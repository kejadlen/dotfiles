# Create Pull Request

Create a pull request using gh for a specified revision.

Usage:
- `/pr <revision>` - Create a draft PR for the specified revision
- `/pr <revision> ready` - Create a ready-for-review PR

Revision must be provided (bookmark, change ID, revset, or commit hash). The revision will be resolved to a bookmark for the PR.

When creating a pull request:
1. Push revision and get bookmark name:
   - If revision has a remote-tracked bookmark: `jj git push --bookmark <name>`
   - If revision has a local-only bookmark: track then push:
     `jj bookmark track <name>@origin && jj git push --bookmark <name>`
   - If revision has no bookmark: `jj git push -c <revision>` (creates and pushes)
   - Retrieve the bookmark name from the output
2. Run `jj log -r 'trunk()..<bookmark>'` to list commits between trunk and the bookmark
3. Run `jj diff --from trunk() --to <bookmark> --stat` to review all changes in the PR
4. Check for .github PR templates and follow them
5. **Invoke the `elements-of-style:writing-clearly-and-concisely` skill** before
   drafting any prose. This is mandatory.
6. Generate a PR title summarizing all commits in the changeset (not just the
   most recent). The title reflects the overall change, not individual commits.
7. Draft a PR summary explaining why the changes were made and their impact.
   Focus on context and motivation, not implementation details. Include only
   "Assisted-by" footer for attribution—no "Generated with Claude Code"
   - Do not repeat information obvious from the diff
   - Omit details like "added function X" or "modified file Y" unless
     non-obvious reasoning justifies them
   - Explain user-facing impact, architectural decisions, and tradeoffs
   - Follow repository conventions
8. Create the PR: `gh pr create --head <bookmark-name> --title "<title>"` using
   a HEREDOC to pass the body. Add `--draft` unless `ready` was specified.
9. **If a Jira card is detected**, transition it to "In Review":
   - Check workspace name or bookmark for pattern like `PROJ-123` (e.g., `LDE-488`)
   - If found: `acli jira workitem transition --key <KEY> --status "In Review"`
   - If not found, skip this step silently
10. Return the PR URL
