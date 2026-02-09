---
name: gh-pr
description: Use when the user asks to "create a pull request", "create a PR", "/pr", "open a PR", "submit for review", or "push and create PR"
argument-hint: <revision> [ready|web]
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

1. Push revision and get bookmark name:
   - If revision has a remote-tracked bookmark: `jj git push --bookmark <name>`
   - If revision has a local-only bookmark: track then push:
     `jj bookmark track <name>@origin && jj git push --bookmark <name>`
   - If revision has no bookmark: `jj git push -c <revision>` (creates and pushes)
   - Retrieve the bookmark name from the output
2. Run `jj log -r 'trunk()..<bookmark>'` to list commits between trunk and the bookmark
3. Run `jj diff --from trunk() --to <bookmark> --stat` to review all changes in the PR
4. Consider whether the pending changes should be organized into smaller, easier
   to review commits. If so, use `jj split` or `jj squash` to reorganize before
   proceeding.
5. Check for .github PR templates and follow them. For checklist items that do
   not apply, use strikethrough: `- ~~Irrelevant item~~`
6. **Invoke the `elements-of-style:writing-clearly-and-concisely` skill** before
   drafting any prose. This is mandatory.
7. **Search episodic memory for design decisions**: Use `episodic-memory:search`
   to find conversations related to the files changed in this PR. Look for:
   - Design decisions and their rationale
   - Alternative approaches that were considered and rejected
   - Tradeoffs discussed during implementation
   - Requirements or constraints that shaped the solution
   Extract key decisions to include in the PR summary's "Design Decisions" section.
8. Generate a PR title summarizing all commits in the changeset (not just the
   most recent). The title reflects the overall change, not individual commits.
9. Draft a PR summary explaining why the changes were made and their impact.
   Focus on context and motivation, not implementation details. Include only
   "Assisted-by" footer for attribution—no "Generated with Claude Code"
   - Do not repeat information obvious from the diff
   - Omit details like "added function X" or "modified file Y" unless
     non-obvious reasoning justifies them
   - Explain user-facing impact, architectural decisions, and tradeoffs
   - If design decisions were found in episodic memory, include a "Design Decisions"
     section highlighting key choices and their rationale
   - Never wrap commit SHAs or PR/issue numbers in backticks—GitHub
     auto-links raw `a1b2c3d` and `#123` but backticks prevent it
   - Follow repository conventions
10. **Code review**: Dispatch the `superpowers:code-reviewer` subagent to review
    the changes. Use `trunk()` as base and `<bookmark>` as head. Provide a brief
    description of what was implemented. Address Critical and Important issues
    before proceeding; Minor issues can be noted for later.
11. Create the PR: `gh pr create --head <bookmark-name> --title "<title>"` using
    a HEREDOC to pass the body.
    - If `web` was specified: add `--web` flag to open prepopulated PR in browser for manual editing, then stop (skip remaining steps)
    - If `ready` was specified: create directly without `--draft`
    - Otherwise: add `--draft` flag
12. **If a Jira card is detected**, transition it to "In Review":
    - Check workspace name or bookmark for pattern like `PROJ-123` (e.g., `LDE-488`)
    - If found: `acli jira workitem transition --key <KEY> --status "In Review"`
    - If not found, skip this step silently
13. Return the PR URL
