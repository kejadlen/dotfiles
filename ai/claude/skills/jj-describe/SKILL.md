---
name: describe
description: Use when the user asks to "describe a change", "describe a revision", "/describe", "rewrite commit message", or "update revision description"
argument-hint: <revision>
---

# Describe a Change

## Target Revision

`$ARGUMENTS`

**Important:** Completely discard the existing revision description. Start from scratch.

## Process

1. Run `jj show -r $ARGUMENTS` to view the changes
2. Invoke the `describing-changes` skill to draft a new description
3. Apply with `jj describe -r $ARGUMENTS -m '...'`
4. Verify with `jj show -r $ARGUMENTS`
