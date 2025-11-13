# Commit Changes

Use the `describing-changes` skill to draft clear, reasoning-focused commit messages.
The `elements-of-style` writing skill is required as a sub-skill for clarity.

Usage:
- `/commit` - Commit all current changes
- `/commit <fileset>` - Commit only files matching the fileset expression

Before committing:
1. Use the `describing-changes` skill to draft the commit message explaining reasoning
   - The skill requires `elements-of-style:writing-clearly-and-concisely` for clarity
2. Check if a fileset was provided as arguments
3. If a fileset is provided, use `jj commit <fileset>` to commit only matching files
4. If no fileset is provided, use `jj commit` to commit all changes
5. Include the "Assisted-by" footer with the current model and tool being used
6. Use a HEREDOC for the commit message to ensure proper formatting
7. Verify the commit with `jj show` to confirm only intended changes were committed
