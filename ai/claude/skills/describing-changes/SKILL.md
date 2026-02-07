---
name: describing-changes
description: Use when drafting any explanation of changes (commit messages, PRs, code reviews, docs)
---

# Describing Changes

## Overview

A change description should explain *why* a decision was made, not *what* the code does. The diff already shows what. Your explanation adds reasoning the code alone cannot convey.

**Core principle:** Most commits need only a title. Add body text only when reasoning is truly non-obvious from the diff. Omit needless words.

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

**Start with title only.** Type prefix + concise reasoning:

```
refactor: Reduce visual noise in error construction
```

**STOP: Is the title sufficient?** If yes, you're done. No body needed.

**Add body ONLY if:**
- Reasoning is truly non-obvious from diff
- Multiple approaches existed and you chose this one for specific reasons
- Impact is invisible without explanation

When body is necessary:

```
fix: Normalize TTL unit mismatch

TTL (seconds) and timestamp (milliseconds) compared directly.
Normalizing both to milliseconds avoids migration.
```

**Format:**
- Title: Under 60 characters, concrete problem or fix
- Body: 1-2 sentences maximum, under 20 words total
- Problem → Solution (omit needless words)

**Before adding ANY body text, audit:**
- Is this sentence invisible in the diff? (No → delete it)
- Does this describe implementation visible in the code? (Yes → delete it)
- Does this just restate what a careful diff reader would see? (Yes → delete it)

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
| "Need to explain the approach" | Title may be sufficient | STOP: Is title sufficient? Most commits need no body. |

## Footer Requirements

If AI assisted in crafting the message, include Assisted-by footer:

```
Assisted-by: Claude Haiku 4.5 via pi
```

Format: `Assisted-by: [Model name] via [tool name]`

Use the actual tool you are running inside (e.g., pi, Claude Code). Do NOT copy the example blindly.

This is MANDATORY when using this skill. Do NOT omit it.
