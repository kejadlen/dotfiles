---
name: describe
description: This skill should be used when the user asks to "describe a change", "describe a revision", "/describe", "rewrite commit message", or "update revision description". Drafts reasoning-focused descriptions for jj revisions.
argument-hint: <revision>
---

# Describe a Change

Draft a reasoning-focused description for a jj revision using the `describing-changes` skill.
The `elements-of-style:writing-clearly-and-concisely` skill is required as a sub-skill for clarity.

## Target Revision

`$ARGUMENTS`

**Important:** Completely discard the existing revision description. This command rewrites it entirely.

## Process

1. View the target revision with `jj show -r $ARGUMENTS` to understand the changes
2. Invoke the `describing-changes` skill to draft a new description explaining reasoning
   - Do NOT reference or build on the existing message
   - Start from scratch explaining why this change exists
   - The skill requires `elements-of-style:writing-clearly-and-concisely` for clarity
3. Use `jj describe -r $ARGUMENTS` with the drafted message, including the "Assisted-by" footer
4. Use a HEREDOC for the description to ensure proper formatting
5. Verify with `jj show -r $ARGUMENTS` to confirm the message was updated
