---
name: jj
description: Use when needing jj command reference, syntax, or behavior - directs to jj --help for authoritative documentation and flags
---

# Jujutsu (jj) Version Control

Use `jj --help` for authoritative command reference and current flags.

## Core Workflow

1. Make file edits (changes exist in working copy)
2. `jj commit -m 'message'` (snapshot current changes, start new empty working copy)
3. Repeat

Use `jj describe` to rewrite a commit message, `jj new <rev>` to start
working on top of a revision.

## Key Differences from Git

No staging area: working copy changes map directly to commits. Operations
are immutable: `jj new`, `jj squash`, `jj rebase` create new commits rather
than modify existing ones. The operation log (`jj op log`) enables undo/recovery.

## Bookmarks and Pushing

Bookmarks are mutable named pointers to commits (like git branches).
Use `jj new <bookmark>` to start working on top of one.

```bash
jj bookmark list                           # show all bookmarks
jj bookmark set feature -r <rev>           # move bookmark to revision
jj bookmark track main --remote=origin     # start tracking a remote bookmark
```

### Advancing bookmarks after commit

`jj bookmark advance` moves the nearest ancestor bookmark(s) forward to a
target revision — the preferred way to move `main` after committing on top
of it.

```bash
jj bookmark advance                  # advance closest bookmarks to @ (default)
jj bookmark advance --to @-          # advance closest bookmarks to @-
jj bookmark advance main --to @-     # advance specific bookmark
```

After `jj commit`, the working copy `@` is empty so `jj bookmark advance`
with no args works — the bookmark is an ancestor of `@`.

### Pushing

```bash
jj git push -b <bookmark>                  # push tracked bookmark
jj git push -c <rev>                       # create auto-named bookmark and push
jj git push --named <name>=<rev>           # create named bookmark and push
```

`-b` refuses to push untracked bookmarks ("Refusing to create new remote
bookmark"). Use `--named` to create, push, and auto-track in one step.
`-c` generates a bookmark name from the change ID (`push-<short-change-id>`).

## Restoring Files

`jj restore` uses `--from` and `--into`/`--to`, not `-r`:

```bash
jj restore --changes-in @                  # undo all working copy changes
jj restore SOME_FILE                       # restore file from parent
jj restore --from kn --into kn FILE        # restore file in a specific revision
```

## Common Pitfalls

**Avoid revset functions with parentheses.** Claude Code's shell
command parser treats `()` as subshell syntax even when quoted, which
triggers permission prompts. Use the underlying value directly:

```bash
jj log -r main@origin                # correct — no parens
jj log -r 'trunk()'                  # WRONG — triggers permission prompt
```

`trunk()` usually resolves to `main@origin` but depends on the repo's
config. Check `jj config get revset-aliases."trunk()"` if unsure.
Prefer the resolved value (e.g., `main@origin`) everywhere.

**`jj show` does not accept path arguments.** It takes an optional revision
but cannot be scoped to a path. Use `jj diff` instead:

```bash
jj diff -r @-                        # all changes in parent revision
jj diff -r @- path/to/file           # specific file in parent revision
```

**Fileset expressions with special characters need quoting.** Use
`glob:"pattern"` with the pattern in double quotes:

```bash
jj diff -- 'glob:"bin/*" ~ glob:"bin/,special"'
```

**`jj op undo` has been removed (v0.39+).** Use `jj op revert` or
`jj undo`/`jj redo`.

**Put `-m` before `--` or fileset args.** jj parses everything after `--` as
fileset, so `-m` placed after `--` becomes a parse error.

## When to Use jj --help

Never rely on this skill as authoritative. Always run `jj <command> --help`
to verify behavior, flags, and current options.
