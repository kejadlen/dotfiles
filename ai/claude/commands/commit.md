# Commit Changes

Invoke the `committing-with-discipline` skill before committing. This
command helps you create commits with proper context, verification, and
discipline.

Usage:
- `/commit` - Commit all current changes
- `/commit <fileset>` - Commit only files matching the fileset expression

Before committing:
1. Use the `committing-with-discipline` skill to ensure proper discipline
2. Check if a fileset was provided as arguments
3. If a fileset is provided, use `jj commit <fileset>` to commit only
matching files
4. If no fileset is provided, use `jj commit` to commit all changes
5. Include the "Assisted-by" footer with the current model and tool being used
6. Use a HEREDOC for the commit message to ensure proper formatting
