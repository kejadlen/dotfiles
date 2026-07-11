---
name: describing-changes
description: Use when drafting any explanation of changes (commit messages, PRs, code reviews, docs)
user-invocable: false
---

# Describing Changes

## Overview

A change description should explain *why* a decision was made, not *what* the code does. The diff already shows what. Your explanation adds reasoning the code alone cannot convey.

**Core principle:** Judge from the diff and context whether a body is warranted. When it is, cover what changed and why, with file or function references where useful. Never restate the title in more technical language; every body sentence must add information the title didn't already give.

## When NOT to Use

When describing how code works (separate from why changes were made).

## The Core Pattern

| ❌ WHAT Focus | ✅ WHY Focus |
|---|---|
| "Added .toMilliseconds() call" | "Timestamp and TTL were compared without unit normalization, causing..." |
| "Fixed cache expiration check" | "Cache entries expired prematurely because TTL (seconds) and timestamp (milliseconds) were compared directly..." |

## Implementation

**REQUIRED SUB-SKILL:** Use the technical-writing skill. Change descriptions are prose for humans; apply the writing skill to ensure clarity and conciseness.

### 1. Identify What Changed

Read the diff. List concrete technical changes (modified function, added parameter, removed check, updated constant).

Re-read the diff immediately before writing the description, even if
you read it earlier in the conversation — files may have changed
since then.

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

**Start with title only.** Write a plain English sentence — no
conventional commit prefixes ([`fix:`, `feat:`, `refactor:`, etc.][no-cc]):

```
Reduce visual noise in error construction
```

[no-cc]: https://sumnerevans.com/posts/software-engineering/stop-using-conventional-commits/

**Prefix the title with a scope when the change has one clear home.** A
scope names the feature, topic, or place the change belongs to,
followed by a colon and a lowercase description:

```
bin: add vipe script
```

A scope is not a conventional commit prefix. The banned prefixes name a
change *type* (`fix:`, `feat:`, `refactor:`); a scope names a *subject*
(`jj:`, `ruby-style:`, `glide:`). Drop the scope when a change spans
several subjects or has no natural home — an unscoped sentence stays the
default.

**Judge the diff, then decide on a body.** Skip it when:
- The diff is genuinely trivial: a typo fix, a formatting pass, a dependency bump with no behavioral change.
- A reader can already reconstruct the reasoning from the diff alone.
- The body would only paraphrase what the diff already shows.

A rationale you *can* construct isn't automatically one worth writing —
if the diff already makes it obvious, a constructed sentence is
decoration, not information. Default to no body; add one only when it
earns its place.

Otherwise, write one — cover what changed, naming the file or
function when it orients the reader, and why.

```
Normalize TTL unit mismatch

lib/cache.rb's expire? compared TTL (seconds) against timestamp
(milliseconds) directly. Normalizing both to milliseconds avoids
a migration of stored values.
```

**Format:**
- Title: under 60 characters (scope prefix included), plain English — capitalize the first word, or lowercase the scope and description when scoped
- Body: sized to the change — a sentence is often enough, but let genuinely complex reasoning run longer
- State what changed, then why (omit needless words)

**Before adding a body sentence, check it earns its place:**
- Does it restate the title in more technical words? If yes, delete it — that's not new information.
- Does it name a file, function, or constraint the title doesn't cover? Keep it.
- Does it explain why this approach, not just what changed? Keep it.

Every sentence must add information the reader didn't already get
from the title or a careful read of the diff.

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
| "The diff is small, no body needed" | Size isn't the test — reconstructability is | Can a reader get the reasoning from the diff alone? If not, write the body. |
| "I'll just restate the title with more jargon" | That's not new information | Delete it unless it names a file/function or explains why |

## Git Trailers

Use [git trailers](https://alchemists.io/articles/git_trailers) for
all commit metadata. Trailers are `Key: value` pairs placed after a
blank line at the bottom of the commit message. Never encode metadata
in the subject line — that's what trailers are for.

```
Normalize TTL unit mismatch

TTL (seconds) and timestamp (milliseconds) compared directly.
Normalizing both to milliseconds avoids migration.

Assisted-by: Claude Opus 4.8 via Claude Code
```

### Required trailers

`Assisted-by` is mandatory when AI drafts or substantially edits the
message. The format is `Assisted-by: [Model name] via [tool name]`
— the human-readable model name, then `via`, then the tool. Use the
actual model and tool you are running inside; do not copy examples
blindly.

Correct: `Assisted-by: Claude Opus 4.8 via Claude Code`. Do not append
the raw model ID in parentheses (`Claude Opus 4.8 (claude-opus-4-8)`),
drop the `via [tool name]` half, or substitute the model ID for the
name.

### Optional trailers

Add other trailers when they provide useful context for post-processing
or traceability:

- `Issue: <id>` — links the commit to a tracked issue
- `Co-authored-by: Name <email>` — credits collaborators

Capitalize the first letter of each trailer key. Keep trailers
alphabetically sorted when there are three or more.
