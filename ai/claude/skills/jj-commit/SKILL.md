---
name: jj-commit
description: Use when the user asks to "commit changes", "commit my work", "/commit", "create a commit", or "jj commit"
argument-hint: <fileset>
allowed-tools: Bash(jj diff:*) Bash(jj show:*) Bash(jj log:*)
---

# Commit Changes

## Fileset (optional)

`$ARGUMENTS`

## Process

1. Run `jj diff $ARGUMENTS` to view changes being committed
2. Invoke the `describing-changes` skill to draft the commit message
3. Check if a changelog exists (CHANGELOG.md, CHANGELOG, CHANGES.md, or similar)
   - If found, add an entry under the appropriate section
   - Scope the entry to only the changes in the fileset, if provided
4. Commit with `jj commit $ARGUMENTS -m '...'` (omit fileset args to commit all; include changelog in fileset if updated)
5. Verify with `jj show`
