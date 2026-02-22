---
name: commit
description: Use when the user asks to "commit changes", "commit my work", "/commit", "create a commit", or "jj commit"
argument-hint: <fileset>
allowed-tools: Bash(jj diff:*) Bash(jj show:*) Bash(jj log:*)
---

# Commit Changes

## Workflow

Execute directly without exploring the codebase first. When asked to
commit and create a PR, use this skill followed by the `/pr` skill
unless told otherwise.

**Prefer new commits over squashing.** Use `jj commit` to create a new
commit by default — even for refactors, cleanups, or small follow-ups.
Only squash (`jj squash`) when the prior commit specifically needs
fixing up (e.g., correcting a bug introduced in that commit, fixing a
typo in code it added). If in doubt, make a new commit.

## Fileset (optional)

`$ARGUMENTS`

## Process

1. Run `jj diff $ARGUMENTS` to view changes being committed
2. When a fileset is given, run `jj diff` (no args) to see all pending
   changes. Review the remaining files and mention any that look related
   to the fileset — e.g., a lockfile updated alongside a manifest, or a
   config change paired with the code that uses it. Ask the user whether
   to include them. Skip this step when no fileset is provided (all
   changes are already included).
3. Invoke the `describing-changes` skill to draft the commit message
4. Check if a changelog exists (CHANGELOG.md, CHANGELOG, CHANGES.md, or similar)
   - If found, add an entry under the appropriate section
   - Scope the entry to only the changes in the fileset, if provided
5. Commit with `jj commit -m '...' $ARGUMENTS` (omit fileset args to commit all; include changelog in fileset if updated)
   - **Put `-m` before `--` or fileset args.** jj parses everything after `--` as fileset, so `-m` content placed after `--` becomes a parse error.
6. Verify with `jj show`
