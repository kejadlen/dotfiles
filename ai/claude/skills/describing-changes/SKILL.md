---
name: describing-changes
description: Use when drafting any explanation of changes (commit messages, PRs, code reviews, docs) - focuses on documenting reasoning and decisions rather than describing what changed
---

# Describing Changes

## Overview

A change description should explain *why* a decision was made, not *what* the code does. The diff already shows what. Your explanation adds reasoning the code alone cannot convey.

**Core principle:** Be concise. Readers skip lengthy explanations. 2-3 sentences explaining the problem, solution, and why this approach work.

## When NOT to Use

When describing how code works (separate from why changes were made).

## The Core Pattern

| ❌ WHAT Focus | ✅ WHY Focus |
|---|---|
| "Added .toMilliseconds() call" | "Timestamp and TTL were compared without unit normalization, causing..." |
| "Fixed cache expiration check" | "Cache entries expired prematurely because TTL (seconds) and timestamp (milliseconds) were compared directly..." |

## Implementation

**REQUIRED SUB-SKILL:** Use the elements-of-style:writing-clearly-and-concisely skill. Change descriptions are prose for humans; apply the writing skill to ensure clarity and conciseness.

### 1. Identify What Changed

Read the diff. List concrete technical changes (modified function, added parameter, removed check, updated constant).

### 2. Answer: Why Now?

Why is this change happening RIGHT NOW?
- What problem does it solve?
- What broke that forced this?

**If you can't answer "why now," the change shouldn't exist.**

### 3. Answer: Why This Approach?

Why this solution instead of alternatives?
- What constraint made this the only viable path?

**If you don't know why you chose this over something else, you haven't thought it through.**

### 4. Answer: Why Does It Matter?

What's the impact?
- What breaks without it?
- What improves with it?

**If the impact is invisible, the message should explain it.**

### 5. Write the Description

Begin with type prefix (fix:, feat:, docs:, ai:, refactor:, etc.) followed by concise reasoning:

```
fix: Normalize TTL unit mismatch

Cache entries expired because TTL (seconds) and timestamp (milliseconds)
were compared directly. Normalize both to milliseconds on comparison
to avoid data migration.
```

**Format:**
- First line: Under 60 characters, concrete problem or fix
- Body: 2-3 sentences (50-75 words typical)
- Problem → Solution → Why this approach

**Before finalizing, audit every sentence:**
- Is this sentence invisible in the diff? (No → delete it)
- Does this describe implementation visible in the code? (Yes → delete it)
- Does this just restate what a careful diff reader would already see? (Yes → delete it)

Each sentence must explain reasoning not visible in the code change itself.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| "Added authentication" | "Added OAuth to support permission boundaries for multi-tenant deployments" |
| "Fixed bug in parser" | "Parser treated empty strings and null identically, causing..." |

## Rationalizations to Resist

| Excuse | Reality | Counter |
|--------|---------|---------|
| "The diff is clear" | Clear about WHAT changed, not WHY | The diff shows WHAT. Your message explains WHY. |
| "I'll remember why I did this" | You won't. Lost context in weeks. | Write it down now. Future-you needs this. |
| "It's just cleanup/refactor" | Doesn't explain business motivation | Why now? Why this code? What problem does it solve? |
| "This is obvious from the code" | Obvious to you ≠ obvious to reviewers | Obvious what changed. Not obvious why. |

## Footer Requirements

If AI assisted in crafting the message, include Assisted-by footer:

```
Assisted-by: Claude Haiku 4.5 via Claude Code
```

Format: `Assisted-by: [Model name] via Claude Code`

This is MANDATORY when using this skill. Do NOT omit it.
