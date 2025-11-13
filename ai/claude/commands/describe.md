# Describe a Change

Use the `describing-changes` skill to draft a reasoning-focused description for a jj revision.
The `elements-of-style` writing skill is required as a sub-skill for clarity.

Usage:
- `/describe <revision>` - Describe a specific revision (e.g., `-1`, `@-`, `r`, or commit ID)

Revision argument is required.

**Important:** Completely discard the existing revision description. This command rewrites it entirely.

Process:
1. View the target revision with `jj show -r <revision>` to understand the changes
2. Use the `describing-changes` skill to draft a new description explaining reasoning
   - Do NOT reference or build on the existing message
   - Start from scratch explaining why this change exists
   - The skill requires `elements-of-style:writing-clearly-and-concisely` for clarity
3. Use `jj describe -r <revision>` with the drafted message, including the "Assisted-by" footer
4. Use a HEREDOC for the description to ensure proper formatting
5. Verify with `jj show -r <revision>` to confirm the message was updated
