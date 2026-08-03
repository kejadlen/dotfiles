---
name: describing-changes
description: Use when drafting any explanation of changes (commit messages, PRs, code reviews, docs)
user-invocable: false
---

# Describing Changes

## Overview

A change description should explain *why* a decision was made, not *what* the code does. The diff already shows what. Your explanation adds reasoning the code alone cannot convey.

## When NOT to Use

When describing how code works (separate from why changes were made).

## The Core Pattern

| ❌ WHAT Focus | ✅ WHY Focus |
|---|---|
| "Fixed cache expiration check" | "TTL (seconds) and timestamp (milliseconds) were compared directly, expiring entries early" |

## Implementation

**REQUIRED SUB-SKILL:** Use the technical-writing skill. Change descriptions are prose for humans; apply the writing skill to ensure clarity and conciseness.

### 1. Identify What Changed

Read the diff. List concrete technical changes (modified function, added parameter, removed check, updated constant).

Re-read the diff immediately before writing the description, even if
you read it earlier in the conversation — files may have changed
since then.

### 2. Find the One Thing the Diff Doesn't Show

Ask what a reader can't reconstruct from the diff: the problem that
forced the change, the constraint that ruled out the obvious approach,
or an invisible impact. Usually there is nothing — the diff covers it.
When there is something, that's the body, and it's one sentence.

Those three are not sections to fill in. Pick the one that carries
information.

### 3. Write the Description

**Write the title.** A plain English sentence — no conventional commit
prefixes ([`fix:`, `feat:`, `refactor:`, etc.][no-cc]):

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
(`jj:`, `ruby-style:`, `glide:`). Several files under one directory
still share a home — scope it to that directory (`ai:`) rather than
calling it unscoped. Drop the scope only when the change has no natural
home at all.

**Then stop, unless step 2 turned something up.** Most commits ship
with no body. A rationale you *can* construct isn't one worth writing —
if the diff makes it obvious, a constructed sentence is decoration.

When step 2 did turn something up:

```
Normalize TTL unit mismatch

lib/cache.rb's expire? compared TTL (seconds) against timestamp
(milliseconds) directly. Normalizing both to milliseconds avoids
a migration of stored values.
```

**Format:**
- Title: under 60 characters (scope prefix included), plain English — capitalize the first word, or lowercase the scope and description when scoped
- Body: none by default, two sentences at most, naming the file or function when that orients the reader
- No headers, bullet lists, or sections in a commit body

### Delete Pass

Reread the draft and cut every sentence that restates the title in more
technical words, narrates the diff, or hedges. If nothing survives, the
title alone was the right message.

## Rationalizations to Resist

| Excuse | Counter |
|--------|---------|
| "This change deserves more context than usual" | The reader has the diff. One sentence of what they can't see. |
| "A body makes it look thorough" | Length is not thoroughness. Padding hides the real reason. |
| "I'll add a bullet list to organize it" | A commit body with structure is too long. Cut instead. |

## Git Trailers

Use [git trailers](https://alchemists.io/articles/git_trailers) for
all commit metadata. Trailers are `Key: value` pairs placed after a
blank line at the bottom of the commit message. Never encode metadata
in the subject line — that's what trailers are for.

```
Normalize TTL unit mismatch

lib/cache.rb's expire? compared TTL (seconds) against timestamp
(milliseconds) directly. Normalizing both to milliseconds avoids
a migration of stored values.

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
