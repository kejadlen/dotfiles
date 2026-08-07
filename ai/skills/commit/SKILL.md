---
name: commit
description: Use when the user asks to "commit changes", "commit my work", "/commit", "create a commit", "jj commit", "describe a change", "describe a revision", "/describe", "rewrite commit message", or "update revision description"
argument-hint: <revision, fileset, or instructions>
allowed-tools: [Bash(jj diff *), Bash(jj show *), Bash(jj log *)]
---

# Commit or Describe Changes

## Mode Detection

Argument (empty if none was passed): `$ARGUMENTS`

Classify the argument before using it anywhere. It is one of three
things:

- A revision — `@-`, `abc123`, a bookmark name. Use describe mode.
- A fileset — one or more paths. Use commit mode, scoped to those paths.
- Instructions — prose saying what to commit, which paths to leave
  alone, or how to split the work. Use commit mode, follow what it says,
  and work out the fileset yourself.

Commit mode is the default, including when the argument is empty.

Only a revision or a fileset is ever safe to substitute into a command.
Instructions are for you to read: pasted after `jj diff` or `jj commit
-m '...'`, a sentence gets parsed as paths and the command fails on the
first word that isn't one. Below, `<revision>` and `<fileset>` mean the
value you resolved here, not the raw argument.

When ambiguous, ask.

## Describe Mode

Rewrite the revision's description from scratch, discarding the existing one.

1. Run `jj show -r <revision>` to view the changes
2. Invoke the `describing-changes` skill to draft a new description
3. Apply with `jj describe -r <revision> -m '...'`
4. Verify with `jj show -r <revision>`

## Commit Mode

Execute directly without exploring the codebase first. When asked to
commit and create a PR, use this skill followed by the `/pr` skill
unless told otherwise.

**Prefer new commits over squashing.** Default to `jj commit`, even for
refactors and small follow-ups. Only `jj squash` when the prior commit
itself needs fixing — a bug or typo in code it introduced, or a revision
of prose or guidance it just wrote.

When squashing, pass a fileset: `jj squash --into @- <paths>`. A bare
`jj squash` moves *every* pending change into the parent, including
files another agent or a hook left in the working copy.

### Fileset (optional)

An empty `<fileset>` commits all pending changes.

A path containing a fileset metacharacter (`,` `~` `|` `&` `()`) parses
as syntax and fails; wrap it in a double-quoted string literal, e.g.
`'"bin/,z"'`. See the `jj` skill for the full fileset quoting rules.

### Process

1. Run `jj diff <fileset>` to view changes being committed
2. Confirm the commit's scope before writing it.
   - When a fileset is given, run `jj diff` (no args) to see all pending
     changes. Review the remaining files and mention any that look
     related to the fileset — e.g., a lockfile updated alongside a
     manifest, or a config change paired with the code that uses it. Ask
     the user whether to include them.
   - When no fileset is given, `jj commit` sweeps in *every* pending
     change with no further prompt. Before committing, check that each
     changed file belongs to the work you intend to commit. Watch for
     files you didn't touch this session (edited by the user, a linter,
     or a hook between turns) and for changes that are a separate logical
     unit. Split those out — commit the intended files by passing them as
     a fileset, or `jj split` after the fact — rather than letting an
     unrelated edit ride along.
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
6. Commit with `jj commit -m '...' <fileset>` (include changelog in the fileset if you updated it)
   - **Put `-m` before `--` or fileset args.** jj parses everything after `--` as fileset, so `-m` content placed after `--` becomes a parse error.
7. Verify with `jj show`
