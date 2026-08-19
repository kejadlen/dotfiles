/**
 * Skill Eval Extension
 *
 * Triages whichever skills are actually available in the current session's
 * context (parsed from the system prompt) and in-scope AGENTS.md files for
 * trim/removal candidates, using Pi session logs as a usage signal.
 * Deep-reviews a single target by handing its content and usage
 * stats to the current conversation with a trim-focused rubric.
 * Also runs behavioral evals declared in a skill's evals.yml through nested pi
 * processes; see run.ts and README.md.
 */

import { existsSync, statSync } from "node:fs";
import { readdir, readFile, mkdir, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join, resolve, basename } from "node:path";
import type {
  ExtensionAPI,
  ExtensionContext,
  ExtensionCommandContext,
} from "@mariozechner/pi-coding-agent";
import { EVALS_FILENAME, loadEvalSuite } from "./evals.ts";
import {
  buildFailureFollowUp,
  buildTrimFollowUp,
  filterSuite,
  formatEvalReport,
  runEvals,
  summarizeFailures,
  type EvalRunConfig,
} from "./run.ts";

// ---------- Types ----------

export interface SkillMeta {
  name: string;
  description: string;
  path: string;
  lineCount: number;
  lastModified: number;
}

export interface AgentsFileMeta {
  path: string;
  lineCount: number;
  lastModified: number;
}

export interface UsageStats {
  count: number;
  lastUsed: number | null;
}

export interface TriageRow {
  kind: "skill";
  name: string;
  path: string;
  lineCount: number;
  usage: UsageStats | null;
  verbose: boolean;
  stale: boolean;
}

export type ResolvedTarget =
  | { ok: true; kind: "skill"; meta: SkillMeta }
  | { ok: true; kind: "agents"; meta: AgentsFileMeta }
  | { ok: false; reason: "not_found" | "ambiguous"; candidates: string[] };

export interface ContextSkill {
  name: string;
  description: string;
  filePath: string;
}

function countLines(content: string): number {
  const normalized = content.endsWith("\n") ? content.slice(0, -1) : content;
  return normalized.length === 0 ? 0 : normalized.split("\n").length;
}

// ---------- Discovery ----------

/**
 * Parse the <available_skills> block that pi's system prompt builder embeds
 * (see @mariozechner/pi-coding-agent's formatSkillsForPrompt). This is the
 * authoritative list of skills actually loaded into the current session,
 * covering default dirs, project dirs, configured skillPaths, and anything
 * extensions contributed via the resources_discover event alike. Skills
 * marked disable-model-invocation are omitted from the prompt and therefore
 * from this list too, since the model can't reach them unprompted.
 */
export function parseAvailableSkillsBlock(systemPrompt: string): ContextSkill[] {
  const blockMatch = systemPrompt.match(/<available_skills>([\s\S]*?)<\/available_skills>/);
  if (!blockMatch) return [];

  const skills: ContextSkill[] = [];
  const skillRe = /<skill>([\s\S]*?)<\/skill>/g;
  let skillMatch: RegExpExecArray | null;
  while ((skillMatch = skillRe.exec(blockMatch[1])) !== null) {
    const inner = skillMatch[1];
    const name = unescapeXml(inner.match(/<name>([\s\S]*?)<\/name>/)?.[1] ?? "");
    const description = unescapeXml(inner.match(/<description>([\s\S]*?)<\/description>/)?.[1] ?? "");
    const filePath = unescapeXml(inner.match(/<location>([\s\S]*?)<\/location>/)?.[1] ?? "");
    if (name && filePath) skills.push({ name, description, filePath });
  }
  return skills;
}

function unescapeXml(str: string): string {
  return str
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&amp;/g, "&");
}

/** Read line count and mtime for each in-context skill, skipping any whose file can't be read. */
export async function loadSkillsFromContext(skills: ContextSkill[]): Promise<SkillMeta[]> {
  const results: SkillMeta[] = [];
  for (const skill of skills) {
    let content: string;
    let stat;
    try {
      content = await readFile(skill.filePath, "utf8");
      stat = statSync(skill.filePath);
    } catch {
      continue;
    }
    results.push({
      name: skill.name,
      description: skill.description,
      path: skill.filePath,
      lineCount: countLines(content),
      lastModified: stat.mtimeMs,
    });
  }
  return results;
}

export async function discoverAgentsFiles(cwd: string): Promise<AgentsFileMeta[]> {
  const paths = new Set<string>();

  const globalPath = join(homedir(), ".pi", "agent", "AGENTS.md");
  if (existsSync(globalPath)) paths.add(resolve(globalPath));

  let dir = resolve(cwd);
  const home = resolve(homedir());
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const candidate = join(dir, "AGENTS.md");
    if (existsSync(candidate)) paths.add(resolve(candidate));

    const isRepoRoot = existsSync(join(dir, ".git")) || existsSync(join(dir, ".jj"));
    const parent = dirname(dir);
    if (isRepoRoot || parent === dir || dir === home) break;
    dir = parent;
  }

  const results: AgentsFileMeta[] = [];
  for (const p of paths) {
    const stat = statSync(p);
    const content = await readFile(p, "utf8");
    results.push({ path: p, lineCount: countLines(content), lastModified: stat.mtimeMs });
  }
  return results;
}

// ---------- Usage scanning ----------

interface RawToolCallContent {
  type: "toolCall";
  name: string;
  arguments: Record<string, unknown>;
}

export async function scanSkillUsage(
  sessionsDir: string,
  skillPaths: string[],
  sinceMs: number,
): Promise<Map<string, UsageStats>> {
  const usage = new Map<string, UsageStats>();
  const normalizedSkillPaths = new Map(skillPaths.map((p) => [resolve(p), p]));

  const files = await findJsonlFiles(sessionsDir);
  for (const file of files) {
    let raw: string;
    try {
      raw = await readFile(file, "utf8");
    } catch {
      continue;
    }
    for (const line of raw.split("\n")) {
      if (!line.trim()) continue;
      let entry: any;
      try {
        entry = JSON.parse(line);
      } catch {
        continue;
      }
      if (entry.type !== "message") continue;
      const message = entry.message;
      if (!message || message.role !== "assistant") continue;
      const ts = Date.parse(entry.timestamp);
      if (Number.isNaN(ts) || ts < sinceMs) continue;
      if (!Array.isArray(message.content)) continue;
      for (const block of message.content as RawToolCallContent[]) {
        if (block.type !== "toolCall" || block.name !== "read") continue;
        const rawPath = block.arguments?.path;
        if (typeof rawPath !== "string") continue;
        const resolvedPath = resolve(rawPath);
        const originalPath = normalizedSkillPaths.get(resolvedPath);
        if (!originalPath) continue;
        const existing = usage.get(originalPath) ?? { count: 0, lastUsed: null };
        existing.count += 1;
        existing.lastUsed = existing.lastUsed === null ? ts : Math.max(existing.lastUsed, ts);
        usage.set(originalPath, existing);
      }
    }
  }
  return usage;
}

async function findJsonlFiles(root: string): Promise<string[]> {
  const results: string[] = [];
  let entries;
  try {
    entries = await readdir(root, { withFileTypes: true });
  } catch {
    return results;
  }
  for (const entry of entries) {
    const full = join(root, entry.name);
    if (entry.isDirectory()) {
      results.push(...(await findJsonlFiles(full)));
    } else if (entry.isFile() && entry.name.endsWith(".jsonl")) {
      results.push(full);
    }
  }
  return results;
}

// ---------- Ranking ----------

export function computeVerboseThreshold(skills: SkillMeta[]): number {
  if (skills.length === 0) return 0;
  const sorted = skills.map((s) => s.lineCount).sort((a, b) => a - b);
  const idx = Math.min(sorted.length - 1, Math.floor(sorted.length * 0.75));
  return sorted[idx];
}

export function rankSkills(
  skills: SkillMeta[],
  usage: Map<string, UsageStats>,
  verboseThreshold: number,
): TriageRow[] {
  const rows: TriageRow[] = skills.map((skill) => {
    const stats = usage.get(skill.path) ?? null;
    const verbose = skill.lineCount >= verboseThreshold;
    const stale = (stats?.count ?? 0) === 0;
    return {
      kind: "skill",
      name: skill.name,
      path: skill.path,
      lineCount: skill.lineCount,
      usage: stats,
      verbose,
      stale,
    };
  });

  const flagScore = (row: TriageRow) => (row.verbose ? 1 : 0) + (row.stale ? 1 : 0);
  return rows.sort((a, b) => {
    const scoreDiff = flagScore(b) - flagScore(a);
    if (scoreDiff !== 0) return scoreDiff;
    return b.lineCount - a.lineCount;
  });
}

// ---------- Report ----------

export function formatTriageMarkdown(
  rows: TriageRow[],
  agentsFiles: AgentsFileMeta[],
  generatedAt: Date,
): string {
  const lines: string[] = [];
  lines.push(`# Skill eval triage — ${generatedAt.toISOString()}`);
  lines.push("");
  lines.push("## Skills");
  lines.push("");
  lines.push("| Name | Lines | Usage (90d) | Last used | Verbose | Stale |");
  lines.push("|------|-------|-------------|-----------|---------|-------|");
  for (const row of rows) {
    const usageCount = row.usage ? String(row.usage.count) : "0";
    const lastUsed = row.usage?.lastUsed
      ? new Date(row.usage.lastUsed).toISOString().slice(0, 10)
      : "never";
    lines.push(
      `| ${row.name} | ${row.lineCount} | ${usageCount} | ${lastUsed} | ${row.verbose ? "yes" : ""} | ${row.stale ? "yes" : ""} |`,
    );
  }
  lines.push("");
  lines.push("## AGENTS.md files");
  lines.push("");
  lines.push("| Path | Lines |");
  lines.push("|------|-------|");
  for (const file of agentsFiles) {
    lines.push(`| ${file.path} | ${file.lineCount} |`);
  }
  lines.push("");
  return lines.join("\n");
}

export function resolveReportPath(now: Date, stateBaseDir?: string, label?: string): string {
  const base = stateBaseDir ?? process.env.XDG_STATE_HOME ?? join(homedir(), ".local", "state");
  const timestamp = now.toISOString().replace(/[:.]/g, "-");
  const suffix = label ? `-${label.replace(/[^a-zA-Z0-9._-]+/g, "_")}` : "";
  return join(base, "pi", "skill-eval", "reports", `${timestamp}${suffix}.md`);
}

export async function writeReport(markdown: string, reportPath: string): Promise<void> {
  await mkdir(dirname(reportPath), { recursive: true });
  await writeFile(reportPath, markdown, "utf8");
}

// ---------- Target resolution ----------

export function resolveTarget(
  query: string,
  skills: SkillMeta[],
  agentsFiles: AgentsFileMeta[],
): ResolvedTarget {
  const q = query.trim().toLowerCase();

  const exactSkill = skills.find((s) => s.name.toLowerCase() === q);
  if (exactSkill) return { ok: true, kind: "skill", meta: exactSkill };

  const exactAgents = agentsFiles.find(
    (a) => basename(a.path).toLowerCase() === q || a.path.toLowerCase() === q,
  );
  if (exactAgents) return { ok: true, kind: "agents", meta: exactAgents };

  const skillMatches = skills.filter((s) => s.name.toLowerCase().includes(q));
  const agentsMatches = agentsFiles.filter((a) => a.path.toLowerCase().includes(q));
  const totalMatches = skillMatches.length + agentsMatches.length;

  if (totalMatches === 1) {
    if (skillMatches.length === 1) return { ok: true, kind: "skill", meta: skillMatches[0] };
    return { ok: true, kind: "agents", meta: agentsMatches[0] };
  }

  if (totalMatches > 1) {
    return {
      ok: false,
      reason: "ambiguous",
      candidates: [...skillMatches.map((s) => s.name), ...agentsMatches.map((a) => a.path)],
    };
  }

  const allNames = [...skills.map((s) => s.name), ...agentsFiles.map((a) => a.path)];
  return { ok: false, reason: "not_found", candidates: allNames.slice(0, 5) };
}

// ---------- Review prompt ----------

const SKILL_RUBRIC = `Cut this skill down. Load the \`tighten-docs\` skill and work its audit, then check the
result against the \`skill-notes\` authoring conventions.

What this file is likely paying for and not using:
- Instructions the model already follows without being told
- Repetition across sections, or a section that restates the description
- Examples past the one that carries the point
- Reference files nothing in SKILL.md routes to

Efficacy outranks size. Text that changes behavior stays even when it reads badly, and the
\`description\` frontmatter keeps every trigger context it has — a smaller skill that stops
loading is a worse skill. Propose specific cuts, name what the skill would lose if each one
landed, and give the line count you'd end at.`;

const AGENTS_RUBRIC = `Cut this AGENTS.md down. Load the \`tighten-docs\` skill and work its audit.

What this file is likely paying for and not using:
- Stale guidance that no longer reflects current practice
- Guidance duplicated here and in a skill this file already routes to
- Instructions that don't change behavior

Every line here loads into every session, so length is the whole cost — but text that changes
behavior stays regardless. Propose specific cuts and give the line count you'd end at.`;

export function buildReviewPrompt(
  kind: "skill" | "agents",
  name: string,
  content: string,
  usage: UsageStats | null,
): string {
  const rubric = kind === "skill" ? SKILL_RUBRIC : AGENTS_RUBRIC;
  const usageLine =
    usage !== null
      ? `Usage in the last 90 days: ${usage.count} time(s), last used ${
          usage.lastUsed ? new Date(usage.lastUsed).toISOString().slice(0, 10) : "never"
        }.`
      : "No usage signal available for this file type.";

  return [
    `# Trim review: ${name}`,
    "",
    `${countLines(content)} line${countLines(content) === 1 ? "" : "s"}. ${usageLine}`,
    "",
    rubric,
    "",
    "```",
    content,
    "```",
  ].join("\n");
}

// ---------- Command arguments ----------

export type ParsedCommand =
  | { action: "triage" }
  | { action: "review"; target: string }
  | {
      action: "run";
      target: string;
      repeat: number;
      jobs: number;
      only?: "trigger" | "adherence";
      cases: string[];
    }
  | { action: "error"; message: string };

const DEFAULT_REPEAT = 1;
const DEFAULT_JOBS = 3;

/**
 * `/skill-eval` and `/skill-eval triage` triage; `/skill-eval run <skill>` runs
 * behavioral evals; anything else is treated as a review target, which keeps the
 * original bare-target form working.
 */
/** Split on whitespace, but keep quoted runs together so a filter can hold spaces. */
export function tokenizeArgs(args: string): string[] {
  const tokens: string[] = [];
  let current = "";
  let quote: '"' | "'" | null = null;
  let started = false;

  for (const char of args.trim()) {
    if (quote) {
      if (char === quote) quote = null;
      else current += char;
      continue;
    }
    if (char === '"' || char === "'") {
      quote = char;
      started = true;
      continue;
    }
    if (/\s/.test(char)) {
      if (started) tokens.push(current);
      current = "";
      started = false;
      continue;
    }
    current += char;
    started = true;
  }
  if (started) tokens.push(current);
  return tokens;
}

export function parseCommandArgs(args: string): ParsedCommand {
  const tokens = tokenizeArgs(args);
  if (tokens.length === 0) return { action: "triage" };

  const [head, ...rest] = tokens;
  if (head === "triage") {
    if (rest.length > 0) return { action: "error", message: "triage takes no arguments." };
    return { action: "triage" };
  }

  if (head === "review") {
    if (rest.length !== 1) return { action: "error", message: "review takes exactly one target." };
    return { action: "review", target: rest[0] };
  }

  if (head === "run") {
    let target: string | undefined;
    let repeat = DEFAULT_REPEAT;
    let jobs = DEFAULT_JOBS;
    let only: "trigger" | "adherence" | undefined;
    const cases: string[] = [];

    for (let i = 0; i < rest.length; i++) {
      const token = rest[i];
      if (token === "--case") {
        const value = rest[++i];
        if (value === undefined || value.startsWith("-")) {
          return { action: "error", message: "--case needs a substring to match against case prompts and notes." };
        }
        cases.push(value);
        continue;
      }
      if (token === "--repeat" || token === "--jobs") {
        const value = Number(rest[++i]);
        if (!Number.isInteger(value) || value < 1) {
          return { action: "error", message: `${token} needs a positive integer.` };
        }
        if (token === "--repeat") repeat = value;
        else jobs = value;
        continue;
      }
      if (token === "--only") {
        const value = rest[++i];
        if (value !== "trigger" && value !== "adherence") {
          return { action: "error", message: "--only takes either trigger or adherence." };
        }
        only = value;
        continue;
      }
      if (token.startsWith("-")) return { action: "error", message: `Unknown flag ${token}.` };
      if (target !== undefined) return { action: "error", message: "run takes exactly one skill." };
      target = token;
    }

    if (target === undefined) {
      return { action: "error", message: "run needs a skill name: /skill-eval run <skill>." };
    }
    return { action: "run", target, repeat, jobs, cases, ...(only ? { only } : {}) };
  }

  if (tokens.length > 1) return { action: "error", message: `Unknown subcommand "${head}".` };
  return { action: "review", target: head };
}

// ---------- Wiring ----------

const NINETY_DAYS_MS = 90 * 24 * 60 * 60 * 1000;
const RUN_TIMEOUT_MS = 5 * 60 * 1000;

function sessionsDirFor(): string {
  return join(homedir(), ".pi", "agent", "sessions");
}

async function runTriage(
  ctx: ExtensionContext,
): Promise<{ ok: true; markdown: string; reportPath: string } | { ok: false; message: string }> {
  const contextSkills = parseAvailableSkillsBlock(ctx.getSystemPrompt());
  if (contextSkills.length === 0) {
    return { ok: false, message: "No skills available in context to triage." };
  }
  const skills = await loadSkillsFromContext(contextSkills);
  const agentsFiles = await discoverAgentsFiles(ctx.cwd);
  const usage = await scanSkillUsage(
    sessionsDirFor(),
    skills.map((s) => s.path),
    Date.now() - NINETY_DAYS_MS,
  );
  const threshold = computeVerboseThreshold(skills);
  const rows = rankSkills(skills, usage, threshold);
  const now = new Date();
  const markdown = formatTriageMarkdown(rows, agentsFiles, now);
  const reportPath = resolveReportPath(now);
  await writeReport(markdown, reportPath);
  return { ok: true, markdown, reportPath };
}

async function runReview(
  ctx: ExtensionContext,
  target: string,
): Promise<{ ok: true; prompt: string; name: string } | { ok: false; message: string }> {
  const contextSkills = parseAvailableSkillsBlock(ctx.getSystemPrompt());
  const skills = await loadSkillsFromContext(contextSkills);
  const agentsFiles = await discoverAgentsFiles(ctx.cwd);
  const resolved = resolveTarget(target, skills, agentsFiles);

  if (!resolved.ok) {
    const label = resolved.reason === "ambiguous" ? "Ambiguous target" : "No matching skill or AGENTS.md file";
    return {
      ok: false,
      message: `${label} for "${target}". Candidates: ${resolved.candidates.join(", ") || "none"}`,
    };
  }

  const content = await readFile(resolved.meta.path, "utf8");

  if (resolved.kind === "skill") {
    const usage = await scanSkillUsage(sessionsDirFor(), [resolved.meta.path], Date.now() - NINETY_DAYS_MS);
    const stats = usage.get(resolved.meta.path) ?? { count: 0, lastUsed: null };
    const prompt = buildReviewPrompt("skill", resolved.meta.name, content, stats);
    return { ok: true, prompt, name: resolved.meta.name };
  }

  const prompt = buildReviewPrompt("agents", resolved.meta.path, content, null);
  return { ok: true, prompt, name: resolved.meta.path };
}

async function resolveEvalTarget(
  ctx: ExtensionContext,
  target: string,
): Promise<{ ok: true; meta: SkillMeta } | { ok: false; message: string }> {
  const contextSkills = parseAvailableSkillsBlock(ctx.getSystemPrompt());
  const skills = await loadSkillsFromContext(contextSkills);
  const agentsFiles = await discoverAgentsFiles(ctx.cwd);
  const resolved = resolveTarget(target, skills, agentsFiles);

  if (!resolved.ok) {
    const label =
      resolved.reason === "ambiguous" ? "Ambiguous target" : "No matching skill";
    return {
      ok: false,
      message: `${label} for "${target}". Candidates: ${resolved.candidates.join(", ") || "none"}`,
    };
  }
  if (resolved.kind !== "skill") {
    return {
      ok: false,
      message: `"${target}" is an AGENTS.md file. Behavioral evals only work on skills, since they measure whether a skill loads and gets followed. Use /skill-eval review ${target} instead.`,
    };
  }
  return { ok: true, meta: resolved.meta };
}

function evalConfig(ctx: ExtensionContext, repeat: number, jobs: number): EvalRunConfig | null {
  const model = ctx.model;
  if (!model) return null;
  return {
    provider: model.provider,
    model: model.id,
    thinking: ctx.thinkingLevel,
    repeat,
    jobs,
    timeoutMs: RUN_TIMEOUT_MS,
  };
}

/** UI methods are no-ops without a UI, so fall back to the console for headless runs. */
function announce(ctx: ExtensionCommandContext, text: string, level: "info" | "warning" | "error"): void {
  ctx.ui.notify(text, level);
  if (!ctx.hasUI) {
    if (level === "error") console.error(text);
    else console.log(text);
  }
}

async function handleRun(
  pi: ExtensionAPI,
  ctx: ExtensionCommandContext,
  parsed: { target: string; repeat: number; jobs: number; only?: "trigger" | "adherence"; cases: string[] },
): Promise<void> {
  const target = await resolveEvalTarget(ctx, parsed.target);
  if (!target.ok) {
    announce(ctx, target.message, "error");
    return;
  }

  const loaded = await loadEvalSuite(target.meta.path);
  if (!loaded.ok) {
    announce(ctx, loaded.errors.join("\n"), "error");
    return;
  }
  const suite = filterSuite(loaded.suite, parsed.cases);

  const config = evalConfig(ctx, parsed.repeat, parsed.jobs);
  if (!config) {
    announce(ctx, "No active model, so there's nothing to run evals with. Pick a model with /model first.", "error");
    return;
  }

  const triggerCases = parsed.only === "adherence" ? 0 : suite.triggerPositive.length + suite.triggerNegative.length;
  const adherenceCases = parsed.only === "trigger" ? 0 : suite.adherence.length;
  if (triggerCases + adherenceCases === 0) {
    const kind = parsed.only ? `${parsed.only} ` : "";
    const filtered = parsed.cases.length > 0 ? ` matching ${parsed.cases.map((c) => `"${c}"`).join(" or ")}` : "";
    announce(ctx, `${EVALS_FILENAME} for ${target.meta.name} has no ${kind}cases${filtered} to run.`, "error");
    return;
  }

  // Each adherence case costs a judge run on top of the agent run.
  const modelRuns = (triggerCases + adherenceCases * 2) * parsed.repeat;
  if (ctx.hasUI) {
    const proceed = await ctx.ui.confirm(
      `Run evals for ${target.meta.name}?`,
      `${modelRuns} nested ${config.provider}/${config.model} runs, ${parsed.jobs} at a time. This spends API credit.`,
    );
    if (!proceed) return;
  }

  ctx.ui.setStatus("skill-eval", `evals: ${target.meta.name} starting`);
  let report;
  try {
    report = await runEvals({
      skillName: target.meta.name,
      skillPath: target.meta.path,
      suite,
      only: parsed.only,
      config: {
        ...config,
        onProgress: (done, total, label) => {
          ctx.ui.setStatus("skill-eval", `evals: ${target.meta.name} ${done}/${total} — ${label.slice(0, 40)}`);
        },
      },
    });
  } finally {
    ctx.ui.setStatus("skill-eval", undefined);
  }

  const markdown = formatEvalReport(report);
  const reportPath = resolveReportPath(report.finishedAt, undefined, `eval-${report.skillName}`);
  await writeReport(markdown, reportPath);

  const failures = summarizeFailures(report);
  announce(ctx, `${markdown}\n\nReport saved to ${reportPath}`, failures.length > 0 ? "warning" : "info");

  if (failures.length > 0) {
    pi.sendUserMessage(buildFailureFollowUp(report, failures, reportPath), { deliverAs: "followUp" });
    return;
  }

  // A green run only licenses trimming if it covered the whole suite.
  if (parsed.cases.length > 0 || parsed.only !== undefined) return;
  pi.sendUserMessage(buildTrimFollowUp(report, target.meta.lineCount, reportPath), { deliverAs: "followUp" });
}

export default async function (pi: ExtensionAPI) {
  const { Type } = await import("typebox");

  pi.registerCommand("skill-eval", {
    description:
      "triage | review <target> | run <skill> [--repeat N] [--jobs N] [--only trigger|adherence] [--case <substring>]",
    getArgumentCompletions: (prefix: string) => {
      const items = [
        { value: "triage", label: "triage — rank skills and AGENTS.md files by trim potential" },
        { value: "review ", label: "review <target> — critique one file's text" },
        { value: "run ", label: "run <skill> — run its evals.yml through subagents" },
      ].filter((item) => item.value.startsWith(prefix));
      return items.length > 0 ? items : null;
    },
    handler: async (args: string, ctx: ExtensionCommandContext) => {
      const parsed = parseCommandArgs(args);

      if (parsed.action === "error") {
        announce(ctx, `${parsed.message} Usage: /skill-eval [triage | review <target> | run <skill>]`, "error");
        return;
      }

      if (parsed.action === "triage") {
        const result = await runTriage(ctx);
        if (!result.ok) {
          announce(ctx, result.message, "error");
          return;
        }
        announce(ctx, `${result.markdown}\n\nReport saved to ${result.reportPath}`, "info");
        return;
      }

      if (parsed.action === "review") {
        const result = await runReview(ctx, parsed.target);
        if (!result.ok) {
          announce(ctx, result.message, "error");
          return;
        }
        pi.sendUserMessage(result.prompt, { deliverAs: "followUp" });
        announce(ctx, `Queued review for ${result.name}`, "info");
        return;
      }

      await handleRun(pi, ctx, parsed);
    },
  });

  pi.registerTool({
    name: "skill_eval",
    label: "Skill Eval",
    description: "Triage in-context skills/AGENTS.md for trim candidates, or fetch one target's content for review",
    promptSnippet: "Triage in-context skills/AGENTS.md for trim candidates, or fetch one target for review",
    promptGuidelines: [
      "Use skill_eval with action 'triage' when asked to find skills or AGENTS.md files worth trimming.",
      "Use skill_eval with action 'review' and a target name when asked to critique a specific skill or AGENTS.md file.",
      "Behavioral evals spend API credit, so they are user-driven: tell the user to run /skill-eval run <skill> rather than trying to run them yourself.",
    ],
    parameters: Type.Object({
      action: Type.Union([Type.Literal("triage"), Type.Literal("review")]),
      target: Type.Optional(Type.String({ description: "Skill name or AGENTS.md path to review" })),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx: ExtensionContext) {
      if (params.action === "triage") {
        const result = await runTriage(ctx);
        if (!result.ok) {
          return { content: [{ type: "text", text: result.message }], isError: true, details: {} };
        }
        return {
          content: [{ type: "text", text: `${result.markdown}\n\nReport saved to ${result.reportPath}` }],
          details: {},
        };
      }

      if (!params.target) {
        return {
          content: [{ type: "text", text: "action 'review' requires a target." }],
          isError: true,
          details: {},
        };
      }

      const result = await runReview(ctx, params.target);
      if (!result.ok) {
        return { content: [{ type: "text", text: result.message }], isError: true, details: {} };
      }
      return { content: [{ type: "text", text: result.prompt }], details: {} };
    },
  });
}
