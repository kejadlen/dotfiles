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
4. Use any available writing skills for assistance with commit message style
and conventions (e.g., elements-of-style)
5. Draft a clear, concise commit message:
   - Start with a single sentence that captures the change's purpose
   - Focus on why the change was made, not what changed (the diff shows
     what changed)
   - CRITICAL: Do NOT include information that is obvious from reading
     the diff. The reviewer has the diff; your message should provide
     context and reasoning that cannot be inferred from the code changes
     alone
   - Only use a bulleted list if multiple distinct reasons or changes
     require explanation; otherwise keep the message to one paragraph
   - Avoid describing file changes, added/removed lines, or renamed
     variables unless the reason for these changes is non-obvious
   - Follow repository conventions
6. Include the "Assisted-by" footer with the current model and tool
being used
7. Use a HEREDOC for the commit message to ensure proper formatting
8. Run `jj log` after committing to verify success
