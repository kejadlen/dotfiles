/**
 * Permission Gate Extension
 *
 * Requires explicit user confirmation before every tool call.
 * Auto-allows read-only operations (read tool, non-destructive jj commands).
 * Auto-allows reading from tracked files, skills directories, and pi docs.
 * Shows tool name and a summary of the arguments, then asks to allow or block.
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { execSync } from "node:child_process";
import * as os from "node:os";
import * as path from "node:path";

const ALLOWED_JJ_SUBCOMMANDS = ["diff", "log", "show", "status"];
const PI_DOCS_PREFIX = path.join(
  os.homedir(),
  ".volta/tools/image/packages/@mariozechner/pi-coding-agent/"
);

let trackedFiles: Set<string> | null = null;
let skillsDirs: Set<string> | null = null;

function getTrackedFiles(cwd: string): Set<string> {
  if (trackedFiles) return trackedFiles;
  try {
    const output = execSync("jj file list", { cwd, encoding: "utf-8" });
    trackedFiles = new Set(output.trim().split("\n").map((f) => path.resolve(cwd, f)));
  } catch {
    trackedFiles = new Set();
  }
  return trackedFiles;
}

/**
 * Derive skills directories from the system prompt's <available_skills> block.
 * This reflects the actual loaded skills (including any added by extensions via
 * resources_discover), rather than just what's configured in settings.json.
 */
function getSkillsDirectories(ctx: ExtensionContext): Set<string> {
  if (skillsDirs) return skillsDirs;
  const dirs = new Set<string>();
  const prompt = ctx.getSystemPrompt();
  const locationRe = /<location>(.*?)<\/location>/g;
  let match;
  while ((match = locationRe.exec(prompt)) !== null) {
    dirs.add(path.dirname(match[1]));
  }
  skillsDirs = dirs;
  return skillsDirs;
}

function isInSkillsDirectory(filePath: string, ctx: ExtensionContext): boolean {
  const dirs = getSkillsDirectories(ctx);
  for (const dir of dirs) {
    if (filePath.startsWith(dir + path.sep) || filePath === dir) return true;
  }
  return false;
}

/**
 * Strip a leading `cd <cwd> && ` or `cd <cwd> ; ` prefix from a command.
 * The agent often wraps commands this way, which is a no-op but obscures the
 * real command from permission checks.
 */
function stripCdToCwd(cmd: string, cwd: string): string {
  const prefix = `cd ${cwd} && `;
  if (cmd.startsWith(prefix)) return cmd.slice(prefix.length);
  const prefixSemi = `cd ${cwd} ; `;
  if (cmd.startsWith(prefixSemi)) return cmd.slice(prefixSemi.length);
  return cmd;
}

function isAllowed(toolName: string, input: Record<string, unknown>, ctx: ExtensionContext): boolean {
  if (toolName === "read") {
    const filePath = path.resolve(ctx.cwd, String(input.path ?? ""));
    return getTrackedFiles(ctx.cwd).has(filePath) || isInSkillsDirectory(filePath, ctx) || filePath.startsWith(PI_DOCS_PREFIX);
  }

  if (toolName === "bash") {
    const cmd = stripCdToCwd(String(input.command ?? "").trimStart(), ctx.cwd);
    if (cmd.startsWith("jj ")) {
      const subcommand = cmd.slice(3).trimStart().split(/\s/)[0];
      return ALLOWED_JJ_SUBCOMMANDS.includes(subcommand);
    }
  }

  return false;
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_result", async (event) => {
    if (event.toolName === "bash") {
      const cmd = String(event.input.command ?? "").trimStart();
      if (cmd.startsWith("jj ")) {
        trackedFiles = null;
      }
    }
  });

  pi.on("tool_call", async (event, ctx) => {
    if (!ctx.hasUI) return;
    if (isAllowed(event.toolName, event.input, ctx)) return;

    const summary = formatArgs(event.toolName, event.input);
    const allowed = await ctx.ui.confirm(event.toolName, summary);

    if (!allowed) {
      return { block: true, reason: "Blocked by user" };
    }
  });
}

function formatArgs(toolName: string, input: Record<string, unknown>): string {
  switch (toolName) {
    case "bash":
      return `$ ${input.command}`;
    case "read":
      return `${input.path}` + (input.offset ? ` (offset ${input.offset})` : "");
    case "write":
      return `${input.path} (${String(input.content ?? "").length} chars)`;
    case "edit":
      return `${input.path}`;
    default: {
      const keys = Object.keys(input);
      if (keys.length === 0) return "(no arguments)";
      return keys.map((k) => `${k}: ${truncate(String(input[k]), 80)}`).join("\n");
    }
  }
}

function truncate(s: string, max: number): string {
  if (s.length <= max) return s;
  return s.slice(0, max) + "…";
}
