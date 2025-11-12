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
