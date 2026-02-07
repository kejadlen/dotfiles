/**
 * Permission Gate Extension
 *
 * Requires explicit user confirmation before every tool call.
 * Auto-allows read-only operations (read tool, non-destructive bash commands).
 * Auto-allows reading from tracked files, skills directories, and pi docs.
 * Shows tool name and a summary of the arguments, then asks to allow or block.
 *
 * Allowed bash commands are configured declaratively in ALLOWED_COMMANDS below.
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { execSync } from "node:child_process";
import * as os from "node:os";
import * as path from "node:path";

// ---------------------------------------------------------------------------
// Allowed bash commands configuration
//
// Each entry maps a command/subcommand to its permission rule, forming a tree:
//
//   true                          — allow with any further arguments
//   string[]                      — shorthand: allow these subcommands (each as true)
//   Record<string, CommandRule>   — recurse into subcommands
//   (args: string) => boolean     — custom predicate on remaining args
//
// Examples:
//   jj: ["diff", "log", "show", "status"],
//   gh: {
//     pr:    ["list", "view", "checks"],
//     issue: ["list", "view"],
//   },
// ---------------------------------------------------------------------------
type CommandRule = true | string[] | ((args: string) => boolean) | { [subcommand: string]: CommandRule };

const ALLOWED_COMMANDS: CommandRule = {
  // version control (read-only subcommands)
  jj: ["diff", "log", "show", "status"],
};

// ---------------------------------------------------------------------------
// Helpers for read-tool path checks
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// Bash command parsing
// ---------------------------------------------------------------------------

/**
 * Strip a leading `cd <cwd> && ` prefix from a command.
 * The agent often wraps commands this way, which is a no-op but obscures the
 * real command from permission checks.
 */
function stripCdToCwd(cmd: string, cwd: string): string {
  const prefix = `cd ${cwd} && `;
  if (cmd.startsWith(prefix)) return cmd.slice(prefix.length);
  return cmd;
}

/** Returns true if the command string contains shell chaining or piping operators. */
function hasChaining(cmd: string): boolean {
  // Block semicolons, &&, ||, pipes, and command substitution.
  // This is intentionally conservative — if the agent needs chaining it can
  // ask for permission on the full command.
  return cmd.includes(";") || cmd.includes("&&") || cmd.includes("||")
    || cmd.includes("|") || cmd.includes("$(") || cmd.includes("`");
}

/**
 * Walk the ALLOWED_COMMANDS tree to check if a command is allowed.
 * Arrays are shorthand for an object whose keys all map to `true`.
 */
function isCommandAllowed(cmd: string): boolean {
  const tokens = cmd.trimStart().split(/\s+/);
  let rule: CommandRule = ALLOWED_COMMANDS;

  for (let i = 0; i < tokens.length; i++) {
    if (rule === true) return true;
    if (typeof rule === "function") return rule(tokens.slice(i).join(" "));
    if (Array.isArray(rule)) return rule.includes(tokens[i]);
    // rule is a subcommand tree — look up the next token
    const next = rule[tokens[i]];
    if (next === undefined) return false;
    rule = next;
  }

  // We consumed all tokens — allow if the final node is `true` or a
  // predicate that accepts empty input.  A tree node means we stopped at
  // a branch (e.g. bare `jj` with no subcommand) — don't auto-allow that.
  if (rule === true) return true;
  if (typeof rule === "function") return rule("");
  return false;
}

// ---------------------------------------------------------------------------
// Main permission check
// ---------------------------------------------------------------------------

function isAllowed(toolName: string, input: Record<string, unknown>, ctx: ExtensionContext): boolean {
  if (toolName === "read") {
    const filePath = path.resolve(ctx.cwd, String(input.path ?? ""));
    return (
      getTrackedFiles(ctx.cwd).has(filePath) ||
      isInSkillsDirectory(filePath, ctx) ||
      filePath.startsWith(PI_DOCS_PREFIX)
    );
  }

  if (toolName === "bash") {
    const cmd = stripCdToCwd(String(input.command ?? "").trimStart(), ctx.cwd);
    if (hasChaining(cmd)) return false;
    return isCommandAllowed(cmd);
  }

  return false;
}

// ---------------------------------------------------------------------------
// Extension entry point
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

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
