# Create Pull Request

Create a pull request using gh for a specified revision.

Usage:
- `/pr <revision>` - Create a draft PR for the specified revision
- `/pr <revision> ready` - Create a ready-for-review PR

Revision must be provided (bookmark, change ID, revset, or commit hash). The revision will be resolved to a bookmark for the PR.

When creating a pull request:
1. Resolve revision to bookmark name:
   - If revision is already a bookmark or has a bookmark, use the bookmark directly
   - If revision is a revset/change ID/commit hash and you have context for what to name it, create a descriptive bookmark, track it, and push:
     `jj bookmark create <descriptive-name> -r <revision>`
     `jj bookmark track <descriptive-name>@origin`
   - If revision is a revset/change ID/commit hash but you lack naming context, push with auto-generated name:
     `jj git push -c <revision>`
     Then retrieve the auto-generated bookmark name from the push output
2. Run `jj log -r 'trunk()..<bookmark>'` to list commits between trunk and the bookmark
3. Run `jj diff --from trunk() --to <bookmark> --stat` to review all changes in the PR
4. Check for .github PR templates and follow them
5. Use the writing skill to generate a PR title summarizing all commits in the
   changeset (not just the most recent). The title reflects the overall change,
   not individual commits. Apply Strunk's principles for clarity and concision.
6. Use the writing skill to draft a PR summary explaining why the changes were
   made and their impact. Focus on context and motivation, not implementation
   details. Include only "Assisted-by" footer for attribution—no "Generated
   with Claude Code"
   - Do not repeat information obvious from the diff
   - Omit details like "added function X" or "modified file Y" unless
     non-obvious reasoning justifies them
   - Explain user-facing impact, architectural decisions, and tradeoffs
   - Follow repository conventions
   - Apply elements-of-style rules: active voice, positive form, definite
     language, omit needless words, keep related words together
7. Create the PR: `gh pr create --head <bookmark-name> --title "<title>"` using
   a HEREDOC to pass the body. Add `--draft` unless `ready` was specified.
8. Return the PR URL
