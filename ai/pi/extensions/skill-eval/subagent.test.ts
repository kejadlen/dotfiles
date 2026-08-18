import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  buildSubagentArgs,
  collectEvents,
  extractCost,
  extractFinalText,
  extractToolCalls,
  formatTranscript,
  runSetupScript,
  runSubagent,
} from "./subagent.ts";

const baseOptions = {
  cwd: "/tmp/sandbox",
  provider: "anthropic",
  model: "claude-opus-5",
  discoverSkills: true,
  tools: ["read"],
};

test("buildSubagentArgs isolates the run and passes model, tools, and skills", () => {
  const args = buildSubagentArgs({ ...baseOptions, thinking: "high", skillDirs: ["/skills/jj"] });

  for (const flag of [
    "-p",
    "--no-session",
    "--no-extensions",
    "--no-context-files",
    "--no-prompt-templates",
    "--no-approve",
  ]) {
    assert.ok(args.includes(flag), `expected ${flag}`);
  }
  assert.deepEqual(args.slice(args.indexOf("--mode"), args.indexOf("--mode") + 2), ["--mode", "json"]);
  assert.deepEqual(args.slice(args.indexOf("--tools"), args.indexOf("--tools") + 2), ["--tools", "read"]);
  assert.deepEqual(args.slice(args.indexOf("--skill"), args.indexOf("--skill") + 2), ["--skill", "/skills/jj"]);
  assert.deepEqual(args.slice(args.indexOf("--thinking"), args.indexOf("--thinking") + 2), ["--thinking", "high"]);
  assert.ok(!args.includes("--no-skills"));
});

test("buildSubagentArgs disables tools and skill discovery when asked", () => {
  const args = buildSubagentArgs({ ...baseOptions, tools: [], discoverSkills: false });
  assert.ok(args.includes("--no-tools"));
  assert.ok(args.includes("--no-skills"));
  assert.ok(!args.includes("--tools"));
});

test("buildSubagentArgs appends messages in order after the flags", () => {
  const args = buildSubagentArgs({ ...baseOptions, messages: ["/skill:jj", "commit my work"] });
  assert.deepEqual(args.slice(-2), ["/skill:jj", "commit my work"]);
});

test("collectEvents parses JSON lines and skips noise", () => {
  const events = collectEvents(['{"type":"agent_start"}', "not json", "", '{"type":"agent_end","messages":[]}'].join("\n"));
  assert.deepEqual(
    events.map((e) => e.type),
    ["agent_start", "agent_end"],
  );
});

test("extractToolCalls returns tool executions in order", () => {
  const events = [
    { type: "tool_execution_start", toolName: "read", args: { path: "/skills/jj/SKILL.md" } },
    { type: "message_end" },
    { type: "tool_execution_start", toolName: "bash", args: { command: "jj st" } },
  ];
  assert.deepEqual(extractToolCalls(events), [
    { name: "read", args: { path: "/skills/jj/SKILL.md" } },
    { name: "bash", args: { command: "jj st" } },
  ]);
});

const agentEnd = {
  type: "agent_end",
  messages: [
    { role: "user", content: [{ type: "text", text: "commit my work" }] },
    {
      role: "assistant",
      content: [
        { type: "text", text: "Checking status." },
        { type: "toolCall", name: "bash", arguments: { command: "jj st" } },
      ],
      usage: { cost: { total: 0.01 } },
    },
    { role: "toolResult", toolName: "bash", isError: false, content: [{ type: "text", text: "Working copy changes" }] },
    { role: "assistant", content: [{ type: "text", text: "Done." }], usage: { cost: { total: 0.02 } } },
  ],
};

test("extractFinalText returns the last assistant text", () => {
  assert.equal(extractFinalText([{ type: "agent_start" }, agentEnd]), "Done.");
});

test("extractFinalText returns an empty string when no assistant text exists", () => {
  assert.equal(extractFinalText([{ type: "agent_end", messages: [] }]), "");
  assert.equal(extractFinalText([]), "");
});

test("extractCost sums per-message cost", () => {
  assert.equal(Number(extractCost([agentEnd]).toFixed(4)), 0.03);
});

test("formatTranscript renders prompts, assistant text, tool calls, and results", () => {
  const transcript = formatTranscript([agentEnd]);
  assert.match(transcript, /\[user\]\ncommit my work/);
  assert.match(transcript, /\[assistant\]\nChecking status\./);
  assert.match(transcript, /\[tool call: bash\]\n\{"command":"jj st"\}/);
  assert.match(transcript, /\[tool result: bash\]\nWorking copy changes/);
});

test("formatTranscript truncates long tool results", () => {
  const events = [
    {
      type: "agent_end",
      messages: [
        { role: "toolResult", toolName: "bash", isError: false, content: [{ type: "text", text: "x".repeat(50) }] },
      ],
    },
  ];
  const transcript = formatTranscript(events, 10);
  assert.match(transcript, /x{10}\n… \[40 more characters\]/);
});

test("runSetupScript reports success and failure with output", async () => {
  const ok = await runSetupScript("echo hello", "/tmp");
  assert.equal(ok.ok, true);
  assert.equal(ok.output, "hello");

  const failed = await runSetupScript("echo boom >&2; exit 3", "/tmp");
  assert.equal(failed.ok, false);
  assert.match(failed.output, /boom/);
});

/** Stand in for the pi entrypoint via PI_BIN so these tests spend no API credit. */
async function withFakePi<T>(script: string, fn: () => Promise<T>): Promise<T> {
  const dir = await mkdtemp(join(tmpdir(), "skill-eval-fakepi-"));
  const path = join(dir, "fake-pi.js");
  await writeFile(path, script);
  const previous = process.env.PI_BIN;
  process.env.PI_BIN = path;
  try {
    return await fn();
  } finally {
    if (previous === undefined) delete process.env.PI_BIN;
    else process.env.PI_BIN = previous;
    await rm(dir, { recursive: true, force: true });
  }
}

test("runSubagent parses the event stream, forwards stdin, and reports cost", async () => {
  const script = `
let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  process.stdout.write(JSON.stringify({ type: "tool_execution_start", toolName: "read", args: { path: input } }) + "\\n");
  process.stdout.write(JSON.stringify({
    type: "agent_end",
    messages: [{ role: "assistant", content: [{ type: "text", text: "ok: " + process.argv.includes("--no-tools") }], usage: { cost: { total: 0.5 } } }],
  }) + "\\n");
});
`;
  const result = await withFakePi(script, () =>
    runSubagent({ ...baseOptions, cwd: "/tmp", tools: [], discoverSkills: false, stdin: "/skills/jj/SKILL.md" }),
  );

  assert.equal(result.exitCode, 0);
  assert.equal(result.error, undefined);
  assert.deepEqual(result.toolCalls, [{ name: "read", args: { path: "/skills/jj/SKILL.md" } }]);
  assert.equal(result.finalText, "ok: true");
  assert.equal(result.costUsd, 0.5);
});

test("runSubagent reports a nonzero exit with stderr instead of throwing", async () => {
  const result = await withFakePi('process.stderr.write("no API key\\n"); process.exit(2);', () =>
    runSubagent({ ...baseOptions, cwd: "/tmp" }),
  );

  assert.equal(result.exitCode, 2);
  assert.match(result.error ?? "", /pi exited with code 2: no API key/);
});

test("runSubagent kills a run that outlives its timeout", async () => {
  const result = await withFakePi("setTimeout(() => {}, 60000);", () =>
    runSubagent({ ...baseOptions, cwd: "/tmp", timeoutMs: 200 }),
  );

  assert.equal(result.timedOut, true);
  assert.match(result.error ?? "", /exceeded 200ms/);
});
