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

## Fileset (optional)

`$ARGUMENTS`

## Process

1. Run `jj diff $ARGUMENTS` to view changes being committed
2. Invoke the `describing-changes` skill to draft the commit message
3. Check if a changelog exists (CHANGELOG.md, CHANGELOG, CHANGES.md, or similar)
   - If found, add an entry under the appropriate section
   - Scope the entry to only the changes in the fileset, if provided
4. Commit with `jj commit -m '...' $ARGUMENTS` (omit fileset args to commit all; include changelog in fileset if updated)
   - **Put `-m` before `--` or fileset args.** jj parses everything after `--` as fileset, so `-m` content placed after `--` becomes a parse error.
5. Verify with `jj show`
