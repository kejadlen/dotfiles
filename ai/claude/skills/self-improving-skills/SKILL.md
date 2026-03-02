---
name: self-improving-skills
description: Use when a loaded skill is incomplete or sparse, or when you discover patterns, gotchas, or commands worth capturing in an existing skill during normal work.
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
3. **Keep the structure clean.** Follow the section pattern from existing content, or start with:
   - Quick Reference (commands/syntax)
   - Common Workflows
   - Common Mistakes
4. **Don't add speculative content.** Only document what you actually used and verified this session.

## What NOT to Do

- Don't rewrite the whole skill on first use — add incrementally
- Don't add content you didn't verify during this session
- Don't remove existing content that's still accurate
- Don't bloat the skill with edge cases nobody's hit yet
