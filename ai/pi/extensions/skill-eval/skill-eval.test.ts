import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, mkdir, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { parseAvailableSkillsBlock, loadSkillsFromContext, discoverAgentsFiles } from "./index.ts";

test("parseAvailableSkillsBlock extracts name, description, and location", () => {
  const systemPrompt = [
    "You are an expert coding assistant.",
    "",
    "<available_skills>",
    "  <skill>",
    "    <name>jj</name>",
    "    <description>Use when running jj commands &amp; you&apos;re unsure of flags.</description>",
    "    <location>/home/user/skills/jj/SKILL.md</location>",
    "  </skill>",
    "  <skill>",
    "    <name>bash</name>",
    "    <description>Use when writing shell scripts.</description>",
    "    <location>/home/user/skills/bash/SKILL.md</location>",
    "  </skill>",
    "</available_skills>",
    "Current date: 2026-01-01",
  ].join("\n");

  const skills = parseAvailableSkillsBlock(systemPrompt);
  assert.equal(skills.length, 2);
  assert.deepEqual(skills[0], {
    name: "jj",
    description: "Use when running jj commands & you're unsure of flags.",
    filePath: "/home/user/skills/jj/SKILL.md",
  });
  assert.equal(skills[1].name, "bash");
});

test("parseAvailableSkillsBlock returns an empty array when no block is present", () => {
  assert.deepEqual(parseAvailableSkillsBlock("You are an expert coding assistant.\nCurrent date: 2026-01-01"), []);
});

test("loadSkillsFromContext reads line count and mtime for each skill file", async () => {
  const dir = await mkdtemp(join(tmpdir(), "skill-eval-context-"));
  try {
    const skillPath = join(dir, "SKILL.md");
    await writeFile(skillPath, ["# Body", "line 2", "line 3"].join("\n"));

    const skills = await loadSkillsFromContext([
      { name: "my-skill", description: "A test skill.", filePath: skillPath },
    ]);
    assert.equal(skills.length, 1);
    assert.equal(skills[0].name, "my-skill");
    assert.equal(skills[0].description, "A test skill.");
    assert.equal(skills[0].path, skillPath);
    assert.equal(skills[0].lineCount, 3);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});

test("loadSkillsFromContext skips skills whose file can't be read", async () => {
  const skills = await loadSkillsFromContext([
    { name: "missing", description: "gone", filePath: "/nonexistent/SKILL.md" },
  ]);
  assert.deepEqual(skills, []);
});

test("discoverAgentsFiles walks up from cwd and stops at repo boundary", async () => {
  const root = await mkdtemp(join(tmpdir(), "skill-eval-agents-"));
  try {
    await mkdir(join(root, ".jj"), { recursive: true });
    await writeFile(join(root, "AGENTS.md"), "# Root\nline2\n");
    const nested = join(root, "sub", "dir");
    await mkdir(nested, { recursive: true });

    const files = await discoverAgentsFiles(nested);
    const rootFile = files.find((f) => f.path === join(root, "AGENTS.md"));
    assert.ok(rootFile, "expected root AGENTS.md to be discovered");
    assert.equal(rootFile.lineCount, 2);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

import { scanSkillUsage } from "./index.ts";

function sessionLine(entry: unknown): string {
  return JSON.stringify(entry) + "\n";
}

test("scanSkillUsage counts read tool calls matching a skill path within the window", async () => {
  const dir = await mkdtemp(join(tmpdir(), "skill-eval-sessions-"));
  try {
    const skillPath = "/home/user/.dotfiles/ai/skills/foo/SKILL.md";
    const projectDir = join(dir, "--home-user-project--");
    await mkdir(projectDir, { recursive: true });

    const now = Date.now();
    const withinWindow = new Date(now - 1000).toISOString();
    const outsideWindow = new Date(now - 200 * 24 * 60 * 60 * 1000).toISOString();

    const lines =
      sessionLine({ type: "session", version: 3, id: "s1", timestamp: withinWindow, cwd: "/home/user/project" }) +
      sessionLine({
        type: "message",
        id: "a1",
        parentId: null,
        timestamp: withinWindow,
        message: {
          role: "assistant",
          content: [{ type: "toolCall", id: "t1", name: "read", arguments: { path: skillPath } }],
          provider: "anthropic",
          model: "test",
          usage: {},
          stopReason: "toolUse",
        },
      }) +
      sessionLine({
        type: "message",
        id: "a2",
        parentId: "a1",
        timestamp: outsideWindow,
        message: {
          role: "assistant",
          content: [{ type: "toolCall", id: "t2", name: "read", arguments: { path: skillPath } }],
          provider: "anthropic",
          model: "test",
          usage: {},
          stopReason: "toolUse",
        },
      }) +
      "not valid json\n";

    await writeFile(join(projectDir, "session1.jsonl"), lines);

    const usage = await scanSkillUsage(dir, [skillPath], now - 90 * 24 * 60 * 60 * 1000);
    const stats = usage.get(skillPath);
    assert.ok(stats, "expected usage entry for skill path");
    assert.equal(stats!.count, 1);
    assert.ok(stats!.lastUsed !== null);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});

test("scanSkillUsage ignores read calls for paths that don't match any skill", async () => {
  const dir = await mkdtemp(join(tmpdir(), "skill-eval-sessions-"));
  try {
    const projectDir = join(dir, "--home-user-project--");
    await mkdir(projectDir, { recursive: true });
    const now = new Date().toISOString();
    const lines = sessionLine({
      type: "message",
      id: "a1",
      parentId: null,
      timestamp: now,
      message: {
        role: "assistant",
        content: [{ type: "toolCall", id: "t1", name: "read", arguments: { path: "/some/other/file.md" } }],
        provider: "anthropic",
        model: "test",
        usage: {},
        stopReason: "toolUse",
      },
    });
    await writeFile(join(projectDir, "session1.jsonl"), lines);

    const usage = await scanSkillUsage(dir, ["/home/user/.dotfiles/ai/skills/foo/SKILL.md"], 0);
    assert.equal(usage.size, 0);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});

test("scanSkillUsage returns an empty map when the sessions directory doesn't exist", async () => {
  const usage = await scanSkillUsage("/nonexistent/sessions/dir", ["/skills/foo/SKILL.md"], 0);
  assert.equal(usage.size, 0);
});

import { computeVerboseThreshold, rankSkills } from "./index.ts";

function fakeSkill(name: string, lineCount: number): import("./index.ts").SkillMeta {
  return { name, description: "", path: `/skills/${name}/SKILL.md`, lineCount, lastModified: 0 };
}

test("computeVerboseThreshold returns the 75th percentile line count", () => {
  const skills = [10, 20, 30, 40, 50, 60, 70, 80].map((n, i) => fakeSkill(`s${i}`, n));
  assert.equal(computeVerboseThreshold(skills), 70);
});

test("computeVerboseThreshold returns 0 for an empty list", () => {
  assert.equal(computeVerboseThreshold([]), 0);
});

test("rankSkills flags verbose and stale skills and sorts flagged ones first", () => {
  const skills = [fakeSkill("short-used", 10), fakeSkill("long-unused", 200), fakeSkill("long-used", 200)];
  const usage = new Map([
    ["/skills/short-used/SKILL.md", { count: 5, lastUsed: 1000 }],
    ["/skills/long-used/SKILL.md", { count: 3, lastUsed: 2000 }],
  ]);

  const rows = rankSkills(skills, usage, 150);

  assert.equal(rows[0].name, "long-unused");
  assert.equal(rows[0].verbose, true);
  assert.equal(rows[0].stale, true);

  const longUsedRow = rows.find((r) => r.name === "long-used")!;
  assert.equal(longUsedRow.verbose, true);
  assert.equal(longUsedRow.stale, false);

  const shortUsedRow = rows.find((r) => r.name === "short-used")!;
  assert.equal(shortUsedRow.verbose, false);
  assert.equal(shortUsedRow.stale, false);
});

import { formatTriageMarkdown, resolveReportPath, writeReport } from "./index.ts";
import { readFile as readFileP } from "node:fs/promises";

test("formatTriageMarkdown includes skill and AGENTS.md sections", () => {
  const rows = [
    {
      kind: "skill" as const,
      name: "foo",
      path: "/skills/foo/SKILL.md",
      lineCount: 200,
      usage: { count: 0, lastUsed: null },
      verbose: true,
      stale: true,
    },
  ];
  const agentsFiles = [{ path: "/home/user/AGENTS.md", lineCount: 60, lastModified: 0 }];
  const md = formatTriageMarkdown(rows, agentsFiles, new Date("2026-01-01T00:00:00.000Z"));

  assert.match(md, /## Skills/);
  assert.match(md, /foo/);
  assert.match(md, /200/);
  assert.match(md, /## AGENTS\.md files/);
  assert.match(md, /\/home\/user\/AGENTS\.md/);
});

test("resolveReportPath builds a path under the given state base dir", () => {
  const now = new Date("2026-01-01T00:00:00.000Z");
  const path = resolveReportPath(now, "/fake/state");
  assert.equal(path, join("/fake/state", "pi", "skill-eval", "reports", "2026-01-01T00-00-00-000Z.md"));
});

test("resolveReportPath appends a filename-safe label", () => {
  const path = resolveReportPath(new Date("2026-01-01T00:00:00.000Z"), "/fake/state", "eval-jj workspaces");
  assert.equal(
    path,
    join("/fake/state", "pi", "skill-eval", "reports", "2026-01-01T00-00-00-000Z-eval-jj_workspaces.md"),
  );
});

test("writeReport creates parent directories and writes content", async () => {
  const dir = await mkdtemp(join(tmpdir(), "skill-eval-report-"));
  try {
    const reportPath = join(dir, "nested", "report.md");
    await writeReport("# hello\n", reportPath);
    const content = await readFileP(reportPath, "utf8");
    assert.equal(content, "# hello\n");
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});

import { resolveTarget, buildReviewPrompt } from "./index.ts";

const jjSkill = fakeSkill("jj", 50);
const jjWorkspacesSkill = fakeSkill("jj-workspaces", 60);
const agentsFile = { path: "/home/user/AGENTS.md", lineCount: 60, lastModified: 0 };

test("resolveTarget matches an exact skill name", () => {
  const result = resolveTarget("jj", [jjSkill, jjWorkspacesSkill], [agentsFile]);
  assert.equal(result.ok, true);
  if (result.ok) {
    assert.equal(result.kind, "skill");
    assert.equal(result.meta.name, "jj");
  }
});

test("resolveTarget reports ambiguous when multiple substrings match", () => {
  const result = resolveTarget("jj", [jjWorkspacesSkill, fakeSkill("jjx", 10)], [agentsFile]);
  // "jj" is not an exact match for either "jj-workspaces" or "jjx", so it falls
  // through to substring matching against both.
  assert.equal(result.ok, false);
  if (!result.ok) {
    assert.equal(result.reason, "ambiguous");
    assert.ok(result.candidates.includes("jj-workspaces"));
    assert.ok(result.candidates.includes("jjx"));
  }
});

test("resolveTarget reports not_found with candidates when nothing matches", () => {
  const result = resolveTarget("nonexistent", [jjSkill], [agentsFile]);
  assert.equal(result.ok, false);
  if (!result.ok) {
    assert.equal(result.reason, "not_found");
    assert.ok(result.candidates.length > 0);
  }
});

test("resolveTarget matches AGENTS.md by basename", () => {
  const result = resolveTarget("AGENTS.md", [jjSkill], [agentsFile]);
  assert.equal(result.ok, true);
  if (result.ok) {
    assert.equal(result.kind, "agents");
  }
});

test("buildReviewPrompt includes size, usage, and content for skills", () => {
  const prompt = buildReviewPrompt("skill", "jj", "# jj skill content\nline two\n", { count: 3, lastUsed: 1735689600000 });
  assert.match(prompt, /2 lines\. Usage in the last 90 days: 3/);
  assert.match(prompt, /jj skill content/);
  assert.match(prompt, /tighten-docs/);
  assert.match(prompt, /Efficacy outranks size/);
});

test("buildReviewPrompt notes no usage signal for AGENTS.md", () => {
  const prompt = buildReviewPrompt("agents", "/home/user/AGENTS.md", "# instructions", null);
  assert.match(prompt, /1 line\. No usage signal available/);
});

import { parseCommandArgs, tokenizeArgs } from "./index.ts";

test("parseCommandArgs treats no arguments and an explicit subcommand as triage", () => {
  assert.deepEqual(parseCommandArgs(""), { action: "triage" });
  assert.deepEqual(parseCommandArgs("   "), { action: "triage" });
  assert.deepEqual(parseCommandArgs("triage"), { action: "triage" });
});

test("parseCommandArgs keeps the bare-target form working as a review", () => {
  assert.deepEqual(parseCommandArgs("jj"), { action: "review", target: "jj" });
  assert.deepEqual(parseCommandArgs("review jj"), { action: "review", target: "jj" });
});

test("parseCommandArgs reads run flags and applies defaults", () => {
  assert.deepEqual(parseCommandArgs("run jj"), { action: "run", target: "jj", repeat: 1, jobs: 3, cases: [] });
  assert.deepEqual(parseCommandArgs("run jj --repeat 3 --jobs 1 --only trigger"), {
    action: "run",
    target: "jj",
    repeat: 3,
    jobs: 1,
    cases: [],
    only: "trigger",
  });
});

test("parseCommandArgs collects repeated --case filters", () => {
  assert.deepEqual(parseCommandArgs("run jj --case pitfall --case squash"), {
    action: "run",
    target: "jj",
    repeat: 1,
    jobs: 3,
    cases: ["pitfall", "squash"],
  });
});

test("parseCommandArgs rejects malformed input with a specific message", () => {
  const cases: [string, RegExp][] = [
    ["run", /needs a skill name/],
    ["run jj bash", /exactly one skill/],
    ["run jj --repeat 0", /positive integer/],
    ["run jj --jobs two", /positive integer/],
    ["run jj --only sideways", /trigger or adherence/],
    ["run jj --wat", /Unknown flag --wat/],
    ["run jj --case", /--case needs a substring/],
    ["run jj --case --jobs 2", /--case needs a substring/],
    ["triage jj", /takes no arguments/],
    ["review", /exactly one target/],
    ["review a b", /exactly one target/],
    ["frobnicate jj", /Unknown subcommand "frobnicate"/],
  ];
  for (const [args, pattern] of cases) {
    const parsed = parseCommandArgs(args);
    assert.equal(parsed.action, "error", `expected an error for "${args}"`);
    if (parsed.action === "error") assert.match(parsed.message, pattern);
  }
});

test("tokenizeArgs keeps quoted runs together and drops the quotes", () => {
  assert.deepEqual(tokenizeArgs("run jj --case 'Squash @ into'"), ["run", "jj", "--case", "Squash @ into"]);
  assert.deepEqual(tokenizeArgs('run jj --case "file show"'), ["run", "jj", "--case", "file show"]);
  assert.deepEqual(tokenizeArgs("  run   jj  "), ["run", "jj"]);
  assert.deepEqual(tokenizeArgs(""), []);
  assert.deepEqual(tokenizeArgs("run jj --case ''"), ["run", "jj", "--case", ""]);
});

test("parseCommandArgs accepts a quoted multi-word case filter", () => {
  assert.deepEqual(parseCommandArgs("run jj --case 'Squash @ into'"), {
    action: "run",
    target: "jj",
    repeat: 1,
    jobs: 3,
    cases: ["Squash @ into"],
  });
});
