import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  buildJudgePrompt,
  formatEvalReport,
  loadedSkill,
  mapWithConcurrency,
  filterSuite,
  matchesFilters,
  parseJudgeVerdicts,
  runEvals,
  skillLoadPath,
  summarizeFailures,
  type EvalReport,
} from "./run.ts";

test("loadedSkill matches reads anywhere inside the skill directory", () => {
  const skillPath = "/skills/jj/SKILL.md";
  assert.equal(loadedSkill([{ name: "read", args: { path: "/skills/jj/SKILL.md" } }], skillPath), true);
  assert.equal(loadedSkill([{ name: "read", args: { path: "/skills/jj/references/rebase.md" } }], skillPath), true);
  assert.equal(loadedSkill([{ name: "read", args: { path: "/skills/jj/../jj/SKILL.md" } }], skillPath), true);
});

test("loadedSkill ignores other skills, other tools, and malformed arguments", () => {
  const skillPath = "/skills/jj/SKILL.md";
  assert.equal(loadedSkill([{ name: "read", args: { path: "/skills/jj-workspaces/SKILL.md" } }], skillPath), false);
  assert.equal(loadedSkill([{ name: "bash", args: { command: "cat /skills/jj/SKILL.md" } }], skillPath), false);
  assert.equal(loadedSkill([{ name: "read", args: {} }], skillPath), false);
  assert.equal(loadedSkill([], skillPath), false);
});

test("loadedSkill counts only the file itself for a bare .md skill", () => {
  const skillPath = "/skills/jj.md";
  assert.equal(loadedSkill([{ name: "read", args: { path: "/skills/jj.md" } }], skillPath), true);
  assert.equal(loadedSkill([{ name: "read", args: { path: "/skills/bash.md" } }], skillPath), false);
});

test("skillLoadPath passes the bundle directory for SKILL.md and the file otherwise", () => {
  assert.equal(skillLoadPath("/skills/jj/SKILL.md"), "/skills/jj");
  assert.equal(skillLoadPath("/skills/jj.md"), "/skills/jj.md");
});

test("buildJudgePrompt numbers expectations and carries task and transcript", () => {
  const prompt = buildJudgePrompt("jj", "commit my work", "[assistant] jj commit", ["uses jj commit", "adds a trailer"]);
  assert.match(prompt, /"jj" skill/);
  assert.match(prompt, /1\. uses jj commit/);
  assert.match(prompt, /2\. adds a trailer/);
  assert.match(prompt, /commit my work/);
  assert.match(prompt, /\[assistant\] jj commit/);
});

test("buildJudgePrompt notes an empty transcript rather than sending nothing", () => {
  assert.match(buildJudgePrompt("jj", "task", "", ["something"]), /the agent produced no output/);
});

test("parseJudgeVerdicts reads a fenced array and matches verdicts by index", () => {
  const reply = [
    "Here are my verdicts:",
    "```json",
    '[{"index": 2, "verdict": "fail", "reason": "no trailer"},',
    ' {"index": 1, "verdict": "pass", "reason": "ran jj commit"}]',
    "```",
  ].join("\n");
  const results = parseJudgeVerdicts(reply, ["uses jj commit", "adds a trailer"]);
  assert.deepEqual(results, [
    { expectation: "uses jj commit", verdict: "pass", reason: "ran jj commit" },
    { expectation: "adds a trailer", verdict: "fail", reason: "no trailer" },
  ]);
});

test("parseJudgeVerdicts falls back to unclear when the reply is unusable", () => {
  for (const reply of ["I could not tell.", "[not json]", '{"verdict":"pass"}']) {
    const results = parseJudgeVerdicts(reply, ["a", "b"]);
    assert.equal(results.length, 2);
    assert.ok(results.every((r) => r.verdict === "unclear"));
  }
});

test("parseJudgeVerdicts treats unknown verdict values as unclear", () => {
  const results = parseJudgeVerdicts('[{"index":1,"verdict":"maybe","reason":"hmm"}]', ["a"]);
  assert.deepEqual(results, [{ expectation: "a", verdict: "unclear", reason: "hmm" }]);
});

test("mapWithConcurrency preserves order and respects the limit", async () => {
  let inFlight = 0;
  let peak = 0;
  const results = await mapWithConcurrency([10, 20, 30, 40, 50], 2, async (item) => {
    inFlight++;
    peak = Math.max(peak, inFlight);
    await new Promise((r) => setTimeout(r, item % 30));
    inFlight--;
    return item * 2;
  });
  assert.deepEqual(results, [20, 40, 60, 80, 100]);
  assert.equal(peak, 2);
});

const report: EvalReport = {
  skillName: "widget-wrangler",
  skillPath: "/skills/widget-wrangler/SKILL.md",
  model: "anthropic/claude-opus-5",
  thinking: "high",
  repeat: 1,
  trigger: [
    { kind: "trigger", expected: "load", prompt: "calibrate the bench widget", attempts: [{ loaded: true, retries: [] }], passes: 1, costUsd: 0.01 },
    { kind: "trigger", expected: "load", prompt: "check widget torque", attempts: [{ loaded: false, retries: [] }], passes: 0, costUsd: 0.01 },
    { kind: "trigger", expected: "skip", prompt: "what is 2 + 2", attempts: [{ loaded: true, retries: [] }], passes: 0, costUsd: 0.01 },
  ],
  adherence: [
    {
      kind: "adherence",
      prompt: "calibrate it and report the torque",
      attempts: [
        {
          transcript: "[assistant] wrangle --torque 42",
          retries: [],
          expectations: [
            { expectation: "names the torque value 42", verdict: "pass", reason: "said 42" },
            { expectation: "reports newton-metres", verdict: "fail", reason: "no units given" },
          ],
        },
      ],
      passes: 0,
      costUsd: 0.05,
    },
  ],
  costUsd: 0.08,
  runs: 4,
  startedAt: new Date("2026-01-01T00:00:00.000Z"),
  finishedAt: new Date("2026-01-01T00:01:00.000Z"),
};

test("formatEvalReport scores both sections and lists misses", () => {
  const markdown = formatEvalReport(report);
  assert.match(markdown, /# Skill eval: widget-wrangler/);
  assert.match(markdown, /anthropic\/claude-opus-5 \(thinking: high\).*\$0\.0800.*60s/);
  assert.match(markdown, /## Trigger fidelity — 1\/3/);
  assert.match(markdown, /\| load \| 0\/1 \| check widget torque \|/);
  assert.match(markdown, /did not load: check widget torque/);
  assert.match(markdown, /loaded when it should not have: what is 2 \+ 2/);
  assert.match(markdown, /## Instruction adherence — 0\/1/);
  assert.match(markdown, /- fail: reports newton-metres — no units given/);
});

test("summarizeFailures reports each miss and each unmet expectation", () => {
  const notes = summarizeFailures(report);
  assert.equal(notes.length, 3);
  assert.match(notes[0], /did not fire for "check widget torque"/);
  assert.match(notes[1], /fired on the near-miss prompt "what is 2 \+ 2"/);
  assert.match(notes[2], /"reports newton-metres" came back fail: no units given/);
});

test("summarizeFailures says nothing when every case passed", () => {
  const clean: EvalReport = {
    ...report,
    trigger: [
      { kind: "trigger", expected: "load", prompt: "p", attempts: [{ loaded: true, retries: [] }], passes: 1, costUsd: 0 },
    ],
    adherence: [],
  };
  assert.deepEqual(summarizeFailures(clean), []);
});

test("formatEvalReport warns when the provider retried, so scores aren't misread", () => {
  const retried: EvalReport = {
    ...report,
    trigger: [
      {
        kind: "trigger",
        expected: "load",
        prompt: "p",
        attempts: [{ loaded: false, retries: [{ attempt: 1, maxAttempts: 3, errorMessage: "overloaded_error" }] }],
        passes: 0,
        costUsd: 0,
      },
    ],
    adherence: [],
  };
  const markdown = formatEvalReport(retried);
  assert.match(markdown, /1 provider retry during this run, first: overloaded_error/);
  assert.match(markdown, /may reflect the provider, not the skill/);
});

test("formatEvalReport stays quiet about retries when there were none", () => {
  assert.doesNotMatch(formatEvalReport(report), /provider retr/);
});

/**
 * End-to-end orchestration against a stub pi entrypoint: no API credit, but it
 * exercises argument construction, sandboxing, setup scripts, and judging.
 */
const FAKE_PI = `
const args = process.argv.slice(2);
let stdin = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (c) => (stdin += c));
process.stdin.on("end", () => {
  const emit = (o) => process.stdout.write(JSON.stringify(o) + "\\n");
  if (args.includes("--no-tools")) {
    // Judge run: pass the first expectation, fail the rest.
    const count = (stdin.match(/^\\d+\\. /gm) || []).length;
    const verdicts = Array.from({ length: count }, (_, i) => ({
      index: i + 1,
      verdict: i === 0 ? "pass" : "fail",
      reason: "stub verdict",
    }));
    emit({ type: "agent_end", messages: [{ role: "assistant", content: [{ type: "text", text: JSON.stringify(verdicts) }], usage: { cost: { total: 0.001 } } }] });
    return;
  }
  const skillDir = args[args.indexOf("--skill") + 1];
  if (args.some((a) => a.startsWith("/skill:"))) {
    // Adherence run: record the sandbox contents so setup scripts are observable.
    const fs = require("node:fs");
    emit({ type: "agent_end", messages: [{ role: "assistant", content: [{ type: "text", text: "sandbox: " + fs.readdirSync(process.cwd()).join(",") }], usage: { cost: { total: 0.002 } } }] });
    return;
  }
  // Trigger run: load the skill only when the prompt mentions widgets.
  if (/widget/.test(stdin)) emit({ type: "tool_execution_start", toolName: "read", args: { path: skillDir + "/SKILL.md" } });
  emit({ type: "agent_end", messages: [{ role: "assistant", content: [{ type: "text", text: "done" }], usage: { cost: { total: 0.003 } } }] });
});
`;

test("runEvals scores trigger and adherence cases end to end", async () => {
  const dir = await mkdtemp(join(tmpdir(), "skill-eval-run-"));
  const previous = process.env.PI_BIN;
  try {
    const fakePi = join(dir, "fake-pi.js");
    await writeFile(fakePi, FAKE_PI);
    process.env.PI_BIN = fakePi;

    const result = await runEvals({
      skillName: "widget-wrangler",
      skillPath: join(dir, "SKILL.md"),
      suite: {
        triggerPositive: [{ prompt: "calibrate the widget" }],
        triggerNegative: [{ prompt: "what is 2 + 2" }, { prompt: "the widget question again" }],
        adherence: [
          { prompt: "calibrate it", expect: ["first", "second"], tools: ["read"], setup: "touch fixture.txt" },
        ],
      },
      config: { provider: "anthropic", model: "test-model", thinking: "high", repeat: 1, jobs: 2, timeoutMs: 10_000 },
    });

    assert.equal(result.runs, 4);
    assert.deepEqual(
      result.trigger.map((r) => [r.expected, r.passes]),
      [
        ["load", 1],
        ["skip", 1],
        ["skip", 0],
      ],
    );
    assert.deepEqual(
      result.adherence[0].attempts[0].expectations.map((e) => e.verdict),
      ["pass", "fail"],
    );
    assert.match(result.adherence[0].attempts[0].transcript, /sandbox: fixture\.txt/);
    assert.ok(result.costUsd > 0);
  } finally {
    if (previous === undefined) delete process.env.PI_BIN;
    else process.env.PI_BIN = previous;
    await rm(dir, { recursive: true, force: true });
  }
});

test("runEvals marks a case unclear when its setup script fails", async () => {
  const dir = await mkdtemp(join(tmpdir(), "skill-eval-run-"));
  const previous = process.env.PI_BIN;
  try {
    const fakePi = join(dir, "fake-pi.js");
    await writeFile(fakePi, FAKE_PI);
    process.env.PI_BIN = fakePi;

    const result = await runEvals({
      skillName: "widget-wrangler",
      skillPath: join(dir, "SKILL.md"),
      suite: {
        triggerPositive: [],
        triggerNegative: [],
        adherence: [{ prompt: "calibrate it", expect: ["first"], tools: ["read"], setup: "exit 7" }],
      },
      config: { provider: "anthropic", model: "test-model", repeat: 1, jobs: 1, timeoutMs: 10_000 },
    });

    const attempt = result.adherence[0].attempts[0];
    assert.match(attempt.error ?? "", /setup script failed/);
    assert.equal(attempt.expectations[0].verdict, "unclear");
  } finally {
    if (previous === undefined) delete process.env.PI_BIN;
    else process.env.PI_BIN = previous;
    await rm(dir, { recursive: true, force: true });
  }
});

test("runEvals honors --only by skipping the other section", async () => {
  const dir = await mkdtemp(join(tmpdir(), "skill-eval-run-"));
  const previous = process.env.PI_BIN;
  try {
    const fakePi = join(dir, "fake-pi.js");
    await writeFile(fakePi, FAKE_PI);
    process.env.PI_BIN = fakePi;

    const suite = {
      triggerPositive: [{ prompt: "calibrate the widget" }],
      triggerNegative: [],
      adherence: [{ prompt: "calibrate it", expect: ["first"], tools: ["read"] }],
    };
    const config = { provider: "anthropic", model: "test-model", repeat: 1, jobs: 1, timeoutMs: 10_000 };

    const triggerOnly = await runEvals({ skillName: "w", skillPath: join(dir, "SKILL.md"), suite, config, only: "trigger" });
    assert.equal(triggerOnly.trigger.length, 1);
    assert.equal(triggerOnly.adherence.length, 0);

    const adherenceOnly = await runEvals({ skillName: "w", skillPath: join(dir, "SKILL.md"), suite, config, only: "adherence" });
    assert.equal(adherenceOnly.trigger.length, 0);
    assert.equal(adherenceOnly.adherence.length, 1);
  } finally {
    if (previous === undefined) delete process.env.PI_BIN;
    else process.env.PI_BIN = previous;
    await rm(dir, { recursive: true, force: true });
  }
});

test("runEvals reports progress for every attempt", async () => {
  const dir = await mkdtemp(join(tmpdir(), "skill-eval-run-"));
  const previous = process.env.PI_BIN;
  try {
    const fakePi = join(dir, "fake-pi.js");
    await writeFile(fakePi, FAKE_PI);
    process.env.PI_BIN = fakePi;

    const seen: string[] = [];
    await runEvals({
      skillName: "widget-wrangler",
      skillPath: join(dir, "SKILL.md"),
      suite: { triggerPositive: [{ prompt: "calibrate the widget" }], triggerNegative: [], adherence: [] },
      config: {
        provider: "anthropic",
        model: "test-model",
        repeat: 2,
        jobs: 1,
        timeoutMs: 10_000,
        onProgress: (done, total, label) => seen.push(`${done}/${total} ${label}`),
      },
    });

    assert.deepEqual(seen, ["1/2 trigger: calibrate the widget", "2/2 trigger: calibrate the widget"]);
  } finally {
    if (previous === undefined) delete process.env.PI_BIN;
    else process.env.PI_BIN = previous;
    await rm(dir, { recursive: true, force: true });
  }
});

test("matchesFilters looks at both the prompt and the note, case-insensitively", () => {
  const testCase = { prompt: "Squash @ into its parent", note: "pitfall: editor hang" };
  assert.equal(matchesFilters(testCase, []), true);
  assert.equal(matchesFilters(testCase, ["PITFALL"]), true);
  assert.equal(matchesFilters(testCase, ["squash @"]), true);
  assert.equal(matchesFilters(testCase, ["rebase"]), false);
  assert.equal(matchesFilters(testCase, ["rebase", "editor"]), true);
});

test("filterSuite narrows every section and leaves an unfiltered suite alone", () => {
  const suite = {
    triggerPositive: [{ prompt: "squash this" }, { prompt: "push a stack" }],
    triggerNegative: [{ prompt: "git submodule" }],
    adherence: [
      { prompt: "squash into parent", expect: ["a"], tools: ["read"] },
      { prompt: "push bottom-first", expect: ["b"], tools: ["read"] },
    ],
  };

  const filtered = filterSuite(suite, ["squash"]);
  assert.deepEqual(filtered.triggerPositive, [{ prompt: "squash this" }]);
  assert.deepEqual(filtered.triggerNegative, []);
  assert.equal(filtered.adherence.length, 1);
  assert.equal(filtered.adherence[0].prompt, "squash into parent");

  assert.deepEqual(filterSuite(suite, []), suite);
});
