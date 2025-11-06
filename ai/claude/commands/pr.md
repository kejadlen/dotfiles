# Create Pull Request

Create a pull request using gh for a bookmark that has already been
pushed.

Usage:
- `/pr <bookmark-name>` - Create a PR for the specified bookmark

When creating a pull request:
1. Run `jj log -r 'trunk()::<bookmark-name>'` to see all commits from
trunk to the bookmark
2. Run `jj diff -r 'trunk()::<bookmark-name>' --stat` to understand all
changes from trunk
3. Analyze all commits and changes that will be included in the pull
request
4. Check if there are any .github templates for pull requests and follow
them
5. Invoke the `writing` skill for assistance with PR description style
and conventions
6. Draft a pull request summary:
   - Focus on why the changes were made and their impact
   - CRITICAL: Do NOT repeat information that is obvious from the diff
     itself. Reviewers will read the diff. Your description should
     provide context, motivation, and implications that cannot be
     determined by examining the code changes alone
   - Avoid describing implementation details like "added function X",
     "modified file Y", or "changed variable Z" unless explaining
     non-obvious reasoning
   - Explain user-facing impact, architectural decisions, or tradeoffs
     that justify the approach taken
   - Follow repository conventions
   - Do NOT include duplicate attribution (e.g., both "Generated with
     Claude Code" and "Assisted-by" footer)
7. Create PR using `gh pr create --head <bookmark-name>` with the
summary. Use a HEREDOC to pass the body and include ONLY the
"Assisted-by" footer with the current model and tool being used
8. Return the PR URL when done
