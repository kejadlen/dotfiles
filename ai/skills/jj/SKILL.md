---
name: jj
description: Use when running any jj (Jujutsu) version control command — committing, describing, bookmarks, rebase, squash, restore, push, or inspecting log/diff/status — and when looking up jj syntax, flags, or behavior. Invoke before free-handing jj commands from memory.
---

# Jujutsu (jj) Version Control

Never treat this skill as authoritative. Run `jj <command> --help` to verify
behavior, flags, and current options.

## Core Workflow

### commit vs. describe vs. new

The working copy `@` is always a real commit; edits stream into it live.
These three verbs differ only in whether they set a message and whether
they move `@`:

| Command | Sets message? | Moves `@`? | Use for |
|---|---|---|---|
| `jj describe [-m]` | yes, on target (default `@`) | no | name or rewrite a commit's message in place |
| `jj new <rev>` | no | yes, to a new empty commit | start fresh work on top of `<rev>` |
| `jj commit -m` | yes, on `@` | yes, to a new empty commit | finish `@` and move on — `describe @` + `new` in one step |

**Prefer `jj commit` over `jj squash`.** Create new commits by default —
even for refactors, cleanups, or small follow-ups. Only squash when the
prior commit specifically needs fixing up (e.g., correcting a bug it
introduced, fixing a typo in code it added).

### Splitting a commit

`jj split -r <rev> -m 'message' <paths>` extracts the named paths
non-interactively; `-m` is what keeps it out of `$EDITOR` when `<rev>`
already has a description.

By default the *selected* paths keep the original change ID and the
remainder becomes a new child commit. To keep the original change's ID and
description where they are and make the extracted paths the new commit,
pass the same revision to both `-r` and `-A`:

```bash
jj split -r abcd -A abcd -m 'scope: message' path/to/file
```

Splitting an ancestor rebases every descendant, `@` included — content is
preserved but commit IDs change, so it isn't an option when a commit ID
has to stay put.

## Landing a Follow-up Change

**Never rewrite an existing commit with `jj edit`.** `jj edit` moves `@`
onto that commit and streams later edits straight into it, which is easy
to forget and rewrites history in place. Make the fix in a new commit,
then route it to where it belongs:

- `jj absorb` splits the new change hunk by hunk and moves each to the
  closest mutable ancestor that last touched those lines. It abandons the
  source commit when every hunk lands and the source has no description;
  hunks it can't place unambiguously stay put, so re-check `jj st` after.
- `jj squash --into <rev> <fileset>` folds specific paths into one target
  commit (see the squash pitfalls below for the `-u`/`-m` requirement).
- `jj rebase` inserts the new commit as its own commit elsewhere.
- Leaving it alone is fine when the change stands on its own.

```bash
jj absorb                            # distribute every hunk to its ancestor
jj absorb <fileset>                  # only these paths
jj absorb --into <rev>               # limit destinations to <rev> and ancestors
```

## Megamerges

A megamerge is a single working commit that merges several parallel
branches at once (often bookmarked `mm`), giving one working copy that
integrates all of them. Moving `@` off it — `jj new` or `jj edit` onto
another commit — discards that combined view, and rebuilding it means
re-running the merge by hand. Stay on the megamerge unless explicitly
told to move; land new work with `jj absorb` or `jj squash --into` so `@`
stays put. The `jj-workspaces` skill uses `mm` when placing workspaces in
the DAG.

## Key Differences from Git

No staging area — working copy edits map straight to `@`, and tracking is
automatic for *every* change, removals included. Deleting a file with `rm`
(or moving/renaming it) is already snapshotted into `@` on the next jj
command — there is no `git rm`, no `git add -A`, and no "untrack" step.
Just delete the file and commit.

## Bookmarks and Pushing

Bookmarks are mutable named pointers to commits (like git branches).
Use `jj new <bookmark>` to start working on top of one.

```bash
jj bookmark list                           # show all bookmarks
jj bookmark set feature -r <rev>           # move bookmark to revision
jj bookmark track main --remote=origin     # start tracking a remote bookmark
```

### Advancing bookmarks after commit

`jj bookmark advance` moves the nearest ancestor bookmark(s) forward to a
target revision — the preferred way to move `main` after committing on top
of it.

```bash
jj bookmark advance                  # advance closest bookmarks to @ (default)
jj bookmark advance --to @-          # advance closest bookmarks to @-
jj bookmark advance main --to @-     # advance specific bookmark
```

After `jj commit`, the working copy `@` is empty so `jj bookmark advance`
with no args works — the bookmark is an ancestor of `@`.

### Pushing

```bash
jj git push -b <bookmark>                  # push tracked bookmark
jj git push -c <rev>                       # create auto-named bookmark and push
jj git push --named <name>=<rev>           # create named bookmark and push
```

`-b` refuses to push untracked bookmarks ("Refusing to create new remote
bookmark"). Use `--named` to create, push, and auto-track in one step.
`-c` generates a bookmark name from the change ID (`push-<short-change-id>`).

`--named` is the whole step, not a follow-up to `jj bookmark create` — it
errors "Bookmark already exists" if the name exists locally, so don't run
`create` first.

## Restoring Files

`jj restore` uses `--from` and `--into`/`--to`, not `-r`:

```bash
jj restore --changes-in @                  # undo all working copy changes
jj restore SOME_FILE                       # restore file from parent
jj restore --from kn --into kn FILE        # restore file in a specific revision
```

**`jj restore FILE` is not "undo my last edit."** It resets the whole
file to the parent revision, wiping *every* uncommitted change in it —
not just the one you meant to back out. Backing out a temporary sed
this way also destroyed unrelated in-progress work in the same file.
Before restoring, run `jj diff FILE` to see everything that would be
lost; to back out one surgical experiment, revert it with the same
tool that made it (another sed/edit) instead of `jj restore`.

## Divergent Changes

A change is divergent when it has more than one visible commit — most often
because two workspaces rewrote it concurrently. jj labels these
`(divergent)` in the log, and the edits from one side appear to have
vanished. Don't rewrite the missing files; recover them:

```bash
jj log -r 'divergent()'              # find them
jj diff -r <commit> --name-only      # see what each holds
jj restore --from <commit> <paths>   # recover
```

A bare change ID errors once it's divergent, so use the change offsets jj
suggests (`abcd/0`, `abcd/1`) to inspect them. Offsets are assigned by
recency, with the most recent commit at `/0`, so re-read `jj log` rather
than reusing an offset from earlier in a session — a concurrent rewrite in
another workspace shifts them all down by one. For `jj abandon`, pass the
short commit ID, as jj's own hint recommends.

## Common Pitfalls

**Avoid revset functions with parentheses.** Claude Code's shell
command parser treats `()` as subshell syntax even when quoted, which
triggers permission prompts. Use the underlying value directly:

```bash
jj log -r trunk                      # correct — paren-free alias
jj log -r 'trunk()'                  # WRONG — triggers permission prompt
```

`trunk` is a config alias for `trunk()`, so it stays correct per repo.
Don't substitute a hardcoded bookmark: `trunk()` is itself an alias and
resolves differently across repos — of the 20 that override it here, four
point at something other than `main@origin` (`mm@origin`, `master@origin`).
`jj config get revset-aliases."trunk()"` shows the current repo's value.

**`jj show` does not accept path arguments.** It takes an optional revision
but cannot be scoped to a path. Use `jj diff` instead:

```bash
jj diff -r @-                        # all changes in parent revision
jj diff -r @- path/to/file           # specific file in parent revision
```

**`--no-patch` can't combine with `--summary`/`--stat`/`--name-only`.**
Those flags already suppress the full patch, so adding `--no-patch`
errors out ("cannot be used with"). To see just the changed files, use
`--summary` alone:

```bash
jj show -r @- --summary              # description + file list, no patch
```

**Fileset expressions with special characters need quoting.** Fileset
operators (`,` `~` `|` `&` `()`) in a bare path are parsed as syntax, not
literal characters, so a path like `bin/,z` fails with "Failed to parse
fileset: Syntax error". Wrap the path in a double-quoted string literal —
the shell needs single quotes around it so jj sees the double quotes:

```bash
jj commit -m '...' '".config/foo"' '"bin/,z"'   # literal path with a comma
```

For glob patterns, use `glob:"pattern"` the same way:

```bash
jj diff -- 'glob:"bin/*" ~ glob:"bin/,special"'
```

**There is no `--cwd` flag.** To target a repo without `cd`ing into it,
use `-R <path>` (short for `--repository`):

```bash
jj log -R /path/to/repo -r main    # correct
jj log --cwd /path/to/repo         # WRONG — no such flag; fails silently
                                    # if stderr is redirected (e.g. `2>/dev/null`)
```

**`jj op undo` has been removed (v0.39+).** Use `jj op revert` or
`jj undo`/`jj redo`.

**Put `-m` before `--` or fileset args.** jj parses everything after `--` as
fileset, so `-m` placed after `--` becomes a parse error.

**`jj squash` takes its source from `@` unless you pass `--from`.** Naming
only `--into <rev>` and a fileset moves that fileset out of `@`, not out of
the commit you were reading about. When `@` has moved since you last ran
`jj log` — the human committing in another terminal is enough — the squash
moves nothing, yet still prints "Rebased N descendant commits" and gives the
destination a new commit ID, so a no-op looks like it worked. Name the source
and re-check `jj st` immediately before any rewrite:

```bash
jj squash --from <rev> --into <rev> -u FILE   # explicit source
```

**`--from` is repeatable, so collapsing several commits is one rewrite.**
Each `--from` takes a revset and the sources need not be adjacent —
commits in between are rebased, not folded in. Pair it with `-m`, since
abandoning several described sources otherwise opens the editor:

```bash
jj squash --from <rev> --from <rev> --into <rev> -m 'combined message'
```

**`jj squash` opens `$EDITOR` to merge descriptions and hangs in
non-interactive shells.** When source and destination both have
descriptions, jj launches the editor to combine them — Claude Code's
Bash tool has no TTY, so the command appears to hang silently and
nothing changes. Always pass one of:

```bash
jj squash --use-destination-message   # discard source description
jj squash -u                          # short form
jj squash -m 'new message'            # inline replacement
```

The same applies to `jj squash --from X --into Y`. If you actually want
to merge the two descriptions, do it from a real terminal.

**"New conflicts appeared in 1 commits" doesn't mean your commit caused
them.** A conflict already sitting in the working copy — usually from a
rebase someone ran in another terminal — gets carried into the new working
copy commit and reported as new. With a fileset, `jj commit` keeps the named
commit clean and leaves the conflict behind in `@`. Check provenance before
resolving anything:

```bash
jj op log --limit 5                                # find the rebase that introduced it
jj op show <op-id>                                 # commits it marked (conflict)
jj log -r @ -T 'if(conflict, "CONFLICT", "clean")' # which commits are conflicted now
```
