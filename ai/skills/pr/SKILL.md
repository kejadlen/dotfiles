---
name: pr
description: Use when the user asks to "create a pull request", "create a PR", "/pr", "open a PR", "submit for review", or "push and create PR"
argument-hint: <revision> [ready|web]
allowed-tools: [Bash(jj diff *), Bash(jj log *), Bash(jj show *), Bash(jj bookmark list *)]
---

# Create Pull Request

Create a pull request using gh for a specified revision.

## Arguments

`$ARGUMENTS`

Parse arguments: first word is the revision, second word is optional:
- `ready`: creates a ready-for-review PR instead of draft
- `web`: opens a prepopulated PR in the browser for manual editing instead of creating it directly

Revision must be provided (bookmark, change ID, revset, or commit hash). The revision will be resolved to a bookmark for the PR.

## Process

1. Gather context for the PR:
   - Run `jj log -r '<revision>' --no-graph` to check for existing bookmarks
   - Run `jj log -r 'main@origin..<revision>'` to list commits between trunk and the revision
   - Run `jj diff --from main@origin --to <revision> --stat` to review all changes
2. Push revision and get bookmark name:
   - If revision has a remote-tracked bookmark: `jj git push --bookmark <name>`
   - If revision has a local-only bookmark (no `@origin`): push with
     `jj git push --named <name>=<revision>` (pushes and auto-tracks)
   - If revision has no bookmark:
     1. Using all available context — the current session (what was discussed
        and why), the full set of commits from trunk to the revision, and the
        diff — generate a short kebab-case bookmark name that summarizes the
        overall PR purpose:
        - Prefix with `alpha/` (e.g., `alpha/fix-widget-layout`)
        - Lowercase, words joined by hyphens
        - Max ~50 chars (excluding prefix), truncate at a word boundary
        - Only alphanumeric and hyphens; no leading/trailing/double hyphens
     2. If a good name was generated, check `jj bookmark list` to ensure it's
        not taken (append `-2` etc. if it is), then push with
        `jj git push --named <generated-name>=<revision>`
     3. If there isn't enough context to produce a meaningful name,
        fall back to `jj git push -c <revision>`
   - Retrieve the bookmark name from the output
3. Consider whether the pending changes should be organized into smaller, easier
   to review commits. If so, use `jj split` or `jj squash` to reorganize before
   proceeding.
4. Check for .github PR templates and follow them. For checklist items that do
   not apply, use strikethrough: `- ~~Irrelevant item~~`
5. **Invoke the `technical-writing` skill** before drafting any prose. This is
   mandatory.
6. **Search episodic memory** with `episodic-memory:search` for conversations
   touching the changed files. Look for a rejected alternative or a constraint
   that shaped the solution — something a reviewer would otherwise ask about.
   Not a section to fill in; at most one more sentence in the summary, and
   usually nothing.
7. Generate a PR title summarizing all commits in the changeset (not just the
   most recent). The title reflects the overall change, not individual commits.
8. Draft the PR summary: three to five sentences of prose covering why the
   change was made and its impact. No headers or bullet lists unless a
   repository template requires them. Include only an "Assisted-by" footer for
   attribution, no "Generated with Claude Code".
   - Lead with user-facing impact and the tradeoff a reviewer would question.
   - Say nothing a reader gets from the diff or the file list. No "added
     function X" or "modified file Y".
   - Link related context found in the session — "Depends on #123", "Closes
     #456", a Slack permalink.
   - Never wrap commit SHAs or PR/issue numbers in backticks—GitHub
     auto-links raw `a1b2c3d` and `#123` but backticks prevent it
   - Do not hard-wrap prose with manual newlines; GitHub wraps Markdown
     itself, so they render as awkward mid-sentence breaks
   - Delete pass before creating the PR: cut every sentence that summarizes
     the diff, restates the title, or exists to look thorough.
9. **Code review**: Dispatch the `superpowers:code-reviewer` subagent to review
    the changes. Tell the reviewer to run
    `jj diff --git --from main@origin --to <revision>` to get the actual commit
    diff—do not let it grep or read the working directory, which may be on a
    different revision. Pass `--git` so the reviewer gets a standard unified diff
    with `@@` hunk headers; the default color-words format prints two
    line-number columns (old, then new) and shows `..` in the old column for
    added lines, which subagents misread when anchoring `file:line`. Provide a
    brief description of what was implemented. Address Critical and Important
    issues before proceeding; Minor issues can be noted for later.
10. Create the PR: `gh pr create --head <bookmark-name> --title "<title>"` using
    a HEREDOC to pass the body.
    - If `web` was specified: add `--web` flag (without `--draft` — they're
      incompatible) to open prepopulated PR in browser for manual editing,
      then stop (skip remaining steps)
    - If `ready` was specified: create directly without `--draft`
    - Otherwise: add `--draft` flag
11. **If a Jira card is detected**, transition it to "In Review":
    - Check workspace name or bookmark for pattern like `PROJ-123` (e.g., `LDE-488`)
    - If found: `acli jira workitem transition --key <KEY> --status "In Review"`
    - If not found, skip this step silently
12. Return the PR URL
