---
name: committing-with-discipline
description: |
  Use when creating or reviewing commits, before using git/jj to commit -
  enforces contextual commit messages that document reasoning (not just what
  changed) and verifies commits contain exactly intended changes
---

# Committing with Discipline

## Overview

A commit message should document *why* a change was made, not *what* changed.
The diff already shows what. Your message adds the context, reasoning, and
decisions the code alone cannot convey. This skill prevents the
rationalizations that lead to lazy commits: vague messages, batched unrelated
changes, skipped verification, and stripped-down messages for "obvious"
changes.

## When to Use

- Before running `jj commit` or `git commit`
- When reviewing a commit before pushing
- When tempted to batch unrelated changes
- When the change feels "obvious" and doesn't need explanation
- Before closing the work - verification is part of discipline

## Core Principle

**Commit messages are for future readers, not current writers.**

A change that's obvious to you now won't be obvious:
- To future you (in 6 months, what was the tradeoff?)
- To someone reviewing the codebase
- During debugging when you need to understand *why* a line exists

## Red Flags - STOP and Rethink

If you catch yourself thinking any of these, stop and apply the discipline:

- "This is obvious/self-explanatory" → If obvious, explain why it's the right approach
- "It's just cleanup" → Cleanup of unrelated code should be separate commit(s)
- "I'll remember this later" → You won't. The commit message is for later
- "It's blocking other work" → Blocking is a reason to commit, not to batch unrelated changes
- "It's a quick fix" → Quick doesn't exempt you from explaining it
- "No one else works on this" → Lower standards = unmaintainable code later
- "I can amend later" → Amending forces history rewrites. Do it right the first time
- "The diff is small/obvious" → Document the *decision*, not the size
- "I need to explain this thoroughly" → Verbosity obscures reasoning. Cut ruthlessly

All of these mean: Stop. Follow the discipline. Your future self will thank you.

## The Discipline

### 1. Check What You're Committing (MANDATORY)

```bash
# Before ANY commit, see exactly what will be committed
jj diff              # See all changes
jj status            # See file list and states
```

**The question:** Do all these files belong together in one logical change?

**If no:** Create separate commits. Batching different logical changes is never justified.

**Reality check:** If you can't explain why these files changed together in 1-2
sentences, they don't belong in the same commit.

**No exceptions:**
- Not even if "they're both quick changes"
- Not even if "one builds on the other"
- Not even if "I'm under time pressure"
- Not even if "the files are related"

Different logical changes = different commits. Period.

### 2. Understand the Context

Before writing your message, answer these questions:

- What problem does this change solve?
- Why is this the right approach (vs alternatives)?
- Are there relevant decisions, tradeoffs, or constraints?
- Will there be questions when reviewing this commit in 6 months?

**Write these answers down as your message draft.** Don't trust your memory.

### 3. Apply Writing Discipline (MANDATORY)

**Before drafting any commit message, use the `elements-of-style:writing-clearly-and-concisely`
skill.** This is not optional. Commit messages are prose for humans; the skill
applies unconditionally.

Key principles from Strunk for commit messages:

- Use active voice (Rule 10): "Fixed X" not "X was fixed"
- Put statements in positive form (Rule 11): State what you did, not what was wrong
- Use definite, specific language (Rule 12): Avoid vague descriptions
- Omit needless words (Rule 13): Strip anything visible in the diff
- Place emphatic words at the end (Rule 18): Key reasoning should be prominent

### 4. Draft the Message

The diff shows what changed. Your message explains why:

**Structure:**
- **Opening line:** Succinct imperative + why (5-10 words). Must stand alone.
- **Reasoning (if needed):** Default 2-3 sentences. Expand only if context genuinely requires it.
- **Gotchas (if any):** Only if critical and non-obvious.

**CRITICAL:** Do NOT include anything visible in the diff. Strip ruthlessly. Every sentence must earn its place. Default to brevity; expand only with justification.

**Test for bad messages:** If you could write your commit message after reading
only the diff (without context), you are describing changes. Rewrite it to
explain reasoning instead.

**Bad example - describing the diff:**
```
Updated config file to use new API endpoint in lib/config.js
Changed ENDPOINT_URL constant from v1 to v2
Modified 3 lines: added new constant, updated old constant, added comment
```

(All visible in the diff. Reader sees what changed without needing your message.)

**Bad example - listing what the code does:**
```
Added caching layer to user service

Adds cache initialization, TTL configuration, and invalidation logic.
Cache stores user objects by ID with 5-minute expiry.
```

(The diff shows the code. What's missing: why add caching now?)

**Better - explaining the reasoning:**
```
Use API v2 endpoint to support OAuth scope requirements

v1 lacks scope boundaries; v2 includes automatic retry, eliminating custom handler.
```

Message explains the business/technical decision in two sentences, not the code itself.

### 5. Add Metadata Footer

Include attribution for assisted commits:

```
Assisted-by: Claude <model> via Claude Code
```

Use a HEREDOC for proper formatting:

```bash
jj commit -m "$(cat <<'EOF'
Your message here.

Assisted-by: Claude Sonnet 4.5 via Claude Code
EOF
)"
```

### 6. Verify the Commit (MANDATORY)

After committing, verify it contains exactly what you intended:

```bash
jj log --limit 1          # See the commit message
jj show                   # See the full diff of what you just committed
```

**The question:** Does this commit contain exactly (and only) what you intended?

**If no:** You made a mistake. The commit is saved, but you can:
- Amend it: `jj describe -r @` (if not yet pushed)
- Or create a follow-up commit fixing the issue

**Verify every single commit. No exceptions:**
- Not even if you're confident it's correct
- Not even if the change is small
- Not even if you're in a hurry
- Verification finds mistakes. If you skip verification, you will push mistakes.

**This is not optional.** Every. Single. Time.

## Common Mistakes

| Mistake | Why It Matters | Fix |
|---------|----------------|-----|
| Message describes files, not changes | Reader is lost about intent | Explain the *why* not the *what* |
| Batching unrelated changes | Future debugging is confused | One logical change per commit |
| "Quick fix" messages ("typo", "cleanup") | No context for future readers | Explain why, even if quick |
| Skipping verification | Wrong files committed (or secrets leaked) | Always run `jj show` after committing |
| Including obvious details | Wastes reader time | Trust the diff; add only non-obvious context |
| Amending commits after push | Breaks history for others | Do it right the first time |

## Example: Discipline in Action

### Scenario
You've fixed a caching bug in src/services/cache.ts. It was a simple one-line change.

### The Temptation
"One line change, obvious fix, let's commit: 'fix cache bug'"

### The Discipline
1. **Verify:** `jj status` → only cache.ts modified ✓
2. **Understand:** Why did this bug exist? What was the wrong behavior? How does the fix work?
3. **Write context:** "TTL wasn't being compared correctly. The bug was
   comparing timestamp (number) to TTL duration (also number), confusing
   milliseconds with seconds. Fixed by normalizing to milliseconds before
   comparison."
4. **Draft message:**
   ```
   Fix cache TTL comparison by normalizing to milliseconds

   TTL (seconds) and timestamp (milliseconds) were compared without unit
   conversion, causing premature expiry. Now normalize both to milliseconds.
   ```
5. **Verify:** `jj show` → confirms only the TTL comparison line changed ✓

**Result:** Future debugger sees not just the fix, but *why* it was needed. No
"why did they do this?" comments in code reviews.

## Implementation

When using this skill:
1. Before ANY commit, run `jj diff` and `jj status`
2. Verify all files in the commit belong together logically
3. Answer the "why" questions before writing the message
4. Draft your message explaining the *decision*, not the *diff*
5. Use HEREDOC for formatting + attribution
6. After committing, run `jj show` to verify exactly what was committed

## Rationalizations to Close

| Rationalization | Counter |
|-----------------|---------|
| "The diff is small, doesn't need explanation" | Small changes still need context. "Why is this line here?" matters more when code is simple |
| "This is obvious to anyone reading the code" | You're wrong. Commit message is for future-you who forgot, and reviewers missing context |
| "I don't have time for a real message" | You don't have time to debug this later when the context is gone |
| "I'll fix the message later with amend" | Amend after push breaks history. Do it right now. Amend only before pushing |
| "No one else works on this file" | Lower standards = abandoned codebase. Apply discipline to everything |
| "This file changed, let me just include it" | Include it only if it belongs with this logical change. When in doubt, separate commits |
| "I already verified it manually" | Manual verification is error-prone. Run `jj show`. No shortcuts |
| "The message can be figured out from the diff" | The *what* can be figured out. The *why* cannot. Message documents decisions |
| "These are both quick changes, I'll batch them" | Quick ≠ related. Different logical changes need different commits |
| "I'll remember why I did this" | You won't. Write it down in the commit message now |
| "The message format doesn't matter much" | Format matters less than context, but use HEREDOC for clean formatting |
| "I've already reviewed the code, skip jj show" | Reviewing code ≠ verifying commit contents. Run `jj show` every time |
| "I need to add more detail to be clear" | More words ≠ more clarity. Verbosity hides the real reason. Cut first; expand only if necessary |
| "This deserves a long explanation" | Default to 2-3 sentences. Expand only if the commit genuinely needs more context to justify its changes |
