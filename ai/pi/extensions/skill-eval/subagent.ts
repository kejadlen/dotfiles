/**
 * Subagent runner.
 *
 * Pi has no subagents, so a "subagent" here is a nested `pi -p --mode json`
 * process: no session file, no extensions, no context files, an explicit tool
 * allowlist, and a scratch cwd. Everything the caller needs — tool calls,
 * final text, spend — comes from parsing the JSON event stream on stdout.
 */

import { spawn } from "node:child_process";

export interface SubagentOptions {
  cwd: string;
  provider: string;
  model: string;
  thinking?: string;
  /** Tool allowlist. An empty list disables tools entirely. */
  tools: string[];
  /** Extra skill paths to load on top of ordinary discovery. */
  skillDirs?: string[];
  /** Whether ordinary skill discovery runs, which keeps description competition realistic. */
  discoverSkills: boolean;
  /** Messages processed in order, each as its own turn. Must not start with "-" or "@". */
  messages?: string[];
  /** Prompt text piped in, which avoids argv escaping limits entirely. */
  stdin?: string;
  timeoutMs?: number;
  signal?: AbortSignal;
}

export interface SubagentToolCall {
  name: string;
  args: Record<string, unknown>;
}

export interface SubagentResult {
  exitCode: number | null;
  timedOut: boolean;
  stderr: string;
  events: any[];
  toolCalls: SubagentToolCall[];
  finalText: string;
  costUsd: number;
  /** Set when the run itself failed, as opposed to the graded behavior failing. */
  error?: string;
}

export function buildSubagentArgs(opts: SubagentOptions): string[] {
  const args = [
    "-p",
    "--mode",
    "json",
    "--no-session",
    "--no-extensions",
    "--no-context-files",
    "--no-prompt-templates",
    "--no-approve",
    "--offline",
    "--provider",
    opts.provider,
    "--model",
    opts.model,
  ];
  if (opts.thinking) args.push("--thinking", opts.thinking);
  if (opts.tools.length === 0) args.push("--no-tools");
  else args.push("--tools", opts.tools.join(","));
  if (!opts.discoverSkills) args.push("--no-skills");
  for (const dir of opts.skillDirs ?? []) args.push("--skill", dir);
  for (const message of opts.messages ?? []) args.push(message);
  return args;
}

/** Resolve the pi entrypoint of the running process so subagents match this build. */
export function piExecutable(): { command: string; prefixArgs: string[] } {
  const cli = process.env.PI_BIN ?? process.argv[1];
  if (cli) return { command: process.execPath, prefixArgs: [cli] };
  return { command: "pi", prefixArgs: [] };
}

export function collectEvents(stdout: string): any[] {
  const events: any[] = [];
  for (const line of stdout.split("\n")) {
    if (!line.trim()) continue;
    try {
      events.push(JSON.parse(line));
    } catch {
      // Non-JSON noise on stdout isn't fatal; the stream is line-oriented.
    }
  }
  return events;
}

export function extractToolCalls(events: any[]): SubagentToolCall[] {
  return events
    .filter((event) => event.type === "tool_execution_start")
    .map((event) => ({ name: event.toolName, args: event.args ?? {} }));
}

function finalMessages(events: any[]): any[] {
  for (let i = events.length - 1; i >= 0; i--) {
    if (events[i].type === "agent_end" && Array.isArray(events[i].messages)) return events[i].messages;
  }
  return [];
}

export function extractFinalText(events: any[]): string {
  const messages = finalMessages(events);
  for (let i = messages.length - 1; i >= 0; i--) {
    const message = messages[i];
    if (message.role !== "assistant" || !Array.isArray(message.content)) continue;
    const text = message.content
      .filter((block: any) => block.type === "text" && typeof block.text === "string")
      .map((block: any) => block.text)
      .join("\n")
      .trim();
    if (text) return text;
  }
  return "";
}

export function extractCost(events: any[]): number {
  let total = 0;
  for (const message of finalMessages(events)) {
    const cost = message?.usage?.cost?.total;
    if (typeof cost === "number") total += cost;
  }
  return total;
}

/** Readable transcript of a run, for handing to a judge. */
export function formatTranscript(events: any[], maxResultChars = 1500): string {
  const lines: string[] = [];
  for (const message of finalMessages(events)) {
    if (message.role === "user" && Array.isArray(message.content)) {
      const text = message.content
        .filter((block: any) => block.type === "text")
        .map((block: any) => block.text)
        .join("\n")
        .trim();
      if (text) lines.push(`[user]\n${text}`);
    } else if (message.role === "assistant" && Array.isArray(message.content)) {
      for (const block of message.content) {
        if (block.type === "text" && block.text?.trim()) lines.push(`[assistant]\n${block.text.trim()}`);
        if (block.type === "toolCall") {
          lines.push(`[tool call: ${block.name}]\n${truncate(JSON.stringify(block.arguments ?? {}), maxResultChars)}`);
        }
      }
    } else if (message.role === "toolResult" && Array.isArray(message.content)) {
      const text = message.content
        .filter((block: any) => block.type === "text")
        .map((block: any) => block.text)
        .join("\n");
      lines.push(`[tool result: ${message.toolName}${message.isError ? " (error)" : ""}]\n${truncate(text, maxResultChars)}`);
    }
  }
  return lines.join("\n\n");
}

function truncate(text: string, max: number): string {
  if (text.length <= max) return text;
  return `${text.slice(0, max)}\n… [${text.length - max} more characters]`;
}

export async function runSubagent(opts: SubagentOptions): Promise<SubagentResult> {
  const { command, prefixArgs } = piExecutable();
  const args = [...prefixArgs, ...buildSubagentArgs(opts)];

  const env = { ...process.env, NO_COLOR: "1", PI_OFFLINE: "1" };
  // A nested run must not inherit this session's identity.
  delete env.PI_SESSION_FILE;
  delete env.PI_SESSION_ID;

  return await new Promise<SubagentResult>((resolve) => {
    const child = spawn(command, args, { cwd: opts.cwd, env, stdio: ["pipe", "pipe", "pipe"] });
    let stdout = "";
    let stderr = "";
    let timedOut = false;
    let settled = false;

    const timer = opts.timeoutMs
      ? setTimeout(() => {
          timedOut = true;
          child.kill("SIGKILL");
        }, opts.timeoutMs)
      : undefined;

    const onAbort = () => child.kill("SIGKILL");
    opts.signal?.addEventListener("abort", onAbort, { once: true });

    const finish = (exitCode: number | null, error?: string) => {
      if (settled) return;
      settled = true;
      if (timer) clearTimeout(timer);
      opts.signal?.removeEventListener("abort", onAbort);
      const events = collectEvents(stdout);
      resolve({
        exitCode,
        timedOut,
        stderr: stderr.trim(),
        events,
        toolCalls: extractToolCalls(events),
        finalText: extractFinalText(events),
        costUsd: extractCost(events),
        ...(error ? { error } : {}),
      });
    };

    child.stdout.setEncoding("utf8");
    child.stdout.on("data", (chunk) => (stdout += chunk));
    child.stderr.setEncoding("utf8");
    child.stderr.on("data", (chunk) => (stderr += chunk));
    child.on("error", (error) => finish(null, error.message));
    child.on("close", (code) => {
      if (timedOut) finish(code, `run exceeded ${opts.timeoutMs}ms and was killed`);
      else if (code !== 0) finish(code, `pi exited with code ${code}${stderr.trim() ? `: ${stderr.trim()}` : ""}`);
      else finish(code);
    });

    if (opts.stdin !== undefined) child.stdin.end(opts.stdin);
    else child.stdin.end();
  });
}

/** Run a case's setup script in its sandbox. */
export async function runSetupScript(script: string, cwd: string): Promise<{ ok: boolean; output: string }> {
  return await new Promise((resolve) => {
    const child = spawn("bash", ["-euo", "pipefail", "-c", script], { cwd, stdio: ["ignore", "pipe", "pipe"] });
    let output = "";
    child.stdout.setEncoding("utf8");
    child.stdout.on("data", (chunk) => (output += chunk));
    child.stderr.setEncoding("utf8");
    child.stderr.on("data", (chunk) => (output += chunk));
    child.on("error", (error) => resolve({ ok: false, output: error.message }));
    child.on("close", (code) => resolve({ ok: code === 0, output: output.trim() }));
  });
}
