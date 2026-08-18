/**
 * evals.yml parsing and validation.
 *
 * An eval file sits next to SKILL.md and declares two kinds of cases:
 * trigger cases (does the description make the agent reach for the skill?)
 * and adherence cases (with the skill loaded, does the agent follow it?).
 *
 * `parseEvalSuite` is pure and works on already-parsed YAML data;
 * `loadEvalSuite` handles reading and YAML decoding.
 */

import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";

export const EVALS_FILENAME = "evals.yml";

export const DEFAULT_ADHERENCE_TOOLS = ["read"];

export interface TriggerCase {
  prompt: string;
  note?: string;
}

export interface AdherenceCase {
  prompt: string;
  expect: string[];
  tools: string[];
  setup?: string;
  note?: string;
}

export interface EvalSuite {
  triggerPositive: TriggerCase[];
  triggerNegative: TriggerCase[];
  adherence: AdherenceCase[];
}

export type ParseResult =
  | { ok: true; suite: EvalSuite }
  | { ok: false; errors: string[] };

export const EVALS_TEMPLATE = `trigger:
  positive:
    # Tasks the skill should be loaded for.
    - prompt: a task phrased the way you'd actually phrase it
  negative:
    # Nearby tasks the skill should stay out of.
    - prompt: a task that sounds similar but needs a different skill

adherence:
  - prompt: a task to carry out with the skill loaded
    expect:
      # One checkable claim per line, graded against the transcript.
      - names the specific command the skill prescribes
    # Optional. Defaults to ["read"]; add tools the task genuinely needs.
    tools: [read, bash]
    # Optional shell script run in the sandbox before the agent starts.
    setup: |
      echo "scaffold fixtures here"
`;

/** Path of the eval file belonging to a SKILL.md. */
export function evalsPathFor(skillPath: string): string {
  return join(dirname(skillPath), EVALS_FILENAME);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

/** A prompt is passed to pi as an argv message, where these prefixes are consumed as flags or file includes. */
function checkPromptPrefix(prompt: string, path: string, errors: string[]): void {
  if (prompt.startsWith("-") || prompt.startsWith("@")) {
    errors.push(
      `${path}: prompt cannot start with "-" or "@" — pi reads those as a flag or a file include. Reword the prompt.`,
    );
  }
}

function parseTriggerCases(raw: unknown, path: string, errors: string[]): TriggerCase[] {
  if (raw === undefined || raw === null) return [];
  if (!Array.isArray(raw)) {
    errors.push(`${path}: expected a list of cases, got ${describe(raw)}.`);
    return [];
  }

  const cases: TriggerCase[] = [];
  raw.forEach((entry, index) => {
    const entryPath = `${path}[${index}]`;
    if (typeof entry === "string") {
      const prompt = entry.trim();
      if (!prompt) {
        errors.push(`${entryPath}: prompt is empty.`);
        return;
      }
      checkPromptPrefix(prompt, entryPath, errors);
      cases.push({ prompt });
      return;
    }
    if (!isRecord(entry)) {
      errors.push(`${entryPath}: expected a string or a mapping with a "prompt" key, got ${describe(entry)}.`);
      return;
    }
    const prompt = typeof entry.prompt === "string" ? entry.prompt.trim() : "";
    if (!prompt) {
      errors.push(`${entryPath}: missing a non-empty "prompt".`);
      return;
    }
    checkPromptPrefix(prompt, entryPath, errors);
    const note = typeof entry.note === "string" ? entry.note : undefined;
    cases.push(note ? { prompt, note } : { prompt });
  });
  return cases;
}

function parseAdherenceCases(raw: unknown, path: string, errors: string[]): AdherenceCase[] {
  if (raw === undefined || raw === null) return [];
  if (!Array.isArray(raw)) {
    errors.push(`${path}: expected a list of cases, got ${describe(raw)}.`);
    return [];
  }

  const cases: AdherenceCase[] = [];
  raw.forEach((entry, index) => {
    const entryPath = `${path}[${index}]`;
    if (!isRecord(entry)) {
      errors.push(`${entryPath}: expected a mapping with "prompt" and "expect" keys, got ${describe(entry)}.`);
      return;
    }

    const prompt = typeof entry.prompt === "string" ? entry.prompt.trim() : "";
    if (!prompt) errors.push(`${entryPath}: missing a non-empty "prompt".`);
    else checkPromptPrefix(prompt, entryPath, errors);

    const expect: string[] = [];
    if (!Array.isArray(entry.expect) || entry.expect.length === 0) {
      errors.push(`${entryPath}.expect: needs at least one expectation to grade against.`);
    } else {
      entry.expect.forEach((item, i) => {
        if (typeof item !== "string" || !item.trim()) {
          errors.push(`${entryPath}.expect[${i}]: expected a non-empty string, got ${describe(item)}.`);
          return;
        }
        expect.push(item.trim());
      });
    }

    let tools = DEFAULT_ADHERENCE_TOOLS;
    if (entry.tools !== undefined) {
      if (!Array.isArray(entry.tools) || entry.tools.some((t) => typeof t !== "string" || !t.trim())) {
        errors.push(`${entryPath}.tools: expected a list of tool names, got ${describe(entry.tools)}.`);
      } else {
        tools = (entry.tools as string[]).map((t) => t.trim());
      }
    }

    let setup: string | undefined;
    if (entry.setup !== undefined) {
      if (typeof entry.setup !== "string") {
        errors.push(`${entryPath}.setup: expected a shell script string, got ${describe(entry.setup)}.`);
      } else if (entry.setup.trim()) {
        setup = entry.setup;
      }
    }

    if (!prompt || expect.length === 0) return;
    const note = typeof entry.note === "string" ? entry.note : undefined;
    cases.push({ prompt, expect, tools, ...(setup ? { setup } : {}), ...(note ? { note } : {}) });
  });
  return cases;
}

function describe(value: unknown): string {
  if (value === null) return "null";
  if (Array.isArray(value)) return "a list";
  return typeof value;
}

/** Validate decoded evals.yml data. Collects every problem rather than failing on the first. */
export function parseEvalSuite(data: unknown, source = EVALS_FILENAME): ParseResult {
  const errors: string[] = [];

  if (data === null || data === undefined) {
    return { ok: false, errors: [`${source}: file is empty.`] };
  }
  if (!isRecord(data)) {
    return { ok: false, errors: [`${source}: expected a mapping with "trigger" and/or "adherence" keys, got ${describe(data)}.`] };
  }

  const known = new Set(["trigger", "adherence"]);
  for (const key of Object.keys(data)) {
    if (!known.has(key)) errors.push(`${source}: unknown top-level key "${key}" (expected "trigger" or "adherence").`);
  }

  let triggerPositive: TriggerCase[] = [];
  let triggerNegative: TriggerCase[] = [];
  if (data.trigger !== undefined && data.trigger !== null) {
    if (!isRecord(data.trigger)) {
      errors.push(`${source}:trigger: expected a mapping with "positive" and/or "negative" keys, got ${describe(data.trigger)}.`);
    } else {
      for (const key of Object.keys(data.trigger)) {
        if (key !== "positive" && key !== "negative") {
          errors.push(`${source}:trigger: unknown key "${key}" (expected "positive" or "negative").`);
        }
      }
      triggerPositive = parseTriggerCases(data.trigger.positive, `${source}:trigger.positive`, errors);
      triggerNegative = parseTriggerCases(data.trigger.negative, `${source}:trigger.negative`, errors);
    }
  }

  const adherence = parseAdherenceCases(data.adherence, `${source}:adherence`, errors);

  if (triggerPositive.length + triggerNegative.length + adherence.length === 0 && errors.length === 0) {
    errors.push(`${source}: no cases found. Add trigger cases, adherence cases, or both.`);
  }

  if (errors.length > 0) return { ok: false, errors };
  return { ok: true, suite: { triggerPositive, triggerNegative, adherence } };
}

/**
 * The `yaml` package ships inside pi but isn't resolvable from an extension
 * directory, so decode through pi's own frontmatter parser, which wraps it.
 */
async function defaultYamlParser(text: string): Promise<unknown> {
  // The wrapper below ends at the first unindented `---`, which would silently
  // truncate the file, so reject that line outright.
  if (text.split("\n").some((line) => line.trimEnd() === "---")) {
    throw new Error('a line containing only "---" is not supported; indent it or quote it');
  }
  const mod: any = await import("@earendil-works/pi-coding-agent");
  const wrapped = text.endsWith("\n") ? text : `${text}\n`;
  return mod.parseFrontmatter(`---\n${wrapped}---\n`).frontmatter;
}

export type LoadResult = ParseResult | { ok: false; errors: string[]; missing: true };

/** Read and validate the evals.yml next to a SKILL.md. */
export async function loadEvalSuite(
  skillPath: string,
  parseYaml: (text: string) => Promise<unknown> = defaultYamlParser,
): Promise<LoadResult> {
  const path = evalsPathFor(skillPath);
  let text: string;
  try {
    text = await readFile(path, "utf8");
  } catch {
    return {
      ok: false,
      missing: true,
      errors: [
        `No eval file at ${path}. Create one to describe what this skill should do:`,
        "",
        EVALS_TEMPLATE,
      ],
    };
  }

  let data: unknown;
  try {
    data = await parseYaml(text);
  } catch (error) {
    return { ok: false, errors: [`${path}: could not parse YAML — ${(error as Error).message}`] };
  }
  return parseEvalSuite(data, path);
}
