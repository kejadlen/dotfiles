# Resolve conflicts skill implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a procedural skill that resolves jj conflicts through
mergiraf automation and manual file-by-file resolution.

**Architecture:** Single SKILL.md file with frontmatter metadata and a
step-by-step workflow body. The skill lives in two mirrored locations
(`ai/skills/` and `ai/claude/skills/`).

**Tech Stack:** Markdown skill file, jj CLI

---

## File structure

- Create: `ai/skills/resolve-conflicts/SKILL.md` (source of truth)
- Create: `ai/claude/skills/resolve-conflicts/SKILL.md` (Claude Code copy)

Both files have identical content.

---

### Task 1: Write the skill file

**Files:**
- Create: `ai/skills/resolve-conflicts/SKILL.md`

- [ ] **Step 1: Write the frontmatter**

```yaml
---
name: resolve-conflicts
description: Use when resolving jj conflicts after rebase, squash, or merge — handles conflict markers, mergiraf automation, and file-by-file manual resolution
argument-hint: [change-id]
allowed-tools: [Bash(jj new *), Bash(jj status *), Bash(jj resolve *), Bash(jj diff *), Bash(jj log *)]
---
```

- [ ] **Step 2: Write the skill body**

The body follows the procedural skill pattern (numbered steps) used by
the `commit` skill. Structure:

1. Heading: `# Resolve Conflicts`
2. `$ARGUMENTS` reference for mode detection
3. Step 1 — set up the resolution change:
   - With argument: `jj new $ARGUMENTS`
   - Without argument: `jj status` to verify current change is empty
     and parent is conflicted. Stop if not empty.
4. Step 2 — run mergiraf: `jj resolve --tool mergiraf -r @-`
   - Then `jj resolve --list -r @-` to check remaining conflicts
   - If none remain, skip to step 4
5. Step 3 — manual resolution loop:
   - For each file in `jj resolve --list -r @-`:
     read the file, use `jj diff -r @-` for context, edit to resolve,
     move to next file
   - After all files: `jj status` to confirm clean
6. Step 4 — prompt the user to `jj squash` (do not run it)
7. Self-improving note at the end

Key details to include in the body:
- The `-r @-` flag on resolve commands targets the conflicted parent
- Conflict markers in jj use a different format than git (document the
  `<<<<<<<` / `%%%%%%%` / `>>>>>>>` pattern with diff-style markers)
- The Read and Edit tools are used for manual resolution (not
  restricted by allowed-tools since those only govern Bash)

- [ ] **Step 3: Verify the skill reads correctly**

Read the file back and check:
- Frontmatter parses correctly (name, description, argument-hint,
  allowed-tools)
- Steps are numbered and unambiguous
- All jj commands include the correct flags
- No references to `jj squash` in allowed-tools

- [ ] **Step 4: Commit**

Commit with message: "Add resolve-conflicts skill"

---

### Task 2: Create the Claude Code copy

**Files:**
- Create: `ai/claude/skills/resolve-conflicts/SKILL.md`

- [ ] **Step 1: Copy the skill file**

Copy `ai/skills/resolve-conflicts/SKILL.md` to
`ai/claude/skills/resolve-conflicts/SKILL.md`. The content is
identical.

- [ ] **Step 2: Verify both files match**

Read both files and confirm they are identical.

- [ ] **Step 3: Commit**

Commit with message: "Copy resolve-conflicts skill to Claude Code directory"
