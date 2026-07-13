/**
 * Skill Eval Extension
 *
 * Triages whichever skills are actually available in the current session's
 * context (parsed from the system prompt) and in-scope AGENTS.md files for
 * trim/removal candidates, using Pi session logs as a usage signal.
 * Deep-reviews a single target by handing its content and usage
 * stats to the current conversation with a trim-focused rubric.
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

export function resolveReportPath(now: Date, stateBaseDir?: string): string {
  const base = stateBaseDir ?? process.env.XDG_STATE_HOME ?? join(homedir(), ".local", "state");
  const timestamp = now.toISOString().replace(/[:.]/g, "-");
  return join(base, "pi", "skill-eval", "reports", `${timestamp}.md`);
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

const SKILL_RUBRIC = `Review this skill for trim opportunities:
- Redundant or repeated instructions
- Sections that just restate the description
- Unclear or unnecessary instructions
- Structural drift from the skill-notes authoring conventions
Propose specific cuts, not just observations.`;

const AGENTS_RUBRIC = `Review this AGENTS.md file for trim opportunities:
- Stale guidance that no longer reflects current practice
- Guidance duplicated elsewhere (in this file or in a referenced skill)
- Instructions that don't actually change behavior
Propose specific cuts, not just observations.`;

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

  return [`# Trim review: ${name}`, "", usageLine, "", rubric, "", "```", content, "```"].join("\n");
}

// ---------- Wiring ----------

const NINETY_DAYS_MS = 90 * 24 * 60 * 60 * 1000;

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

export default async function (pi: ExtensionAPI) {
  const { Type } = await import("typebox");

  pi.registerCommand("skill-eval", {
    description: "Triage in-context skills/AGENTS.md for trim candidates, or deep-review one target",
    handler: async (args: string, ctx: ExtensionCommandContext) => {
      const target = args.trim();
      if (!target) {
        const result = await runTriage(ctx);
        if (!result.ok) {
          ctx.ui.notify(result.message, "error");
          return;
        }
        ctx.ui.notify(`${result.markdown}\n\nReport saved to ${result.reportPath}`, "info");
        return;
      }

      const result = await runReview(ctx, target);
      if (!result.ok) {
        ctx.ui.notify(result.message, "error");
        return;
      }
      pi.sendUserMessage(result.prompt, { deliverAs: "followUp" });
      ctx.ui.notify(`Queued review for ${result.name}`, "info");
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
