# Commit Changes

Commit changes using jj. Arguments can specify a fileset to include in
the commit.

Usage:
- `/commit` - Commit all current changes
- `/commit <fileset>` - Commit only files matching the fileset
  expression

When committing:
1. Check if a fileset was provided as arguments
2. If a fileset is provided, use `jj commit <fileset>` to commit only
matching files
3. If no fileset is provided, use `jj commit` to commit all changes
4. Draft a clear, concise commit message:
   - Focus on why the change was made, not what changed (the diff shows
     what changed)
   - Omit information that is obvious from the diff itself
   - Follow repository conventions
5. Include the "Assisted-by" footer with the current model and tool
being used
6. Use a HEREDOC for the commit message to ensure proper formatting
7. Run `jj log` after committing to verify success
