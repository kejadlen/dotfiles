# Create Pull Request

Create a pull request using gh for a bookmark that has already been
pushed.

Usage:
- `/pr <bookmark-name>` - Create a PR for the specified bookmark

When creating a pull request:
1. Run `jj log -r <bookmark-name>::@` to see all commits that will be
merged (from the bookmark to the current working copy)
2. Run `jj diff -r <bookmark-name>::@` to understand all changes that
will be included
3. Analyze all commits and changes that will be included in the pull
request
4. Draft a pull request summary:
   - Focus on why the changes were made and their impact
   - Do NOT repeat information that is obvious from the diff itself
   - The diff shows what changed; the PR description should explain why
     and what the implications are
   - Follow repository conventions
5. Check if there are any .github templates for pull requests and follow
them
6. Create PR using `gh pr create --head <bookmark-name>` with the
summary. Use a HEREDOC to pass the body and include an "Assisted-by"
footer with the current model and tool being used
7. Return the PR URL when done
