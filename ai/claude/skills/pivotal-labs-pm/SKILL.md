---
name: pivotal-labs-pm
description: Use when writing stories, breaking down work, prioritizing a backlog, organizing what to build next, or managing scope. Covers story writing, acceptance criteria, story splitting, backlog ordering, and icebox triage.
---

# Pivotal Labs PM

Backlog management adapted from the Pivotal Labs methodology. The backlog is a single stack-ranked list. The story at the top is the next thing to work on. Scope is the only flexible variable -- cut scope, not quality.

## Stories

A story captures what changes, who benefits, why it matters, and how to verify it's done.

Every story must answer:

- **What** is the change?
- **Who** is it for?
- **Why** does it matter now?
- **Done when?** Specific, testable acceptance criteria.

### Splitting

Prefer smaller stories. The goal is the smallest change that delivers meaningful value on its own.

| Signal | Action |
|---|---|
| Multiple "and"s in acceptance criteria | Split into independent stories |
| Can't explain who benefits | Not a story yet -- clarify or discard |
| Can't explain why now | Move to icebox |
| Too much uncertainty to define done | Spike first (timeboxed investigation) |
| Acceptance criteria could each ship alone | Each criterion is its own story |

## The Backlog

### Containers

- **Icebox:** Unscheduled ideas. No ordering required. Stories live here until worth doing.
- **Backlog:** Strict linear ordering. Every story has exactly one position. No priority buckets. Above means before, below means after.

### Managing

- Reprioritize continuously. The backlog is never "set."
- Use **release markers** as goal posts -- a named milestone at a position in the backlog. Stories above ship for that milestone; stories below don't.
- When scope exceeds capacity, cut from the bottom.
- Move from icebox to backlog only when a story has a clear narrative and acceptance criteria.

### Flow

Work top to bottom. Start the top story, finish it, start the next.

**unstarted → started → delivered → accepted**

- **Delivered** means ready for verification against acceptance criteria.
- **Accepted** means done.
- If delivered work doesn't meet acceptance criteria, reject with specific feedback. It returns to started.
