---
name: describing-changes
description: |
  Use when drafting any explanation of changes (commit messages, PRs, code
  reviews, docs) - focuses on documenting reasoning and decisions rather than
  describing what changed
---

# Describing Changes

## Overview

A change description should explain *why* a decision was made, not *what* the code does. The diff already shows what. Your explanation adds the reasoning, tradeoffs, and context the code alone cannot convey.

**Core principles:**
- The reader can see the code changed. They cannot see why you chose this approach instead of alternatives, or what constraint forced the change.
- **Be concise.** Readers skip lengthy explanations. 2-3 sentences covering the problem, solution, and tradeoff is sufficient. Strip everything visible in the diff.

## When to Use

About to explain why something changed? Use this skill.

Applies to:
- Commit messages
- Pull request descriptions
- Code review comments
- Technical documentation
- Change logs

**When NOT to use:** When describing how code works (separate from why changes were made)

## The Core Pattern

| ❌ WHAT Focus | ✅ WHY Focus |
|---|---|
| "Added .toMilliseconds() call" | "Timestamp and TTL were compared without unit normalization, causing..." |
| "Fixed cache expiration check" | "Cache entries expired prematurely because the stored timestamp used a different unit scale than..." |
| "Updated endpoint from v1 to v2" | "v1 endpoint lacks OAuth scope support needed for permission boundaries. v2 provides..." |
| "Changed loop logic" | "Original loop terminated early when encountering null values, breaking batching for partial datasets. New logic..." |

**Ask yourself:** Can I write this explanation after reading only the diff? If yes, you're describing the change. Rewrite to explain reasoning instead.

## Implementation

**REQUIRED SUB-SKILL:** Use the elements-of-style:writing-clearly-and-concisely skill when drafting any change description. This is mandatory. Commit messages are prose for humans; apply the writing skill unconditionally to ensure clarity and conciseness.

Before writing any change description:

### 1. Identify What Changed

Read the diff. List the concrete technical changes:
- Modified this function
- Added this parameter
- Removed this check
- Updated this constant

### 2. Answer: Why Now?

Why is this change happening RIGHT NOW, at this moment?
- What problem does it solve?
- What broke that forced this?
- What new requirement triggered it?
- What opportunity did it enable?

**If you can't answer "why now," the change shouldn't exist.**

### 3. Answer: Why This Approach?

Why this solution instead of alternatives?
- What approaches were considered?
- Why were they rejected?
- What constraint made this the only viable path?
- What tradeoff did you accept?

**If you don't know why you chose this over something else, you haven't thought it through.**

### 4. Answer: Why Does It Matter?

What's the impact?
- How does this affect behavior?
- What breaks without it?
- What improves with it?
- What downstream systems depend on this change?

**If the impact is invisible, the message should explain it.**

### 5. Write the Description

Begin with a type prefix (fix:, feat:, docs:, ai:, refactor:, etc.) followed by concise reasoning:

```
fix: Cache TTL comparison unit mismatch

Cache entries expired prematurely because TTL (seconds) and timestamp
(milliseconds) were compared directly. Normalizing both to milliseconds
on comparison avoids data migration and works immediately.
```

**Format:** Problem → Solution → Why this approach, in 2-3 sentences maximum.

**First line:** Keep it short and specific (under 50 characters ideally, rarely exceeding 60). The first line should communicate the core problem or fix in one concise phrase. Longer first lines force readers to scan instead of grasp the change at a glance.

**Don't include:**
- Details visible in the diff (like the specific code change)
- Multiple alternatives and their tradeoffs (just mention the constraint that eliminated them)
- Implementation details (show in code, not message)
- Justifications for why the approach is "good" (reason why it was chosen vs alternatives, not praise)

**Multi-part changes:** If one commit includes multiple changes (error handling + retry logic + config), explain how they work together in one sentence. If changes are independent, use separate commits instead.

## Common Mistakes

| Mistake | Why It Fails | Fix |
|---------|------------|-----|
| "Added authentication" | Describes code, not reasoning | "Added OAuth to support permission boundaries for multi-tenant deployments" |
| "Fixed bug in parser" | Says what, not why it broke | "Parser treated empty strings and null identically, causing..." |
| "Refactored loop" | Describes the change | "Original loop couldn't handle batches with null entries. New approach..." |
| "Updated config" | Vague about intent | "Increased timeout from 5s to 30s because slow networks were exceeding..." |
| All detail visible in diff | Assumes reader sees what you see | Strip diff details, add context not visible in code |

## Red Flags - When You're Being Too Wordy

Stop and trim if you catch yourself:

- Writing more than 3 sentences - PAUSE and ask: does each sentence explain reasoning not visible in diff?
- Including implementation details visible in the diff
- Explaining what the code does rather than why the change exists
- Justifying the approach as "good" instead of explaining the constraint
- Enumerating multiple alternatives considered (mention only the blocker)
- Adding foundational context readers can find in issue tickets
- "But this change is complex/important/multi-faceted" → Still 2-3 sentences max. If genuinely complex, it's multiple commits, not one wordy message.

**Length discipline:**
- Commit messages: typically 2-3 sentences (50-75 words)
- Simple fixes: Under 30 words

**Before finalizing, audit every sentence:**
- Is this sentence invisible in the diff? (Yes → keep it, No → delete it)
- Does this describe implementation visible in the code? (Yes → delete it, No → keep it)
- Does this just restate what a careful diff reader would already see? (Yes → delete it, No → keep it)

If any sentence fails this audit, remove it. The diff shows WHAT changed. Your message explains WHY (and only if WHY is not obvious from reading the code change itself).

**NEVER rationalize:** "This change is complex so I need to explain the cases" - if all cases are visible in the diff, don't list them. "This change is important so the message should be thorough" - thorough means every word earns its place, not verbose.

## Red Flags - When You're Describing the Change Instead of Explaining It

Stop and rewrite if you catch yourself saying:

- "Added/removed/modified X" → Rephrase: WHY did you add/remove/modify it?
- "This line does Y" → Rewrite: This change was needed because...
- "Changed from A to B" → Rewrite: We switched from A to B because A had the problem of...
- "The diff shows Z" → Rewrite: The reason for this change is...
- "Obvious from the code" → That's exactly backwards - if it's obvious what changed, explain why it changed
- "Cleanup/refactor" → Refactor from what? Into what? Why?
- "I'll remember why I did this" → You won't. Write it down now.
- "The diff is clear" → Clear about WHAT changed. Not clear about WHY.
- "It's just cleanup" → Cleanup of what? Why now instead of before?

All of these signal you're still describing the change instead of explaining the reasoning.

## Example: Before and After

### ❌ Describing the Change
```
Fix cache TTL comparison

Modified cache.ts to normalize timestamp units before comparison.
Added .toMilliseconds() call on both values before checking expiration.
Prevents premature cache invalidation.
```

(Reader sees: "Added .toMilliseconds()". So what? Why was this needed?)

### ✅ Explaining the Reasoning (Concise)
```
fix: Normalize TTL unit mismatch

Cache entries expired because TTL (seconds) and timestamp (milliseconds)
were compared directly. Normalize both to milliseconds on comparison
to avoid data migration.
```

(Reader sees: Problem → Solution → Why this approach. Done in 2 sentences.)

## Rationalizations to Resist

When you catch yourself thinking one of these, STOP and add more context:

| Rationalization | What It Blocks | Counter |
|-----------------|----------------|---------|
| "The diff is clear" | Doesn't explain why this approach over alternatives | The diff shows WHAT changed. Your message explains WHY. |
| "I'll remember why I did this" | Lost context in 2 weeks when debugging | You won't remember. Write it down now. Future-you needs this. |
| "It's just cleanup/refactor" | Doesn't explain the business motivation | Why now? Why this code? What problem does cleaning up solve? |
| "This is obvious from the code" | Assumes readers have your context | Obvious to you ≠ obvious to reviewers missing background. |
| "No one else works on this file" | Lowers standards temporarily | Lower standards compound. Document anyway. |
| "The change is small/simple" | Size doesn't determine if reasoning matters | Small changes need context more, not less. |
| "I need to explain everything" (over-explaining) | Makes readers skip the message | 2-3 sentences is enough. If more needed, it belongs in issue ticket. |
| "The skill says explain alternatives" | Leads to verbose comparisons | Explain the constraint, not all options. Readers don't need a matrix. |

All of these thoughts mean: Either add context explaining reasoning (first 6) or trim to essentials (last 2).

## Key Questions

Use these to validate your change description:

1. **What problem does this solve?** - Must be answerable without looking at code
2. **Why this approach?** - What alternatives were rejected and why?
3. **What breaks without it?** - Business/product impact, not just technical
4. **Why not done before?** - What changed to make this relevant now?
5. **What does the reader need to understand?** - What context am I providing that isn't in the diff?

If you skip any of these, add more context to your description.

## Footer Requirements

**If AI assisted in crafting the message, include Assisted-by footer:**

```
Assisted-by: Claude Haiku 4.5 via Claude Code
```

Format: `Assisted-by: [Model name] via Claude Code`

This is MANDATORY when using this skill. Do NOT omit it.
