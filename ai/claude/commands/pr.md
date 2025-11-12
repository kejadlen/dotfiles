# Create Pull Request

Create a pull request using gh for a bookmark that has already been
pushed.

Usage:
- `/pr` - Create a PR for the closest pushable bookmark
- `/pr <bookmark-name>` - Create a PR for the specified bookmark

When creating a pull request:
1. If no bookmark is provided, use `jj log -r 'max(bookmarks() &
   bookmarks(remote=origin))'` to find the closest pushable bookmark (a local
   bookmark that has been pushed to origin)
2. Run `jj log -r 'trunk()::bookmark-name'` to list all commits from trunk to
   the bookmark
3. Run `jj diff -r 'trunk()::bookmark-name' --stat` to review all changes
4. Check for .github PR templates and follow them
5. Generate a PR title summarizing all commits in the changeset (not just the
   most recent). The title reflects the overall change, not individual commits
6. Draft a PR summary explaining why the changes were made and their impact.
   Focus on context and motivation, not implementation details. Include only
   "Assisted-by" footer for attribution—no "Generated with Claude Code"
   - Do not repeat information obvious from the diff
   - Omit details like "added function X" or "modified file Y" unless
     non-obvious reasoning justifies them
   - Explain user-facing impact, architectural decisions, and tradeoffs
   - Follow repository conventions
7. Create the PR: `gh pr create --head <bookmark-name> --title "<title>"` using
   a HEREDOC to pass the body
8. Return the PR URL
