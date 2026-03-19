---
name: skill-notes
description: Use when creating a new SKILL.md file, reviewing an existing skill for quality, or when the user asks about skill authoring conventions
---

# Skill Notes

Supplementary notes on writing effective skills, accumulated from experience and external sources.

*This is a self-improving skill — see the `self-improving-skills` skill.*

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

## Sources

- [Lessons from Building Claude Code: How We Use Skills](https://x.com/trq212/status/2033949937936085378) (Anthropic, 2026)
