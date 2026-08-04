---
name: editing-prose
description: Use when writing or editing prose longer than a paragraph to catch AI writing tropes — patterns that flag text as LLM-generated rather than human-written.
---

# Editing Prose

Catches AI writing tropes that other writing skills miss. Sources:
[tropes.fyi](https://tropes.fyi) and
[Modeltell](https://github.com/thirdshiftlab/modeltell).

Complements `technical-writing` (structure, terminology),
`writing-clearly-and-concisely` (sentence-level clarity), and
`diataxis` (document classification). Those skills cover good writing in
general; this one covers the specific patterns LLMs reach for that flag
text as AI-generated.

## When not to use

- Code comments (different conventions; brevity matters more)
- Commit messages (use `describing-changes`)
- Short replies, single-sentence answers, terse status updates
- Code itself

## Workflow

1. Read [`ai-tropes.md`](ai-tropes.md) for the full catalog, with
   examples for each pattern, organized by word choice, sentence
   structure, paragraph structure, tone, formatting, and composition.
2. Scan the prose for each trope category, looking for repetition or
   stacking — one instance of a pattern is usually fine; multiple is
   the tell.
3. Edit in place. Replace each flagged pattern with plain, varied
   prose.
4. Re-read the edited version end-to-end. AI tropes often hide in
   transitions and conclusions; a second pass catches what the
   category-by-category scan missed.

## The core principle

Don't mechanically eliminate every em dash or every "is" → "serves
as" — that produces stilted, evasive writing in the other direction.
Look for *concentration* and *stacking*. A single em dash in a
1000-word piece is invisible; ten is the tell.

## High-signal tropes (check these first)

These are the strongest tells. If you see them, edit them:

- Negative parallelism: "It's not X — it's Y" / "not because X, but
  because Y"
- "Not X. Not Y. Just Z." countdown
- "The X? A Y." self-posed rhetorical questions
- Em-dash density (more than ~3 per 1000 words is suspicious)
- Bold-first bullets (every list item starts with `**Word**:`)
- "Delve", "tapestry", "landscape", "leverage" as a verb
- "Serves as"/"stands as"/"represents" instead of "is"
- Tricolon stacking (rule of three repeated three times in a row)
- "Here's the kicker"/"Here's the thing" false suspense
- Unicode arrows (`→`) and smart quotes in plain text contexts
- "Whether you're X or Y" pseudo-inclusive openers
- "In today's [adjective] landscape/world/era" openers
