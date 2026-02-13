---
name: jj
description: Use when needing jj command reference, syntax, or behavior - directs to jj --help for authoritative documentation and flags
---

# Jujutsu (jj) Version Control

Use `jj --help` for authoritative command reference and current flags.

## Quick Start

Run `jj <command> --help` for detailed command documentation:

```bash
jj --help           # Full command list
jj status --help    # Specific command details
jj log --help       # Syntax and options
```

## Core Workflow

1. Make file edits (changes exist in working copy)
2. `jj describe <message>` (write commit message)
3. `jj new` (create next commit, working copy becomes immutable)
4. Repeat

## Key Differences from Git

No staging area: working copy changes map directly to commits. Operations are immutable: `jj new`, `jj squash`, `jj rebase` create new commits rather than modify existing ones. Conflicts are queryable through `jj status` and `jj log`. The operation log (`jj op log`) shows all operations for undo/recovery.

## Bookmarks (Named References)

In jj, **bookmarks** are named references to commits, similar to git branches. Create and manage them:

```bash
jj bookmark create feature-auth -r main    # Create bookmark from main
jj bookmark list                           # Show all bookmarks
jj bookmark list -r feature-auth           # Show specific bookmark
jj bookmark delete feature-auth            # Delete bookmark
jj checkout feature-auth                   # Switch to bookmark
jj bookmark set feature-auth -r <rev>      # Move bookmark to different commit
```

**Key differences from git branches:**
- Bookmarks are immutable references (can't be modified in place)
- Multiple bookmarks can point to same commit
- `jj checkout` switches working copy to bookmark; use `jj new` to create commits on that bookmark

**Use bookmarks for:** Feature branches, parallel work, named release points. NOT for temporary work (use detached state instead).

## Pushing to Remote

```bash
# Push existing tracked bookmarks
jj git push -b <bookmark-name>

# Create and push new bookmark in one step (preferred)
jj git push --named <bookmark-name>=<revision>

# Push all bookmarks including new ones
jj git push --all
```

**Note:** `--named` creates the bookmark, pushes it, and auto-tracks it. Use this for PRs.

## Common Pitfalls

**Quote revsets containing parentheses.** Bash interprets `()` as subshell
syntax. Always quote revsets like `trunk()`:

```bash
jj log -r 'trunk()'                  # correct
jj diff --from 'trunk()' --to @      # correct
jj log -r trunk()                    # WRONG — bash syntax error
```

**`jj show` does not accept path arguments.** Unlike `git show`, you cannot
write `jj show @- -- path/to/file`. Use `jj diff` instead:

```bash
jj diff -r @-                        # all changes in parent revision
jj diff -r @- path/to/file           # specific file in parent revision
jj diff --from @-- --to @- some/dir  # between two revisions, scoped to path
```

**Path filtering uses positional fileset args, not revset syntax.** To find
revisions that touched a path, pass the path as a positional argument:

```bash
jj log ai/src/main.rs                # revisions touching this file
jj log -r '::@' ai/src/              # scoped to ancestors of @
```

## Command Categories

Run `jj --help` to see all commands. Main categories:

Repository: init, clone, status
Changes: new, describe, commit, edit
History: log, show, diff
Modification: squash, split, rebase
Bookmarks: bookmark create/list/delete
Sync: git fetch, git push
Conflict: resolve
Recovery: undo, op log, op undo

## When to Use jj --help

Direct command help is always more current than documentation. Use it for:

- Exact flag names and syntax
- Current command options
- Command behavior details
- Examples and edge cases

Never rely on this skill's command list as authoritative. Always run `jj <command> --help` to verify behavior, flags, and current options.
