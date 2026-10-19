---
name: skill-notes
description: Use when creating a new SKILL.md file, reviewing an existing skill for quality, or when the user asks about skill authoring conventions
---

# Skill Notes

Supplementary notes on writing effective skills, accumulated from experience and external sources.

*This is a self-improving skill. If you used it and it came up short — a missing command, flag, gotcha, or workflow — invoke the `self-improving-skills` skill and follow it before you finish.*

## Skill Categories

When deciding what skill to build, these categories help identify gaps:

| Category | What it does |
|---|---|
| Library/API reference | How to use an internal library, CLI, or SDK — edge cases, footguns, snippets |
| Product verification | How to test that code works — often paired with playwright, tmux, etc. |
| Data fetching | Connect to data/monitoring stacks — credentials, dashboard IDs, common queries |
| Business process | Automate repetitive workflows into one command |
| Code scaffolding | Generate framework boilerplate for your codebase |
| Code quality/review | Enforce org code quality — can run via hooks or CI |
| CI/CD & deployment | Fetch, push, deploy code — may reference other skills |
| Runbooks | Symptom → investigation → structured report |
| Infrastructure ops | Routine maintenance with guardrails for destructive actions |

## Memory and Stored Data

Skills can maintain state across sessions by writing to files — append-only logs, JSON, even SQLite. For example, a standup skill that keeps a log of previous posts so it can diff against yesterday.

Store persistent data in a stable location that survives skill upgrades rather than in the skill directory itself.

## Store Scripts for Composition

Bundling helper scripts and libraries in the skill directory lets the model spend its turns on composition rather than reconstructing boilerplate. For data-heavy skills, include helper functions the model can compose into generated scripts on the fly.

## On-Demand Hooks (Claude Code only)

Claude Code skills can register hooks that activate only when the skill is invoked and last for the session. Use this for opinionated guardrails you don't want running all the time — e.g., a `/careful` skill that blocks `rm -rf`, `DROP TABLE`, force-push via a PreToolUse matcher when touching prod.

## Frontmatter Beyond the Documented Three

The public docs list `name`, `description`, and `allowed-tools`, but the skill
loader reads more. It resolves `model` — any of `sonnet`, `opus`, `haiku`,
`fable`, `best`, `opusplan`, the `[1m]` long-context variants, or the literal
`inherit` — and `effort`, one of `low`, `medium`, `high`, `xhigh`, `max`, or an
integer, warning when it can't parse the value. A mechanical skill that runs
commands and compares output against documented expectations belongs on
`model: haiku`, and often `effort: low` with it.

Also read and undocumented: `user-invocable`, `disable-model-invocation`,
`when_to_use`, `paths`, `hooks`, `argument-hint`, `version`, and `shell`.

## Scoping allowed-tools

The auto-permit half is real: listed tools are usable without a permission
prompt while the skill is active, so an unused entry is not harmless padding —
it widens what the skill may do unasked. Drop anything the body never reaches
for. The docs also claim the list *restricts*, that Claude can use only those
tools while the skill runs; that half isn't visible anywhere in the binary, and
the same doc page was stale on three other points, so treat it as unconfirmed
rather than a guardrail to lean on.

Bash entries are prefix matches with a trailing wildcard, and both
`Bash(cmd *)` and `Bash(cmd:*)` work; the binary's own validation message calls
`:*` the legacy form. The catch is that matching is shell-operator aware, so no
rule ever authorizes a compound command: `Bash(just build)` does nothing for
`cd target/debug && just build`. A procedure written as `&&` chains or a `for`
loop therefore cannot be scoped at all, and the list ends up decorative while
still prompting on every step. Splitting it into one command per line makes the
scoping real, and tends to improve the skill anyway — the chaining is usually
there for a human who wanted one paste.

## Sources

- [Lessons from Building Claude Code: How We Use Skills](https://x.com/trq212/status/2033949937936085378) (Anthropic, 2026)
- Frontmatter and `allowed-tools` behavior read out of the Claude Code 2.1.276 binary (`strings` over the skill loader and the permission-rule matcher), which documents more fields than the published docs do
