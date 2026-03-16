/**
 * Permission Gate Extension
 *
 * Requires explicit user confirmation before every tool call.
 * Auto-allows read-only operations (read tool, non-destructive bash commands).
 * Auto-allows reading from tracked files, skills directories, and pi docs.
 * Shows tool name and a summary of the arguments, then asks to allow or block.
 *
 * Write/edit prompts offer "Allow for session" — once accepted, subsequent
 * writes/edits to tracked files are auto-allowed for the remainder of the
 * session. Writes to untracked files still require confirmation. Resets on
 * session start.
 *
 * Allowed bash commands are configured declaratively in BASE_COMMANDS below.
 * Projects can add to the allowlist via `.pi/permissions.json`, which requires
 * a one-time user confirmation (re-prompted if the file changes).
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { execSync } from "node:child_process";
import { createHash } from "node:crypto";
import * as fs from "node:fs";
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

/** JSON-safe subset of CommandRule (no predicates) for .pi/permissions.json */
type JsonCommandRule = true | string[] | { [subcommand: string]: JsonCommandRule };

const BASE_COMMANDS: CommandRule = {
  gh: { "issue": ["list", "view"], "project": ["item-list", "list"], "repo": ["list"] },
  jj: { "bookmark": ["list"], "diff": true, "log": true, "show": true, "st": true, "status": true },
};

// ---------------------------------------------------------------------------
// Per-project permission overrides
//
// Projects can place a `.pi/permissions.json` in the project root:
//
//   { "allow": { "cargo": ["test", "check"], "make": ["test"] } }
//
// On first use (or when the file changes), the user is shown a summary
// and asked to confirm. Approvals are stored in ~/.pi/agent/ keyed by
// a hash of the file content.
// ---------------------------------------------------------------------------
const APPROVALS_PATH = path.join(os.homedir(), ".pi/agent/approved-permissions.json");

interface ApprovalRecord {
  hash: string;
}

function loadApprovals(): Record<string, ApprovalRecord> {
  try {
    return JSON.parse(fs.readFileSync(APPROVALS_PATH, "utf-8"));
  } catch {
    return {};
  }
}

function saveApprovals(approvals: Record<string, ApprovalRecord>): void {
  fs.mkdirSync(path.dirname(APPROVALS_PATH), { recursive: true });
  fs.writeFileSync(APPROVALS_PATH, JSON.stringify(approvals, null, 2) + "\n");
}

function hashContent(content: string): string {
  return createHash("sha256").update(content).digest("hex");
}

/**
 * Render a command rule tree as a human-readable list of allowed command paths.
 * e.g. { cargo: ["test", "check"] } → ["cargo test", "cargo check"]
 */
function summarizeRules(rule: JsonCommandRule, prefix = ""): string[] {
  if (rule === true) return [prefix || "(all commands)"];
  if (Array.isArray(rule)) return rule.map((s) => `${prefix} ${s}`.trim());
  const lines: string[] = [];
  for (const [key, sub] of Object.entries(rule)) {
    lines.push(...summarizeRules(sub, `${prefix} ${key}`.trim()));
  }
  return lines;
}

/**
 * Deep-merge a JSON rule tree into an existing CommandRule tree.
 * Project rules can only add — they cannot override `true` with something
 * more restrictive, and predicates in the base are preserved.
 */
function mergeRules(base: CommandRule, override: JsonCommandRule): CommandRule {
  // base is already fully permissive — nothing to add
  if (base === true) return true;
  // override grants blanket access at this level
  if (override === true) return true;

  // base is a predicate or array — wrap into object form to merge
  if (typeof base === "function" || Array.isArray(base)) {
    // Can't cleanly merge a predicate/array with an object override.
    // Convert base array to object, keep predicates as-is.
    if (Array.isArray(base) && !Array.isArray(override)) {
      const obj: { [k: string]: CommandRule } = {};
      for (const k of base) obj[k] = true;
      return mergeRules(obj, override);
    }
    if (Array.isArray(base) && Array.isArray(override)) {
      return [...new Set([...base, ...override])];
    }
    // predicate base + object override — keep predicate (it's more expressive)
    return base;
  }

  // Both are objects (or override is array)
  if (Array.isArray(override)) {
    // Convert override array to object and merge
    const obj: { [k: string]: JsonCommandRule } = {};
    for (const k of override) obj[k] = true;
    return mergeRules(base, obj);
  }

  // Both are objects — recurse
  const merged: { [k: string]: CommandRule } = { ...base };
  for (const [key, val] of Object.entries(override)) {
    if (key in merged) {
      merged[key] = mergeRules(merged[key], val);
    } else {
      merged[key] = val;
    }
  }
  return merged;
}

/** The effective merged command tree, updated after approval. */
let allowedCommands: CommandRule = BASE_COMMANDS;

/**
 * Pending project rules awaiting user approval. Set at session start if the
 * project has a .pi/permissions.json that hasn't been approved yet. Cleared
 * after the user accepts or rejects.
 */
let pendingProjectRules: { raw: string; rules: JsonCommandRule } | null = null;

/** Per-session opt-in: when true, write/edit to tracked files are auto-allowed. */
let sessionAllowEdits = false;

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
    trackedFiles = new Set(output.trim().split("\n").map((f) => {
      const resolved = path.resolve(cwd, f);
      try { return fs.realpathSync(resolved); } catch { return resolved; }
    }));
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
    const dir = path.dirname(match[1]);
    dirs.add(dir);
    // Also resolve symlinks so that paths through symlinked directories
    // (e.g. ~/.claude -> ~/.dotfiles/ai/claude/) still match after
    // realpathSync is applied to the file being read.
    try { dirs.add(fs.realpathSync(dir)); } catch { /* ignore */ }
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

/** Returns true if the command string contains shell chaining, piping, or injection operators. */
function hasChaining(cmd: string): boolean {
  // Intentionally conservative — if the agent needs any of these it can
  // ask for permission on the full command.
  return /[;|&`\n]/.test(cmd)
    || cmd.includes("$(")
    || cmd.includes("<(") || cmd.includes(">(")
    || cmd.includes("<<");
}

/**
 * Walk the allowedCommands tree to check if a command is allowed.
 * Arrays are shorthand for an object whose keys all map to `true`.
 */
function isCommandAllowed(cmd: string): boolean {
  const tokens = cmd.trimStart().split(/\s+/);
  let rule: CommandRule = allowedCommands;

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

function isTrackedFile(filePath: string, ctx: ExtensionContext): boolean {
  let realPath: string;
  try {
    realPath = fs.realpathSync(filePath);
  } catch {
    return false;
  }
  return getTrackedFiles(ctx.cwd).has(realPath);
}

function isAllowed(toolName: string, input: Record<string, unknown>, ctx: ExtensionContext): boolean {
  if (toolName === "read") {
    const filePath = path.resolve(ctx.cwd, String(input.path ?? ""));
    // Resolve symlinks so a tracked symlink pointing outside the repo
    // doesn't auto-allow reading its target.
    let realPath: string;
    try {
      realPath = fs.realpathSync(filePath);
    } catch {
      return false; // Can't resolve — require prompt
    }
    return (
      getTrackedFiles(ctx.cwd).has(realPath) ||
      isInSkillsDirectory(realPath, ctx) ||
      realPath.startsWith(PI_DOCS_PREFIX)
    );
  }

  if (toolName === "write" || toolName === "edit") {
    if (!sessionAllowEdits) return false;
    const filePath = path.resolve(ctx.cwd, String(input.path ?? ""));
    return isTrackedFile(filePath, ctx);
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

export default function(pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    // Reset state each session
    allowedCommands = BASE_COMMANDS;
    pendingProjectRules = null;
    sessionAllowEdits = false;

    const permPath = path.join(ctx.cwd, ".pi/permissions.json");
    let raw: string;
    try {
      raw = fs.readFileSync(permPath, "utf-8");
    } catch {
      return; // No project permissions file
    }

    let projectRules: JsonCommandRule;
    try {
      const parsed = JSON.parse(raw);
      projectRules = parsed.allow;
      if (!projectRules) return;
    } catch {
      if (ctx.hasUI) ctx.ui.notify("Invalid .pi/permissions.json — ignoring", "warning");
      return;
    }

    const hash = hashContent(raw);
    const approvals = loadApprovals();

    if (approvals[ctx.cwd]?.hash === hash) {
      // Already approved this exact version
      allowedCommands = mergeRules(BASE_COMMANDS, projectRules);
    } else {
      // Defer approval prompt to first tool_call (UI isn't ready here)
      pendingProjectRules = { raw, rules: projectRules };
    }
  });

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

    // Prompt for pending project permissions on first tool_call
    if (pendingProjectRules) {
      const pending = pendingProjectRules;
      pendingProjectRules = null; // Clear so we only prompt once

      const summary = summarizeRules(pending.rules);
      const message = "Project wants to auto-allow:\n" + summary.map((s) => `  ${s}`).join("\n");
      const approved = await ctx.ui.confirm("Project permissions", message);

      if (approved) {
        const approvals = loadApprovals();
        approvals[ctx.cwd] = { hash: hashContent(pending.raw) };
        saveApprovals(approvals);
        allowedCommands = mergeRules(BASE_COMMANDS, pending.rules);
      }
    }

    if (isAllowed(event.toolName, event.input, ctx)) return;

    const summary = formatArgs(event.toolName, event.input);

    // For write/edit, offer a "allow for session" option
    if (event.toolName === "write" || event.toolName === "edit") {
      const choice = await ctx.ui.select(`${event.toolName}: ${summary}`, [
        "Allow once",
        "Allow for session",
        "Block",
      ]);

      if (choice === "Allow for session") {
        sessionAllowEdits = true;
        ctx.ui.notify("Edits allowed for this session (tracked files only)", "info");
        return;
      }
      if (choice === "Allow once") return;
      return { block: true, reason: "Blocked by user" };
    }

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
