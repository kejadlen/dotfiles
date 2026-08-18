/**
 * Behavioral evals: run a skill's text through nested pi processes.
 *
 * Trigger cases measure whether the description makes the agent reach for the
 * skill, so the run keeps ordinary skill discovery on (competing descriptions
 * are part of the test) and allows only `read`, then checks whether the skill
 * files were read.
 *
 * Adherence cases force the skill in with `/skill:<name>`, let the agent work
 * in a scratch directory, and hand the transcript to a judge run that grades
 * each declared expectation.
 *
 * Runs are hermetic apart from globally discovered skills: no context files, no
 * extensions, no session, and a fresh sandbox directory per case.
 */

import { mkdtemp, mkdir, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { basename, dirname, join, relative, resolve, sep } from "node:path";
import type { AdherenceCase, EvalSuite, TriggerCase } from "./evals.ts";
import { formatTranscript, runSetupScript, runSubagent, type SubagentResult } from "./subagent.ts";

export interface EvalRunConfig {
  provider: string;
  model: string;
  thinking?: string;
  /** Attempts per case. Repeats surface flaky trigger behavior. */
  repeat: number;
  /** Cases in flight at once. */
  jobs: number;
  timeoutMs: number;
  signal?: AbortSignal;
  onProgress?: (done: number, total: number, label: string) => void;
}

export type Verdict = "pass" | "fail" | "unclear";

export interface ExpectationResult {
  expectation: string;
  verdict: Verdict;
  reason: string;
}

export interface TriggerAttempt {
  loaded: boolean;
  error?: string;
}

export interface TriggerResult {
  kind: "trigger";
  expected: "load" | "skip";
  prompt: string;
  note?: string;
  attempts: TriggerAttempt[];
  passes: number;
  costUsd: number;
}

export interface AdherenceAttempt {
  expectations: ExpectationResult[];
  transcript: string;
  error?: string;
}

export interface AdherenceResult {
  kind: "adherence";
  prompt: string;
  note?: string;
  attempts: AdherenceAttempt[];
  passes: number;
  costUsd: number;
}

export interface EvalReport {
  skillName: string;
  skillPath: string;
  model: string;
  thinking?: string;
  repeat: number;
  trigger: TriggerResult[];
  adherence: AdherenceResult[];
  costUsd: number;
  runs: number;
  startedAt: Date;
  finishedAt: Date;
}

/**
 * What to hand `--skill`, so the target loads even when it isn't discoverable
 * from the sandbox. Pi accepts either a file or a directory, and a bare `.md`
 * skill has no directory of its own.
 */
export function skillLoadPath(skillPath: string): string {
  return basename(skillPath) === "SKILL.md" ? dirname(skillPath) : skillPath;
}

/**
 * True when the run read the skill itself, or one of its bundled references.
 * A bare `.md` skill shares its directory with unrelated skills, so only the
 * file itself counts there.
 */
export function loadedSkill(toolCalls: { name: string; args: Record<string, unknown> }[], skillPath: string): boolean {
  const target = resolve(skillPath);
  const bundleDir = basename(skillPath) === "SKILL.md" ? resolve(dirname(skillPath)) : undefined;
  return toolCalls.some((call) => {
    if (call.name !== "read") return false;
    const raw = call.args?.path;
    if (typeof raw !== "string") return false;
    const read = resolve(raw);
    if (read === target) return true;
    if (!bundleDir) return false;
    const rel = relative(bundleDir, read);
    return rel !== "" && !rel.startsWith("..") && !rel.startsWith(`..${sep}`);
  });
}

export function buildJudgePrompt(
  skillName: string,
  task: string,
  transcript: string,
  expectations: string[],
): string {
  return [
    `You are grading one run of a coding agent that was given the "${skillName}" skill and then a task.`,
    "",
    "Grade each expectation independently against the transcript. Judge only what the transcript",
    'shows: "pass" when the transcript clearly meets the expectation, "fail" when it clearly does not,',
    '"unclear" when the transcript does not settle it. Do not credit intentions the agent never acted on.',
    "",
    "Task given to the agent:",
    task,
    "",
    "Expectations:",
    ...expectations.map((item, i) => `${i + 1}. ${item}`),
    "",
    "Transcript:",
    "<<<TRANSCRIPT",
    transcript || "(the agent produced no output)",
    "TRANSCRIPT",
    "",
    "Reply with only a JSON array, one object per expectation, in the same order:",
    '[{"index": 1, "verdict": "pass" | "fail" | "unclear", "reason": "one sentence"}]',
  ].join("\n");
}

/** Pull the verdict array out of a judge reply, tolerating code fences and surrounding prose. */
export function parseJudgeVerdicts(text: string, expectations: string[]): ExpectationResult[] {
  const fallback = (reason: string): ExpectationResult[] =>
    expectations.map((expectation) => ({ expectation, verdict: "unclear" as Verdict, reason }));

  const start = text.indexOf("[");
  const end = text.lastIndexOf("]");
  if (start === -1 || end <= start) return fallback("judge did not return a JSON array");

  let parsed: unknown;
  try {
    parsed = JSON.parse(text.slice(start, end + 1));
  } catch {
    return fallback("judge returned unparseable JSON");
  }
  if (!Array.isArray(parsed)) return fallback("judge did not return a JSON array");

  return expectations.map((expectation, i) => {
    const entry: any = parsed.find((item: any) => Number(item?.index) === i + 1) ?? parsed[i];
    const verdict: Verdict =
      entry?.verdict === "pass" || entry?.verdict === "fail" || entry?.verdict === "unclear"
        ? entry.verdict
        : "unclear";
    const reason = typeof entry?.reason === "string" ? entry.reason : "judge gave no reason";
    return { expectation, verdict, reason };
  });
}

async function withSandbox<T>(prefix: string, fn: (dir: string) => Promise<T>): Promise<T> {
  const dir = await mkdtemp(join(tmpdir(), `skill-eval-${prefix}-`));
  try {
    return await fn(dir);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

async function runTriggerAttempt(
  testCase: TriggerCase,
  skillPath: string,
  config: EvalRunConfig,
): Promise<{ attempt: TriggerAttempt; costUsd: number }> {
  return await withSandbox("trigger", async (cwd) => {
    const result = await runSubagent({
      cwd,
      provider: config.provider,
      model: config.model,
      thinking: config.thinking,
      tools: ["read"],
      skillDirs: [skillLoadPath(skillPath)],
      discoverSkills: true,
      stdin: testCase.prompt,
      timeoutMs: config.timeoutMs,
      signal: config.signal,
    });
    return {
      attempt: {
        loaded: loadedSkill(result.toolCalls, skillPath),
        ...(result.error ? { error: result.error } : {}),
      },
      costUsd: result.costUsd,
    };
  });
}

async function judge(
  skillName: string,
  testCase: AdherenceCase,
  transcript: string,
  config: EvalRunConfig,
): Promise<{ expectations: ExpectationResult[]; costUsd: number }> {
  return await withSandbox("judge", async (cwd) => {
    const result = await runSubagent({
      cwd,
      provider: config.provider,
      model: config.model,
      thinking: config.thinking,
      tools: [],
      discoverSkills: false,
      stdin: buildJudgePrompt(skillName, testCase.prompt, transcript, testCase.expect),
      timeoutMs: config.timeoutMs,
      signal: config.signal,
    });
    if (result.error) {
      return {
        expectations: testCase.expect.map((expectation) => ({
          expectation,
          verdict: "unclear" as Verdict,
          reason: `judge run failed: ${result.error}`,
        })),
        costUsd: result.costUsd,
      };
    }
    return { expectations: parseJudgeVerdicts(result.finalText, testCase.expect), costUsd: result.costUsd };
  });
}

async function runAdherenceAttempt(
  testCase: AdherenceCase,
  skillName: string,
  skillPath: string,
  config: EvalRunConfig,
): Promise<{ attempt: AdherenceAttempt; costUsd: number }> {
  return await withSandbox("adherence", async (cwd) => {
    const work = join(cwd, "work");
    await mkdir(work, { recursive: true });

    if (testCase.setup) {
      const setup = await runSetupScript(testCase.setup, work);
      if (!setup.ok) {
        return {
          attempt: {
            expectations: unclearAll(testCase.expect, `setup script failed: ${setup.output || "no output"}`),
            transcript: "",
            error: `setup script failed: ${setup.output || "no output"}`,
          },
          costUsd: 0,
        };
      }
    }

    let result: SubagentResult;
    try {
      result = await runSubagent({
        cwd: work,
        provider: config.provider,
        model: config.model,
        thinking: config.thinking,
        tools: testCase.tools,
        skillDirs: [skillLoadPath(skillPath)],
        discoverSkills: false,
        messages: [`/skill:${skillName}`, testCase.prompt],
        timeoutMs: config.timeoutMs,
        signal: config.signal,
      });
    } catch (error) {
      const message = (error as Error).message;
      return {
        attempt: { expectations: unclearAll(testCase.expect, message), transcript: "", error: message },
        costUsd: 0,
      };
    }

    const transcript = formatTranscript(result.events);
    if (result.error) {
      return {
        attempt: {
          expectations: unclearAll(testCase.expect, `run failed: ${result.error}`),
          transcript,
          error: result.error,
        },
        costUsd: result.costUsd,
      };
    }

    const graded = await judge(skillName, testCase, transcript, config);
    return {
      attempt: { expectations: graded.expectations, transcript },
      costUsd: result.costUsd + graded.costUsd,
    };
  });
}

function unclearAll(expectations: string[], reason: string): ExpectationResult[] {
  return expectations.map((expectation) => ({ expectation, verdict: "unclear" as Verdict, reason }));
}

/** Run tasks with bounded concurrency, preserving input order in the results. */
export async function mapWithConcurrency<T, R>(
  items: T[],
  limit: number,
  fn: (item: T, index: number) => Promise<R>,
): Promise<R[]> {
  const results = new Array<R>(items.length);
  let next = 0;
  const workers = Array.from({ length: Math.max(1, Math.min(limit, items.length)) }, async () => {
    while (next < items.length) {
      const index = next++;
      results[index] = await fn(items[index], index);
    }
  });
  await Promise.all(workers);
  return results;
}

type Unit =
  | { kind: "trigger"; expected: "load" | "skip"; testCase: TriggerCase }
  | { kind: "adherence"; testCase: AdherenceCase };

export interface RunEvalsOptions {
  skillName: string;
  skillPath: string;
  suite: EvalSuite;
  config: EvalRunConfig;
  only?: "trigger" | "adherence";
}

export async function runEvals({ skillName, skillPath, suite, config, only }: RunEvalsOptions): Promise<EvalReport> {
  const startedAt = new Date();

  const units: Unit[] = [];
  if (only !== "adherence") {
    for (const testCase of suite.triggerPositive) units.push({ kind: "trigger", expected: "load", testCase });
    for (const testCase of suite.triggerNegative) units.push({ kind: "trigger", expected: "skip", testCase });
  }
  if (only !== "trigger") {
    for (const testCase of suite.adherence) units.push({ kind: "adherence", testCase });
  }

  const total = units.length * config.repeat;
  let done = 0;
  const tick = (label: string) => config.onProgress?.(++done, total, label);

  const results = await mapWithConcurrency(units, config.jobs, async (unit) => {
    if (unit.kind === "trigger") {
      const attempts: TriggerAttempt[] = [];
      let costUsd = 0;
      for (let i = 0; i < config.repeat; i++) {
        const { attempt, costUsd: cost } = await runTriggerAttempt(unit.testCase, skillPath, config);
        attempts.push(attempt);
        costUsd += cost;
        tick(`trigger: ${unit.testCase.prompt}`);
      }
      const passes = attempts.filter((a) => (unit.expected === "load" ? a.loaded : !a.loaded)).length;
      const result: TriggerResult = {
        kind: "trigger",
        expected: unit.expected,
        prompt: unit.testCase.prompt,
        ...(unit.testCase.note ? { note: unit.testCase.note } : {}),
        attempts,
        passes,
        costUsd,
      };
      return result;
    }

    const attempts: AdherenceAttempt[] = [];
    let costUsd = 0;
    for (let i = 0; i < config.repeat; i++) {
      const { attempt, costUsd: cost } = await runAdherenceAttempt(unit.testCase, skillName, skillPath, config);
      attempts.push(attempt);
      costUsd += cost;
      tick(`adherence: ${unit.testCase.prompt}`);
    }
    const passes = attempts.filter((a) => a.expectations.every((e) => e.verdict === "pass")).length;
    const result: AdherenceResult = {
      kind: "adherence",
      prompt: unit.testCase.prompt,
      ...(unit.testCase.note ? { note: unit.testCase.note } : {}),
      attempts,
      passes,
      costUsd,
    };
    return result;
  });

  const trigger = results.filter((r): r is TriggerResult => r.kind === "trigger");
  const adherence = results.filter((r): r is AdherenceResult => r.kind === "adherence");

  return {
    skillName,
    skillPath,
    model: `${config.provider}/${config.model}`,
    thinking: config.thinking,
    repeat: config.repeat,
    trigger,
    adherence,
    costUsd: results.reduce((sum, r) => sum + r.costUsd, 0),
    runs: total,
    startedAt,
    finishedAt: new Date(),
  };
}

// ---------- Reporting ----------

function firstLine(text: string, max = 80): string {
  const line = text.split("\n")[0].trim();
  return line.length > max ? `${line.slice(0, max - 1)}…` : line;
}

export function formatEvalReport(report: EvalReport): string {
  const lines: string[] = [];
  const triggerPasses = report.trigger.reduce((sum, r) => sum + r.passes, 0);
  const triggerTotal = report.trigger.length * report.repeat;
  const adherencePasses = report.adherence.reduce((sum, r) => sum + r.passes, 0);
  const adherenceTotal = report.adherence.length * report.repeat;
  const seconds = Math.round((report.finishedAt.getTime() - report.startedAt.getTime()) / 1000);

  lines.push(`# Skill eval: ${report.skillName}`);
  lines.push("");
  lines.push(`${report.skillPath}`);
  lines.push("");
  lines.push(
    `${report.model}${report.thinking ? ` (thinking: ${report.thinking})` : ""} · ${report.runs} case run(s) · ` +
      `${report.repeat} attempt(s) per case · $${report.costUsd.toFixed(4)} · ${seconds}s`,
  );
  lines.push("");

  if (report.trigger.length > 0) {
    lines.push(`## Trigger fidelity — ${triggerPasses}/${triggerTotal}`);
    lines.push("");
    lines.push("| Expected | Loaded | Prompt |");
    lines.push("|----------|--------|--------|");
    for (const row of report.trigger) {
      const loads = row.attempts.filter((a) => a.loaded).length;
      lines.push(
        `| ${row.expected === "load" ? "load" : "skip"} | ${loads}/${row.attempts.length} | ${firstLine(row.prompt)} |`,
      );
    }
    const failures = report.trigger.filter((r) => r.passes < r.attempts.length);
    if (failures.length > 0) {
      lines.push("");
      lines.push("Misses:");
      lines.push("");
      for (const row of failures) {
        const verb = row.expected === "load" ? "did not load" : "loaded when it should not have";
        lines.push(`- ${verb}: ${firstLine(row.prompt, 120)}`);
        for (const attempt of row.attempts) {
          if (attempt.error) lines.push(`  - run error: ${attempt.error}`);
        }
      }
    }
    lines.push("");
  }

  if (report.adherence.length > 0) {
    lines.push(`## Instruction adherence — ${adherencePasses}/${adherenceTotal}`);
    lines.push("");
    for (const row of report.adherence) {
      lines.push(`### ${firstLine(row.prompt, 120)}`);
      lines.push("");
      row.attempts.forEach((attempt, i) => {
        if (row.attempts.length > 1) lines.push(`Attempt ${i + 1}:`);
        if (attempt.error) lines.push(`- run error: ${attempt.error}`);
        for (const expectation of attempt.expectations) {
          lines.push(`- ${expectation.verdict}: ${expectation.expectation} — ${expectation.reason}`);
        }
        lines.push("");
      });
    }
  }

  return lines.join("\n");
}

/** Failure detail worth pulling into the conversation so the skill text can be fixed. */
export function summarizeFailures(report: EvalReport): string[] {
  const notes: string[] = [];
  for (const row of report.trigger) {
    if (row.passes === row.attempts.length) continue;
    const loads = row.attempts.filter((a) => a.loaded).length;
    notes.push(
      row.expected === "load"
        ? `The description did not fire for "${firstLine(row.prompt, 120)}" (${loads}/${row.attempts.length} loads).`
        : `The description fired on the near-miss prompt "${firstLine(row.prompt, 120)}" (${loads}/${row.attempts.length} loads).`,
    );
  }
  for (const row of report.adherence) {
    for (const attempt of row.attempts) {
      for (const expectation of attempt.expectations) {
        if (expectation.verdict === "pass") continue;
        notes.push(
          `On "${firstLine(row.prompt, 80)}", expectation "${expectation.expectation}" came back ${expectation.verdict}: ${expectation.reason}`,
        );
      }
    }
  }
  return notes;
}
