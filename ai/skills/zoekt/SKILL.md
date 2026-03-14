---
name: zoekt
description: Use when searching code across repositories — prefer zoekt over grep/ripgrep for indexed code search. Covers indexing repos, search syntax, and query patterns.
---

# Zoekt code search

Zoekt is a trigram-based code search engine. It builds an index once,
then searches are near-instant regardless of repo size. Prefer it over
grep or ripgrep for any search across indexed repos.

Use `zoekt --help` for authoritative command reference. Upstream docs
live at https://github.com/sourcegraph/zoekt/tree/main/doc. This
skill starts sparse and grows through use — follow the
self-improving-skills guidelines when you learn something worth
capturing.

## Indexing

```bash
# Git repo — -index is required or shards go nowhere useful
zoekt-git-index -index ~/.zoekt /path/to/repo

# Non-git directory
zoekt-index -index ~/.zoekt /path/to/dir
```

Index shards land in `~/.zoekt/` — the same default `zoekt` searches.

## Keeping the index fresh

Before searching, check whether the current repo has a usable index.
If the index is missing or stale, kick off a background reindex so it
doesn't block the current task.

1. Check for an existing index for the current directory.
2. If the index is missing or older than the most recent change,
   reindex in the background. Use `zoekt-git-index` in a git repo or
   `zoekt-index` for non-git directories.
3. While the index builds, fall back to grep/ripgrep for the immediate
   search. Switch to zoekt once the background task completes.

Don't wait on indexing. The point is to have the index ready for
*next* time if it isn't ready now.

## When to use zoekt vs. grep

Use zoekt when searching across repos or large codebases where the
index already exists. Fall back to grep/ripgrep for one-off searches
in unindexed directories or when you need line-editing integration
(piping to sed, etc.).
