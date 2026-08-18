---
name: jj
description: Use when running any jj (Jujutsu) version control command — committing, describing, bookmarks, rebase, squash, restore, push, or inspecting log/diff/status — and when looking up jj syntax, flags, or behavior. Invoke before free-handing jj commands from memory.
---

# Jujutsu (jj) version control

Verify behavior and flags against `jj <command> --help`, and read
`pitfalls.md` before reaching for `squash`, `diff`, `show`, `file show`,
filesets, `-R`, or a revset with parentheses — it catalogues flags that fail
silently, hang without a TTY, or make a no-op look like it worked.

*This is a self-improving skill — see the `self-improving-skills` skill.*

## Core workflow

### commit vs. describe vs. new

The working copy `@` is always a real commit; edits stream into it live.

| Command | Sets message? | Moves `@`? | Use for |
|---|---|---|---|
| `jj describe [-m]` | yes, on target (default `@`) | no | name or rewrite a commit's message in place |
| `jj new <rev>` | no | yes, to a new empty commit | start fresh work on top of `<rev>` |
| `jj commit -m` | yes, on `@` | yes, to a new empty commit | finish `@` and move on — `describe @` + `new` in one step |

### Splitting a commit

`jj split -r <rev> -m 'message' <paths>` extracts the named paths
non-interactively; `-m` keeps it out of `$EDITOR` when `<rev>` already has a
description.

By default the *selected* paths keep the original change ID and the
remainder becomes a new child commit. To leave the original change ID and
description in place and make the extracted paths the new commit, pass the
same revision to both `-r` and `-A`:

```bash
jj split -r abcd -A abcd -m 'scope: message' path/to/file
```

Splitting an ancestor rebases every descendant, `@` included — content
survives but commit IDs change, so it's out when a commit ID has to stay put.

## Absorb

`jj absorb` moves each hunk of the working-copy change to the closest mutable
ancestor that last touched those lines. Hunks it can't place unambiguously
stay put, so re-check `jj st` after; the source commit is abandoned only when
every hunk lands and it has no description.

```bash
jj absorb                            # distribute every hunk to its ancestor
jj absorb <fileset>                  # only these paths
jj absorb --into <rev>               # limit destinations to <rev> and ancestors
```

When the hunks all belong in one specific commit, use `jj squash --into <rev>
<fileset>` instead — `pitfalls.md` covers its `--from` and `-u`/`-m`
requirements.

## Megamerges

A megamerge is bookmarked `mm` by convention, and the `jj-workspaces` skill
uses that name when placing workspaces in the DAG. Land new work with
`jj absorb` or `jj squash --into` so `@` stays on the merge.

### Adding a new branch to the merge

Work written on top of `mm` can't be pushed — its diff against trunk
contains every parent. Move it beneath the merge instead, so it hangs off
trunk and `mm` picks it up as one more parent:

```bash
jj rebase -r <rev> -A trunk -B mm    # one rewrite, no cleanup
```

Do it in one rewrite. `-r` always re-parents the rebased commit's descendants
onto its former parents, so rewriting `mm` separately to add a destination
hands `@` all of `mm`'s former parents, leaving a second near-identical
megamerge beside the real one. `jj rebase -r @ -o mm` repairs it.

`-o`/`--onto` is repeatable (`-d` is the older alias), so `-o p1 -o p2 ...`
sets several parents.

Don't read the result off the ASCII graph. Diff the merge as an invariant
across the rewrite, and list its parents explicitly:

```bash
jj diff --from trunk --to mm --summary > /tmp/mm-before.txt
# ...rewrite...
jj diff --from trunk --to mm --summary | diff /tmp/mm-before.txt -

jj log --no-graph -r mm -T 'parents.map(|p| p.change_id().short()).join("\n")'
```

## Key differences from git

No staging area, and tracking is automatic for *every* change, removals
included. `rm` (or a move/rename) is snapshotted into `@` on the next jj
command — no `git rm`, no `git add -A`. Just delete the file and commit.

## Bookmarks and pushing

```bash
jj bookmark list                           # show all bookmarks
jj bookmark set feature -r <rev>           # move bookmark to revision
jj bookmark track main --remote=origin     # start tracking a remote bookmark
```

A bookmark reported "ahead by at least N, behind by at least N" against its
remote is usually just a rebase, not lost work — compare the tips with
`jj diff --from <remote> --to <local> --stat` before assuming otherwise.

### Advancing bookmarks after commit

`jj bookmark advance` moves the nearest ancestor bookmark(s) forward — the
preferred way to move `main` after committing on top of it.

```bash
jj bookmark advance                  # advance closest bookmarks to @ (default)
jj bookmark advance main --to @-     # advance specific bookmark
```

### Pushing

```bash
jj git push -b <bookmark>                  # push tracked bookmark
jj git push -c <rev>                       # create auto-named bookmark and push
jj git push --named <name>=<rev>           # create named bookmark and push
```

`-b` refuses to push untracked bookmarks ("Refusing to create new remote
bookmark"). `--named` creates, pushes, and auto-tracks in one step — it is
the whole step, not a follow-up to `jj bookmark create`, and errors
"Bookmark already exists" if the name is already local. `-c` derives the name
from the change ID (`push-<short-change-id>`).

**Push a stack bottom-first, or pass `-b <bookmark>` per branch.** A bare
`jj git push` only considers `remote_bookmarks(remote=origin)..@`, so pushing
the *tip* first puts a remote bookmark below the others and drops every
ancestor bookmark out of that revset. The next bare push then reports "No
bookmarks/tags found in the default push revset: Nothing changed" and
silently leaves the lower branch unpushed — it reads like success.

## Restoring files

`jj restore` uses `--from` and `--into`/`--to`, not `-r`:

```bash
jj restore --changes-in @                  # undo all working copy changes
jj restore SOME_FILE                       # restore file from parent
jj restore --from kn --into kn FILE        # restore file in a specific revision
```

**`jj restore FILE` is not "undo my last edit."** It resets the whole file
to the parent, wiping *every* uncommitted change in it, not just the one you
meant to back out. Run `jj diff --git FILE` first to see what would be lost; to
back out one surgical experiment, revert it with the tool that made it.

## Divergent changes

A change is divergent when it has more than one visible commit — usually
because two workspaces rewrote it concurrently. jj labels these
`(divergent)` in the log, and the edits from one side appear to have
vanished. Don't rewrite the missing files; recover them:

```bash
jj log -r 'divergent()'              # find them
jj diff -r <commit> --name-only      # see what each holds
jj restore --from <commit> <paths>   # recover
```

A bare change ID errors once it's divergent, so use the offsets jj suggests
(`abcd/0`, `abcd/1`). Offsets go by recency with the newest at `/0`, so
re-read `jj log` rather than reusing one from earlier in the session — a
concurrent rewrite in another workspace shifts them all down by one. For
`jj abandon`, pass the short commit ID.

Not every duplicate is litter: copies pinned by tags or another
`immutable_heads()` clause can't be abandoned at all.

```bash
jj log -r 'divergent() & ~immutable()'   # the only ones you could touch
```
