---
name: self-improving-skills
description: Use when a loaded skill is incomplete or sparse, or when you discover patterns, gotchas, or commands worth capturing in an existing skill during normal work.
user-invocable: false
---

# Self-Improving Skills

## Overview

Skills are living documents. When you use a skill and learn something it doesn't cover, **update the skill after completing the task.** This applies whether the skill is nearly empty or well-established.

## When the Skill Doesn't Cover What You Need

The skill won't have everything — especially early on. Figure it out:

1. **Check the tool's own help.** Run `--help`, `help`, or equivalent. CLI tools document themselves.
2. **Read nearby docs.** Look for READMEs, man pages, or doc directories in the tool's install path.
3. **Experiment.** Try the command. Read the error. Adjust.
4. **Search the filesystem.** `find`, `rg`, `ls` for config files, examples, or related scripts.

Once you've figured it out, that's exactly the kind of thing to capture in the skill.

## When to Improve

- Skill is sparse or missing sections you'd expect
- You discover a command, pattern, or gotcha not yet documented
- You hit an error and figure out the fix
- An existing section is wrong or outdated
- You find a workflow that works well and isn't captured

## How to Improve

1. **Do the task first.** Don't stop to write docs. Get the work done.
2. **After the task**, update the skill file with what you learned:
   - Commands and syntax that worked
   - Common mistakes and fixes
   - Workflows you followed
   - Gotchas and edge cases
3. **Keep additions small.** Add exactly the missing piece — a command, a gotcha, a workflow step. Don't bulk-import documentation from `--help` or reference material. The skill captures what you *learned through use*, not what you *could look up*.
4. **Keep the structure clean.** Follow the section pattern from existing content, or start with:
   - Quick Reference (commands/syntax)
   - Common Workflows
   - Common Mistakes
5. **Don't add speculative content.** Only document what you actually used and verified this session.

## Mark Self-Improving Skills

When creating a self-improving skill, note it in the skill itself so future sessions know to apply this workflow. Add a line like:

> *This is a self-improving skill — see the `self-improving-skills` skill.*

This closes the loop: the skill gets loaded, the agent sees the note, loads this skill, and knows to update after use.

## New Skills Should Start Lean

When creating a new self-improving skill, resist the urge to front-load it with everything you know. Start with just enough to orient — what the tool is, the core workflow rule, key conventions. Everything else gets discovered through use and added incrementally. A skill that starts comprehensive has nowhere to grow and no guarantee its content reflects real usage.

## What NOT to Do

- Don't rewrite the whole skill on first use — add incrementally
- Don't add content you didn't verify during this session
- Don't remove existing content that's still accurate
- Don't bloat the skill with edge cases nobody's hit yet
- Don't restructure or rewrite surrounding sections — add exactly the missing piece and leave the rest alone
- Don't bulk-copy from `--help` output, READMEs, or other reference material — the skill is a journal of learned experience, not a mirror of existing docs
