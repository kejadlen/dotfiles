---
name: commit
description: Use when the user asks to "commit changes", "commit my work", "/commit", "create a commit", "jj commit", "describe a change", "describe a revision", "/describe", "rewrite commit message", or "update revision description"
argument-hint: <revision or fileset>
allowed-tools: [Bash(jj diff *), Bash(jj show *), Bash(jj log *)]
---

# Commit or Describe Changes

## Mode Detection

`$ARGUMENTS`

Determine which mode to use:

- **Describe mode** — argument names an existing revision (e.g., `@-`,
  `abc123`, a bookmark name). Use when the user says "describe",
  "rewrite commit message", or "update revision description".
- **Commit mode** — argument is empty, a fileset, or the user says
  "commit". This is the default.

When ambiguous, ask.

## Describe Mode

Rewrite the description of an existing revision from scratch. Completely
discard the existing description.

1. Run `jj show -r $ARGUMENTS` to view the changes
2. Invoke the `describing-changes` skill to draft a new description
3. Apply with `jj describe -r $ARGUMENTS -m '...'`
4. Verify with `jj show -r $ARGUMENTS`

## Commit Mode

Execute directly without exploring the codebase first. When asked to
commit and create a PR, use this skill followed by the `/pr` skill
unless told otherwise.

**Prefer new commits over squashing.** Use `jj commit` to create a new
commit by default — even for refactors, cleanups, or small follow-ups.
Only squash (`jj squash`) when the prior commit specifically needs
fixing up (e.g., correcting a bug introduced in that commit, fixing a
typo in code it added). If in doubt, make a new commit.

### Fileset (optional)

`$ARGUMENTS`

### Process

1. Run `jj diff $ARGUMENTS` to view changes being committed
2. When a fileset is given, run `jj diff` (no args) to see all pending
   changes. Review the remaining files and mention any that look related
   to the fileset — e.g., a lockfile updated alongside a manifest, or a
   config change paired with the code that uses it. Ask the user whether
   to include them. Skip this step when no fileset is provided (all
   changes are already included).
3. **Adversarial review.** Before writing the commit message, re-read the
   diff as a skeptical reviewer trying to find reasons NOT to commit.
   Check for:
   - Bugs or logic errors introduced by the change
   - Incomplete work (TODOs, half-finished refactors, dead code left behind)
   - Unintended side effects or behavioral changes
   - Debug artifacts (print statements, hardcoded values, commented-out code)
   - Changes that don't belong together (should be separate commits)

   If you find issues, list them concisely and ask the user whether to
   proceed, fix first, or split the commit. If the diff is clean, say so
   in one line and move on — don't invent problems.
4. Invoke the `describing-changes` skill to draft the commit message
5. Check if a changelog exists (CHANGELOG.md, CHANGELOG, CHANGES.md, or similar)
   - If found, add an entry under the appropriate section
   - Scope the entry to only the changes in the fileset, if provided
6. Commit with `jj commit -m '...' $ARGUMENTS` (omit fileset args to commit all; include changelog in fileset if updated)
   - **Put `-m` before `--` or fileset args.** jj parses everything after `--` as fileset, so `-m` content placed after `--` becomes a parse error.
7. Verify with `jj show`
