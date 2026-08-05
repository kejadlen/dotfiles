---
name: self-improving-skills
description: Use right after finishing a task where a skill you relied on fell short — you had to run `--help` or read docs it should have covered, you tried a command or flag that turned out not to exist, you hit an error and worked out the fix, or the skill was sparse, outdated, or missing a workflow. Load it and follow it to fold what you learned back into that skill before wrapping up, rather than moving on. Applies during normal work, not only when asked.
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

- **You had to check `--help`.** If the skill didn't have the command you needed and you had to fall back to `--help` or docs, that's the clearest signal the skill is missing something. After the task, add what you learned.
- **You tried a command that doesn't exist.** If you assumed a subcommand or flag existed and it failed, capture the correct approach so the mistake isn't repeated.
- Skill is sparse or missing sections you'd expect
- You discover a command, pattern, or gotcha not yet documented
- You hit an error and figure out the fix
- An existing section is wrong or outdated
- You find a workflow that works well and isn't captured

**Do it immediately after the task — don't wait to be asked.** If the user has to say "update the skill," you've already missed the cue.

## How to Improve

1. **Do the task first.** Don't stop to write docs. Get the work done.
2. **After the task**, update the skill file with what you learned:
   - Commands and syntax that worked
   - Common mistakes and fixes
   - Workflows you followed
   - Gotchas and edge cases
3. **Keep additions small.** Add exactly the missing piece — a command, a gotcha, a workflow step. Don't bulk-import documentation from `--help` or reference material. The skill captures what you *learned through use*, not what you *could look up*.
4. **Put it where it belongs.** Extend the section that already covers that ground; add a heading only when nothing fits. Don't open a summary section — Quick Reference, Checklist, Red Flags — that restates what the file already says. A command table earns its place when it *is* the content, not when it's a second copy of it.
5. **Don't add speculative content.** Only document what you actually used and verified this session.

## Mark Self-Improving Skills

When creating a self-improving skill, add a marker so a future session knows to apply this workflow. Make the marker an **instruction that names the action**, not a passive pointer. A line like "see the `self-improving-skills` skill" reads as a vague label — agents acknowledge it and move on without loading anything. Write an imperative tied to the trigger condition instead:

> *This is a self-improving skill. If you used it and it came up short — a missing command, flag, gotcha, or workflow — invoke the `self-improving-skills` skill and follow it before you finish.*

This closes the loop: the agent loads the marked skill, hits the marker mid-task, and the imperative ("invoke … and follow it before you finish") is concrete enough to actually trigger the load and the update — instead of just noticing the gap and carrying on.

## New Skills Should Start Lean

When creating a new self-improving skill, resist the urge to front-load it with everything you know. Start with just enough to orient — what the tool is, the core workflow rule, key conventions. Everything else gets discovered through use and added incrementally. A skill that starts comprehensive has nowhere to grow and no guarantee its content reflects real usage.

## What NOT to Do

- Don't remove existing content that's still accurate
- Don't bloat the skill with edge cases nobody's hit yet
- Don't restructure or rewrite surrounding sections — add exactly the missing piece and leave the rest alone
- Don't state a fact the skill already states elsewhere — give it one home and reference that from anywhere else needing it

## Tightening is a separate job

These rules cover incremental additions mid-task: add the missing piece, leave
the rest alone. They are not a ban on ever reorganizing a skill — when one
needs cutting or restructuring, that's a deliberate pass with `tighten-docs`.

The two fit together as long as additions don't create work for that pass, so
follow `tighten-docs`' rules on keeping `SKILL.md` procedural and pushing bulky
examples or variant detail into linked reference files instead of growing the
skill.
