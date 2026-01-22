---
name: commit
description: This skill should be used when the user asks to "commit changes", "commit my work", "/commit", "create a commit", or "jj commit". Drafts clear, reasoning-focused commit messages using jj.
argument-hint: [fileset]
---

# Commit Changes

Draft clear, reasoning-focused commit messages using the `describing-changes` skill.
The `elements-of-style:writing-clearly-and-concisely` skill is required as a sub-skill for clarity.

## Fileset (optional)

`$ARGUMENTS`

## Process

1. Check if a fileset was provided: `$ARGUMENTS`
2. If a fileset is provided:
   - Run `jj diff $ARGUMENTS` to view the specific changes being committed
   - Invoke the `describing-changes` skill to draft the commit message based on these specific changes
3. If no fileset is provided (empty `$ARGUMENTS`):
   - Run `jj diff` to view all current changes
   - Invoke the `describing-changes` skill to draft the commit message explaining reasoning
4. The skill requires `elements-of-style:writing-clearly-and-concisely` for clarity
5. Audit the message: is every sentence invisible in the diff?
   - For each sentence, ask: "Does this explain something not visible in the code change?"
   - If the answer is "no" (sentence just restates what the diff shows), delete it
   - If all sentences pass the audit, proceed. If any fail, rewrite until they do.
6. If a fileset is provided, use `jj commit $ARGUMENTS` to commit only matching files (include the changelog in the fileset if it was updated)
7. If no fileset is provided (empty `$ARGUMENTS`), use `jj commit` to commit all changes
8. Include the "Assisted-by" footer with the current model and tool being used
9. Use a HEREDOC for the commit message to ensure proper formatting
10. Verify the commit with `jj show` to confirm only intended changes were committed
