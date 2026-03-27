---
name: ranger
description: Use when managing tasks with the ranger CLI — creating backlogs, tracking work, picking up tasks, prioritizing, or following the ranger PM workflow in any project
---

# Ranger — Task Management

Use the `ranger` CLI to manage project tasks. Run `ranger --help` for commands and syntax.

All work must correspond to a task in the backlog. If the user asks for something that isn't tracked, create a task first, then pick it up. When the user says "let's keep working" without specifying a task, pick up the next queued task (top of the queue).

## Quick Reference

Commands use `ranger <noun> <verb>` structure. Top-level nouns: `backlog` (alias `b`), `task` (alias `t`), `comment` (alias `c`), `tag`, `blocker`.

```bash
# Backlogs
ranger backlog list                  # List all backlogs

# Tasks
ranger task create --backlog <name> "Title"   # Create a task
ranger task create --backlog <name> --state ready --description "..." "Title"
ranger task list --backlog <name>             # List tasks
ranger task show <key>                        # Show task details
ranger task edit <key> --state <state>        # Change task state
ranger task move <key> -B <other>             # Reorder: place before another task
ranger task move <key> -A <other>             # Reorder: place after another task
ranger task delete <key>                      # Delete a task
```

```bash
# Tags (created implicitly — no "tag create" command; adding a new name creates the tag)
ranger tag list                              # List all tags
ranger tag add <task-key> <tag-name>         # Add a tag to a task (creates tag if new)
ranger tag remove <task-key> <tag-name>      # Remove a tag from a task (alias: rm)
```

Task states for `--state`: `icebox`, `ready`, `in_progress`, `done`.

The `RANGER_DEFAULT_BACKLOG` env var sets the default `--backlog` value so you can omit it.

Task keys are short prefixes (e.g. `tl`) of longer IDs — use just enough to be unique. There is no `--top` or `--bottom` flag; to move to the top, use `-B` with the first task's key.

## Conventions

- **Icebox**: ideas, not committed to
- **Ready**: committed, ordered by priority (top = most important)
- **In Progress**: actively being worked on
- **Done**: finished

Top of the queue = most important. Bias toward quick wins — small easy tasks should be prioritized higher by default.

## Workflow

- Don't mark a task **done** until the changes are committed. Commit first, then transition.
- When you encounter a bug in ranger during other work, file it in the ranger backlog (`--backlog ranger`) and tag it `bug`. Include what you observed, the expected behavior, and how to reproduce it in the description. Don't fix it inline — continue with the original task unless the bug blocks it.

---

*This is a self-improving skill — see the `self-improving-skills` skill.*
