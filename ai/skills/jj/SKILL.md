---
name: jj
description: Use when running any jj (Jujutsu) version control command — committing, describing, bookmarks, rebase, squash, restore, push, or inspecting log/diff/status — and when looking up jj syntax, flags, or behavior. Invoke before free-handing jj commands from memory.
---

# Jujutsu (jj) version control

Verify behavior and flags against `jj <command> --help`, and read
`pitfalls.md` before reaching for `squash`, `diff`, `show`, `file show`,
`config get`, `tag`, `op`, filesets, `-R`, or a revset with parentheses — it
catalogues flags that fail silently, hang without a TTY, or make a no-op look
like it worked.

*This is a self-improving skill. If you used it and it came up short — a missing command, flag, gotcha, or workflow — invoke the `self-improving-skills` skill and follow it before you finish.*

Flags below are verified against jj 0.45.1 unless a line names another
version.

## Naming revisions

**Re-read `jj log` before reusing an ID from earlier in the session.** Any
rewrite — yours, another workspace's, or the human's in another terminal —
gives commits new IDs and can abandon a change outright. "Revision `abcd`
doesn't exist" means the ID went stale far more often than it means you
mistyped it, and it is the most common jj failure there is: re-derive the ID
rather than hunting for the typo.

- Prefer change IDs, a bookmark, or `@`-relative expressions, which resolve
  fresh. A bare commit-ID prefix is both stale-prone and ambiguous.
- `-r main` fails when the repo has no *local* `main` — a clone often has only
  `main@origin`, and jj's hint lists what does exist. `trunk` is the
  paren-free alias to reach for, but it resolves out of config rather than
  being fixed: `jj config get 'revset-aliases."trunk()"'` when the repo's
  answer matters.
- A divergent change ID errors on its own; jj prints the offsets to use.

## Core workflow

### commit vs. describe vs. new

The working copy `@` is always a real commit; edits stream into it live.
There is no staging area, and tracking covers removals — `rm`, moves, and
renames are snapshotted into `@` on the next jj command. No `git rm`, no
`git add -A`; delete the file and commit.

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

## Rebase

Which commits move is set by exactly one of `-b`/`-s`/`-r`; where they land by
exactly one of `-o`/`-A`/`-B`:

| Flag | Selects |
|---|---|
| `-b, --branch` | the whole branch relative to the destination's ancestors — jj's own gloss is that `-b=br -o=dst` equals `-s=roots(dst..br) -o=dst`. The default when none of the three is given is `-b @` |
| `-s, --source` | the revset and all its descendants |
| `-r, --revision` | just the revset, re-parenting its descendants onto its former parents |
| `-o, --onto` | new parent; repeatable, so `-o p1 -o p2` makes a merge (`-d` is the older alias) |
| `-A, --insert-after` / `-B, --insert-before` | splice into the DAG at a position, rewriting neighbours |

Also useful: `--skip-emptied` drops commits a rebase makes empty,
`--keep-divergent` stops jj abandoning a copy, `--simplify-parents` prunes
redundant edges from a merge.

**`--ignore-immutable` is a global flag, not a rebase one** — it works on
`rebase`, `bookmark set`, `git push`, and every other rewriting command, so
"Commit `<id>` is immutable" has the same override everywhere. `-b` hits it
most, because a branch reaches further back than you meant. Check what the
revset actually covers before overriding; immutability usually means you
selected too much, not that it's in the way.

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

The `jj stack` alias does this for a whole branch rather than one commit,
defaulting to `mm+::@-` — everything between the merge and `@`. Read it with
`jj config get aliases.stack`; `jj stack --help` doesn't work, because the
alias shells out and the flag lands on the wrapped `jj rebase` as an empty
`--revisions`.

Don't read the result off the ASCII graph. Diff the merge as an invariant
across the rewrite, and list its parents explicitly:

```bash
jj diff --from trunk --to mm --summary > /tmp/mm-before.txt
# ...rewrite...
jj diff --from trunk --to mm --summary | diff /tmp/mm-before.txt -

jj log --no-graph -r mm -T 'parents.map(|p| p.change_id().short()).join("\n")'
```

## Bookmarks and pushing

```bash
jj bookmark list                           # show all bookmarks
jj bookmark set feature -r <rev>           # move bookmark to revision
jj bookmark track main --remote=origin     # start tracking a remote bookmark
```

`jj bookmark set` refuses to move a bookmark backwards or sideways
(`-B`/`--allow-backwards` overrides). That guard fires on the ordinary case of
resetting a local bookmark onto its remote after a rewrite, so
`jj bookmark set main -r main@origin` needs the flag; it is only a real
warning when you didn't expect the target to be behind.

A bookmark reported "ahead by at least N, behind by at least N" against its
remote is usually just a rebase, not lost work — compare the tips with
`jj diff --from <remote> --to <local> --stat` before assuming otherwise.

A bookmark name that resolves to more than one commit errors `Name <x> is
conflicted`; jj prints the commit IDs to disambiguate with.

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

One decision, on whether the name already exists locally. Check with
`jj bookmark list` if you don't know:

| Local bookmark | Command |
|---|---|
| doesn't exist yet | `jj git push --named <name>=<rev>` — creates, pushes, tracks |
| already exists | `jj git push -b <name>` — pushes, tracks if untracked |

So `jj bookmark create <name>` followed by `jj git push --named <name>=<rev>`
is always wrong: the create makes the name local, and `--named` then errors
"Bookmark already exists". Pick one or the other, not both.

There is no `--allow-new` on 0.45 — reaching for it is a git habit. 0.45
auto-tracks on `-b` instead ("If a bookmark isn't tracking anything yet, the
remote bookmark will be tracked automatically"); older versions refused with
"Refusing to create new remote bookmark", which is the error `--allow-new`
looks like it would fix.

`-c` derives the name from the change ID (`push-<short-change-id>`).
`jj git push --dry-run` exists and is cheap; `jj absorb --dry-run` does not.

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
jj restore --changes-in kn FILE            # restore file in a specific revision
```

`--from` and `--into` are a source and a destination, so naming the same
revision for both restores a file from itself and prints "Nothing changed."
To back a file out inside one commit, use `--changes-in <rev>`.

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
jj log -r 'change_id(abcd)'          # list every copy of the change
jj diff -r <commit> --name-only      # see what each holds
jj restore --from <commit> <paths>   # recover
```

There is no `divergent()` revset — on jj 0.37 it fails with "Function
`divergent` doesn't exist" and suggests `merges`. Find the copies through
`change_id(<id>)`, or spot them by the `(divergent)` label in `jj log`.

A bare change ID errors once it's divergent, so use the offsets jj suggests
(`abcd/0`, `abcd/1`). Offsets go by recency with the newest at `/0`, so
re-read `jj log` rather than reusing one from earlier in the session — a
concurrent rewrite in another workspace shifts them all down by one. For
`jj abandon`, pass the short commit ID.

Not every duplicate is litter: copies pinned by tags or another
`immutable_heads()` clause can't be abandoned at all, so filter with
`jj log -r 'change_id(abcd) & ~immutable()'` to see the ones you could touch.
`jj abandon` on an already-hidden copy reports "Skipping 1 revisions that are
already hidden. No revisions to abandon." — that is success, not a failure.
