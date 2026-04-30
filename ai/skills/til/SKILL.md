---
name: til
description: Use when you've discovered something non-obvious during work — a gotcha, undocumented behavior, or surprise that would change how you'd approach similar work. Also use when starting non-trivial work or stuck on tool/library behavior to check prior learnings.
---

# TIL log

Capture learnings that don't have a home yet. Surface prior learnings before similar work.

## When to invoke

**Write**: you discovered something non-obvious that future agents would benefit from knowing. Examples: a tool flag that behaves differently than its docs suggest, a workaround that took several attempts to find, a constraint you only noticed after hitting it.

**Read**: starting non-trivial work in an area, or stuck on tool/library behavior. Check whether prior sessions logged something relevant. Grep by the tool or library name first; fall back to listing all TILs (they're short).

## Decision tree (write)

You have a learning worth keeping. Pick one:

1. Fold it into an existing skill if it fits within scope — even a skill you didn't load this session. Invoke `self-improving-skills` and edit the skill directly. Don't write a TIL; the skill is the durable artifact.

2. Otherwise, write a TIL file. Use this when the learning is cross-cutting, doesn't fit any current skill, or is too small or speculative for a skill of its own. Continue below.

Prefer (1) when there's a clean fit; default to (2) otherwise.

## Anti-triggers (don't write)

- Project-specific context — use the auto-memory system instead (`feedback`, `project`, `reference`).
- Already documented in code, an existing skill, or project docs — don't duplicate.
- A how-to recipe — recipes belong in skills. The TIL captures the *learning* (e.g., "rg's `--multiline` doesn't compose with `--files-with-matches`"), not the recipe.
- Trivially obvious or one-off — if you wouldn't reach for it again, skip.

## Writing a TIL

Files live at `~/.claude/til/<slug>.md`. Run `mkdir -p ~/.claude/til` if the directory doesn't exist.

The slug is short, hyphenated, descriptive — derive it from the title. Examples: `jj-mergiraf-3way.md`, `zoekt-regex-anchors.md`, `gh-pr-checks-flake.md`.

Frontmatter:

```yaml
---
title: <one sentence, under ~60 chars>
tags: [tag1, tag2, tag3]
learned: YYYY-MM-DD
status: pending
---
```

`status` stays `pending` until the learning is folded into a skill (see Consolidation below).

The body is 2-5 sentences. Cover what surprised you, what to do or avoid next time, and a pointer to the source (file, command, URL, version) if relevant. Not a recipe. Not a skill draft. A note your future self can use. If you need more than a short code block to capture it, it's probably a skill, not a TIL.

Example:

````markdown
---
title: rg --multiline doesn't compose with --files-with-matches
tags: [ripgrep, search]
learned: 2026-05-07
status: pending
---

`rg --multiline -l <pattern>` returns the correct file list, but the
multiline match context is suppressed. If you need both, run two passes:
`-l` for files, then a second pass with `-A`/`-B` for context per file.
Confirmed on ripgrep 14.1.
````

### Dedup before writing

Check whether a related TIL already exists:

```bash
ls ~/.claude/til/
grep -l '^tags:.*\btag-name\b' ~/.claude/til/*.md
```

The anchored pattern matches only the `tags:` line so body text doesn't produce false positives. If one exists, update it (refine body, extend tags) rather than creating a duplicate.

### Tag hygiene

Before introducing a new tag, list what's already in use:

```bash
grep -h '^tags:' ~/.claude/til/*.md | sort -u
```

Reuse existing tags when reasonable. Only invent new tags when no existing tag fits.

## Reading TILs

```bash
ls ~/.claude/til/                                       # all TILs (slug = title at a glance)
grep -l '^tags:.*\btag-name\b' ~/.claude/til/*.md       # by tag
grep -l '^status: pending' ~/.claude/til/*.md           # unconsolidated learnings
```

Read the relevant files in full — they're short by design.

If a TIL turns out to be wrong (the original observation was incorrect, or the upstream tool fixed the behavior), update or delete it rather than leaving a stale claim. A TIL is only useful if future-you can trust it.

## Consolidation (manual, deferred)

When several pending TILs share a tag and form a coherent body:

1. Fold them into a new or existing skill via the `self-improving-skills` flow.
2. In each folded TIL, set `status: consolidated` and add a `consolidated_into: <skill-name>` line to the frontmatter.
3. Don't delete consolidated TILs — they're the audit trail showing what fed into the skill.

