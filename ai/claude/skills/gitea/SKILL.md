---
name: gitea
description: Use when needing tea CLI command reference, syntax, or behavior - directs to tea --help for authoritative documentation and flags
---

# Gitea CLI (tea)

Use `tea --help` for authoritative command reference and current flags.

## Quick Start

Run `tea <command> --help` for detailed command documentation:

```bash
tea --help              # Full command list
tea issues --help       # Specific command details
tea pulls create --help # Syntax and options
```

tea auto-discovers the Gitea instance and repo from the current directory's git remote.

## Targeting Remote Repos

When not inside a clone of the target repo, specify the repo and login explicitly:

```bash
tea issues list -r owner/repo -l instance-name
tea issues create -r owner/repo -l instance-name -t "Title" -d "Body"
```

`-l` matches the NAME column from `tea logins list`. Use `-r owner/repo` (the slug, not a URL).
These flags are needed on **every command** when the cwd isn't a clone with a matching remote.

## Core Workflows

**Issues:**
```bash
tea issues                      # List open issues
tea issues <index>              # Show issue details
tea issues create -t "Title" -d "Description"  # Create (inline)
tea issues create               # Create (interactive)
tea issues edit <index>         # Edit an issue
tea issues edit <idx> [<idx>...] --add-labels "a,b"  # Bulk label
tea issues close <index>        # Close an issue
tea comment <index> "<body>"    # Comment on an issue or PR
```

**Pull requests:**
```bash
tea pulls                       # List open PRs
tea pulls <index>               # Show PR details
tea pulls create                # Create a PR
tea pulls checkout <index>      # Check out a PR locally
tea pulls merge <index>         # Merge a PR
tea pulls approve <index>       # Approve a PR
tea pulls reject <index>        # Request changes
tea pulls review <index>        # Interactive review
```

**Labels & milestones:**
```bash
tea labels list                 # List labels
tea labels create --name "bug" --color "e11d48" --description "Bug reports"
tea milestones list             # List milestones
tea milestones create           # Create a milestone
```

**Repositories:**
```bash
tea repos                       # Show current repo details
tea repos list                  # List your repos
tea repos search <query>        # Search repos on the instance
tea repos create                # Create a repo
tea repos fork                  # Fork a repo
```

**Releases:**
```bash
tea releases list               # List releases
tea releases create             # Create a release
```

## Common Patterns

### Batch issue creation with labels

Create labels first, then apply on create or after:

```bash
# 1. Create labels
tea labels create -r o/r -l inst --name "security" --color "e11d48"
tea labels create -r o/r -l inst --name "component" --color "0075ca"

# 2a. Create issues with labels inline
tea issues create -r o/r -l inst -t "Title" -d "Body" -L "security,component"

# 2b. Or add labels to existing issues (supports multiple indices)
tea issues edit -r o/r -l inst --add-labels "security,component" 1 2 3
```

### Bulk labeling in a loop

```bash
for i in 1 2 3 4 5; do
  tea issues edit -r o/r -l inst --add-labels "label1,label2" "$i"
done
```

### Issue descriptions with markdown

Pass multiline markdown via `-d` with shell quoting:

```bash
tea issues create -r o/r -l inst \
  -t '[CRITICAL] Issue title' \
  -d '## Summary

Description with **markdown** and code:

```typescript
const x = 1;
```

## Impact

Bullet points:
- First
- Second'
```

## Gotchas

- **No project board support:** tea cannot add issues to Gitea project boards. Use the web UI or Gitea API directly.
- **Labels flag differs between create and edit:** `issues create` uses `-L`/`--labels`, while `issues edit` uses `--add-labels`/`--remove-labels`.
- **`-l` is `--login`, not `--labels`:** The `-L` (uppercase) shorthand is for labels. Mixing these up silently targets the wrong Gitea instance.

## Command Categories

Run `tea --help` to see all commands. Main categories:

Issues: issues list/create/edit/close/reopen
Pull Requests: pulls list/create/checkout/close/merge/approve/reject/review/clean
Comments: comment (on issues or PRs)
Repos: repos list/search/create/fork/migrate/delete
Labels: labels list/create/update/delete
Milestones: milestones list/create
Releases: releases list/create/edit/delete, releases assets
Times: times (tracked time on issues/PRs)
Organizations: organizations list/create/delete
Helpers: open (open in browser), notifications, clone
Setup: logins, logout, whoami

## Output Formats

All listing commands support `--output` / `-o`:

```bash
tea issues --output json        # JSON output (useful for scripting)
tea issues --output yaml        # YAML output
tea issues --output csv         # CSV output
tea issues --output table       # Table output
```

## Filtering

Issues and PRs support filtering:

```bash
tea issues --state closed           # By state (open/closed/all)
tea issues --labels "bug,urgent"    # By labels
tea issues --milestones "v1.0"      # By milestone
tea issues --assignee "username"    # By assignee
tea issues --keyword "search term"  # By keyword search
```

## When to Use tea --help

Direct command help is always more current than documentation. Use it for:

- Exact flag names and syntax
- Current command options
- Command behavior details
- Examples and edge cases

Never rely on this skill's command list as authoritative. Always run `tea <command> --help` to verify behavior, flags, and current options.
