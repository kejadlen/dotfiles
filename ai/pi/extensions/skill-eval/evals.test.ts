import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { evalsPathFor, loadEvalSuite, parseEvalSuite } from "./evals.ts";

test("parseEvalSuite accepts bare strings and mappings for trigger cases", () => {
  const result = parseEvalSuite({
    trigger: {
      positive: ["squash this into its parent", { prompt: "describe my change", note: "phrasing check" }],
      negative: [{ prompt: "add a git submodule" }],
    },
  });

  assert.equal(result.ok, true);
  if (!result.ok) return;
  assert.deepEqual(result.suite.triggerPositive, [
    { prompt: "squash this into its parent" },
    { prompt: "describe my change", note: "phrasing check" },
  ]);
  assert.deepEqual(result.suite.triggerNegative, [{ prompt: "add a git submodule" }]);
  assert.deepEqual(result.suite.adherence, []);
});

test("parseEvalSuite defaults adherence tools to read and keeps setup scripts", () => {
  const result = parseEvalSuite({
    adherence: [
      { prompt: "commit my work", expect: ["uses jj commit"] },
      { prompt: "rebase onto main", expect: ["uses jj rebase"], tools: ["read", "bash"], setup: "jj git init\n" },
    ],
  });

  assert.equal(result.ok, true);
  if (!result.ok) return;
  assert.deepEqual(result.suite.adherence[0].tools, ["read"]);
  assert.equal(result.suite.adherence[0].setup, undefined);
  assert.deepEqual(result.suite.adherence[1].tools, ["read", "bash"]);
  assert.equal(result.suite.adherence[1].setup, "jj git init\n");
});

test("parseEvalSuite rejects prompts pi would read as a flag or file include", () => {
  const result = parseEvalSuite({ trigger: { positive: ["--torque is wrong, fix it"] } }, "evals.yml");
  assert.equal(result.ok, false);
  if (result.ok) return;
  assert.equal(result.errors.length, 1);
  assert.match(result.errors[0], /evals\.yml:trigger\.positive\[0\]/);
  assert.match(result.errors[0], /cannot start with/);
});

test("parseEvalSuite requires at least one expectation per adherence case", () => {
  const result = parseEvalSuite({ adherence: [{ prompt: "commit my work" }] });
  assert.equal(result.ok, false);
  if (result.ok) return;
  assert.match(result.errors[0], /needs at least one expectation/);
});

test("parseEvalSuite collects every problem rather than stopping at the first", () => {
  const result = parseEvalSuite({
    trigger: { positive: [{ note: "no prompt here" }], sideways: [] },
    adherence: [{ prompt: "do a thing", expect: ["fine"], tools: "bash" }],
    extra: true,
  });

  assert.equal(result.ok, false);
  if (result.ok) return;
  assert.equal(result.errors.length, 4);
  assert.ok(result.errors.some((e) => /unknown top-level key "extra"/.test(e)));
  assert.ok(result.errors.some((e) => /trigger: unknown key "sideways"/.test(e)));
  assert.ok(result.errors.some((e) => /missing a non-empty "prompt"/.test(e)));
  assert.ok(result.errors.some((e) => /tools: expected a list of tool names/.test(e)));
});

test("parseEvalSuite reports an empty or non-mapping file", () => {
  const empty = parseEvalSuite(null, "evals.yml");
  assert.equal(empty.ok, false);
  if (!empty.ok) assert.match(empty.errors[0], /file is empty/);

  const list = parseEvalSuite([1, 2], "evals.yml");
  assert.equal(list.ok, false);
  if (!list.ok) assert.match(list.errors[0], /expected a mapping/);

  const noCases = parseEvalSuite({ trigger: { positive: [] } }, "evals.yml");
  assert.equal(noCases.ok, false);
  if (!noCases.ok) assert.match(noCases.errors[0], /no cases found/);
});

test("evalsPathFor puts the eval file next to SKILL.md", () => {
  assert.equal(evalsPathFor("/skills/jj/SKILL.md"), "/skills/jj/evals.yml");
});

test("loadEvalSuite reads the file next to the skill and validates the decoded data", async () => {
  const dir = await mkdtemp(join(tmpdir(), "skill-eval-evals-"));
  try {
    await writeFile(join(dir, "evals.yml"), "trigger:\n  positive:\n    - squash it\n");
    const seen: string[] = [];
    const result = await loadEvalSuite(join(dir, "SKILL.md"), async (text) => {
      seen.push(text);
      return { trigger: { positive: ["squash it"] } };
    });

    assert.equal(result.ok, true);
    if (!result.ok) return;
    assert.deepEqual(result.suite.triggerPositive, [{ prompt: "squash it" }]);
    assert.equal(seen[0], "trigger:\n  positive:\n    - squash it\n");
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});

test("loadEvalSuite reports a missing file with a template to copy", async () => {
  const result = await loadEvalSuite("/nonexistent/skill/SKILL.md");
  assert.equal(result.ok, false);
  if (result.ok) return;
  assert.equal((result as { missing?: true }).missing, true);
  assert.match(result.errors[0], /No eval file at \/nonexistent\/skill\/evals\.yml/);
  assert.ok(result.errors.some((e) => /trigger:/.test(e)));
});

test("loadEvalSuite surfaces YAML decoding failures", async () => {
  const dir = await mkdtemp(join(tmpdir(), "skill-eval-evals-"));
  try {
    await writeFile(join(dir, "evals.yml"), "trigger: [\n");
    const result = await loadEvalSuite(join(dir, "SKILL.md"), async () => {
      throw new Error("unexpected end of stream");
    });
    assert.equal(result.ok, false);
    if (result.ok) return;
    assert.match(result.errors[0], /could not parse YAML — unexpected end of stream/);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});
