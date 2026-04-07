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
6. **Search episodic memory for design decisions**: Use `episodic-memory:search`
   to find conversations related to the files changed in this PR. Look for:
   - Design decisions and their rationale
   - Alternative approaches that were considered and rejected
   - Tradeoffs discussed during implementation
   - Requirements or constraints that shaped the solution
   Extract key decisions to include in the PR summary's "Design Decisions" section.
7. Generate a PR title summarizing all commits in the changeset (not just the
   most recent). The title reflects the overall change, not individual commits.
8. Draft a PR summary explaining why the changes were made and their impact.
   Focus on context and motivation, not implementation details. Include only
   "Assisted-by" footer for attribution—no "Generated with Claude Code"
   - Do not repeat information obvious from the diff
   - Omit details like "added function X" or "modified file Y" unless
     non-obvious reasoning justifies them
   - Explain user-facing impact, architectural decisions, and tradeoffs
   - If design decisions were found in episodic memory, include a "Design Decisions"
     section highlighting key choices and their rationale
   - If the session references a blocking PR, linked issue, Slack thread,
     or other related context, include it in the description automatically
     (e.g., "Depends on #123", "Closes #456", or a Slack permalink)
   - Never wrap commit SHAs or PR/issue numbers in backticks—GitHub
     auto-links raw `a1b2c3d` and `#123` but backticks prevent it
   - Do not insert manual newlines to wrap prose; GitHub renders Markdown
     and hard-wraps automatically, so added line breaks show up as awkward
     breaks in the rendered description
   - Follow repository conventions
9. **Code review**: Dispatch the `superpowers:code-reviewer` subagent to review
    the changes. Tell the reviewer to run
    `jj diff --from main@origin --to <revision>` to get the actual commit diff—do
    not let it grep or read the working directory, which may be on a different
    revision. Provide a brief description of what was implemented. Address
    Critical and Important issues before proceeding; Minor issues can be noted
    for later.
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
