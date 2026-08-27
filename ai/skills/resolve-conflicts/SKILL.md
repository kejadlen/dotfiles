---
name: resolve-conflicts
description: Use when resolving jj conflicts after rebase, squash, or merge — handles conflict markers, mergiraf automation, and file-by-file manual resolution, in place with `jj resolve -r` or in an isolated workspace
argument-hint: [change-id]
allowed-tools: [Bash(mkdir -p work), Bash(jj workspace add --name=resolve-* -r * work/resolve-*), Bash(cd work/resolve-*), Bash(jj status), Bash(jj resolve *), Bash(jj diff *), Bash(jj log *), Bash(jj op log *), Bash(jj op show *), Bash(jj squash *), Bash(jj workspace forget resolve-*), Bash(jj workspace update-stale), Bash(rm -rf work/resolve-*)]
---

# Resolve Conflicts

`$ARGUMENTS`

This skill resolves conflicts without disturbing the main workspace's `@` —
in place with `jj resolve -r` where that suffices (step 1a), otherwise in an
isolated workspace (step 1b). Invoke the `jj-workspaces`
skill for the general mechanics referenced below (workspace naming,
`work/` layout, sync behavior); the steps here are the conflict-specific
application of it, using the exact commands `allowed-tools` permits.

## Step 0 — Check where the conflict came from

**"New conflicts appeared in 1 commits" doesn't mean the command you just
ran caused them.** A conflict already sitting in the working copy — usually
from a rebase someone ran in another terminal — gets carried into the new
working copy commit and reported as new. With a fileset, `jj commit` keeps
the named commit clean and leaves the conflict behind in `@`. Check
provenance before resolving anything:

```
jj op log --limit 5                                # find the rebase that introduced it
jj op show <op-id>                                 # commits it marked (conflict)
jj log -r @ -T 'if(conflict, "CONFLICT", "clean")' # which commits are conflicted now
```

## Step 1 — Pick the revision and the mechanism

If `$ARGUMENTS` contains a change ID, use it as the conflicted revision.
Otherwise run `jj status` in the main workspace and use `@-` if it has
conflicts; stop and ask the user for a change ID if it doesn't.

**Anchor on the oldest conflicted commit, not `@-`.** A conflict inherited
through ancestry shows up in every descendant, so `@-` is usually a symptom
rather than the source. `jj status`'s hint names the real one ("start by
creating a commit on top of the first conflicted commit"), and `jj log -r
'conflicts()'` lists the full set. Fix the root and jj rebases the rest —
step 4's squash then reports `Existing conflicts were resolved or abandoned
from N commits`. Resolving at `@-` instead leaves every ancestor conflicted.

**When the conflict is in `@` itself, skip to step 3 and resolve in
place.** A rebase run while the working copy holds uncommitted work leaves
the conflict in `@`, not in a commit. `jj workspace add -r @` can't check
out a revision that's already checked out, and the isolation buys nothing
because there is no other `@` to protect. Edit the files directly and drop
the `-r @-` from every `jj resolve` in the steps below.

**Try `jj resolve -r <rev>` before adding a workspace.** It rewrites the
named revision and rebases descendants in place, so `@` never moves — which
is what a workspace was buying you. That makes it the right default when a
megamerge is checked out and `@` must stay put. A workspace only earns its
cost when resolution needs a real checkout to work in: running the project's
tooling, or hand-editing several files against a build.

Always pass `--tool` explicitly. A bare `jj resolve` launches the
interactive merge editor, which hangs a non-interactive Bash call.

## Step 1a — Resolve in place with `jj resolve -r`

`--tool :ours` and `--tool :theirs` take side #1 and side #2 whole, and they
handle a `2-sided conflict including 1 deletion` that mergiraf can't touch —
one command per file, no checkout:

```
jj resolve -r <rev> --tool :theirs <path>    # side #2 wins; removes the file if that side deleted it
```

Read the sides off the materialized markers first (`jj file show -r <rev>
<path>`) to learn which number is which: the `+++++++ <change-id>` labelled
`(rebased revision)` is your own commit's side.

For a file needing real merge judgment, resolve it as a temp file and hand
that to `cp` as a merge tool — the same in-place rewrite, but with content
you wrote:

```
jj file show -r <rev> <path> > /tmp/fix              # materialized conflict markers
# edit /tmp/fix — remove markers, write the merged content
jj resolve -r <rev> --tool cpfix \
  --config 'merge-tools.cpfix.program=cp' \
  --config 'merge-tools.cpfix.merge-args=["/tmp/fix", "$output"]' \
  <path>
```

Work root-first: each resolution clears that path from every descendant, and
jj reports `Existing conflicts were resolved or abandoned from N commits`.
When no conflicts remain, skip steps 2–4 entirely — there is nothing to
squash, because the revisions were rewritten directly.

**Resolving the root can push a fresh conflict into a downstream
megamerge.** A merge commit whose tree recorded the old resolution goes
`(conflict)` once its parents change, so a clean run at the root can be
followed by `New conflicts appeared in N commits` naming the megamerge. That
conflict is `3-sided` when the merge has three parents, and **no merge tool
can take it** — `:ours`, `:theirs`, and the `cp` trick all fail with "has 3
sides. At most 2 sides are supported." Resolve it by writing the file in the
working copy (the conflict materializes there through ancestry) and then
`jj squash --into <megamerge>`; that clears the megamerge and every
descendant without moving `@` off it.

When taking one side of a 3-sided materialization, don't splice the
`+++++++` block in as-is — its region can overlap content that also appears
after `>>>>>>>`, so a literal copy duplicates lines. Reconstruct the intended
file from `jj file show -r <parent> <path>` for each parent instead.

`cp -p` rather than plain `cp` as the merge-tool program preserves the
executable bit, which matters for any conflict jj labels `including an
executable`.

**Check generated files afterward.** A generated artifact that auto-merged
cleanly is the classic stale-output trap: the text merged, but the generator
would emit something else. Re-run the generator and squash any diff into the
commit that owns it — and run it from the main workspace, never from
`work/`, where repo tooling reading `git ls-files` goes green-but-wrong.

## Step 1b — Set up an isolated resolution workspace

Per `jj-workspaces`' "Creating a Workspace" recipe, but anchored on the
conflicted revision instead of trunk (skip its DAG-placement rebase step —
this workspace's working-copy commit belongs directly on `<change-id>`,
not on trunk):

```
mkdir -p work
jj workspace add --name=resolve-<change-id> -r <change-id> work/resolve-<change-id>
cd work/resolve-<change-id>
```

`-r <change-id>` makes the new workspace's working-copy commit a child of
`<change-id>` — the same relationship `jj new <change-id>` would have
created in the main workspace — but isolated in its own checkout. Run all
remaining steps from inside `work/resolve-<change-id>`.

## Step 2 — Run mergiraf

Attempt automatic resolution with mergiraf, targeting the conflicted parent:

```
jj resolve --tool mergiraf -r @-
```

The `-r @-` flag targets the conflicted parent rather than the working copy.
After it runs, check what's left:

```
jj resolve --list -r @-
```

If the list is empty, all conflicts are resolved — skip to step 4.

## Step 3 — Manual resolution loop

**A type conflict has no markers to edit.** When one side changes a path's
type — a tracked file replaced by a symlink, say — `jj resolve --list` labels
it `2-sided conflict including a symlink`, mergiraf has nothing textual to
merge, and the materialized file is a description rather than content:

```
Conflict:
  Removing file with id 401ff494… (<base> "…" (parents of rebased revision))
  Adding file with id 0f6b69c3… (<side> "…" (rebase destination))
  Adding symlink with id c4563938… (<side> "…" (rebased revision))
```

`jj file show` refuses these with "Path exists but is not a file." Read the
intent from `jj diff --git -r <side> <path>` instead, where the mode change
(`100644` → `120000`) and the symlink target both appear, then recreate the
winning side by hand — `rm <path> && ln -s <target> <path>`. The Edit tool
cannot write a symlink.

For each text file still listed by `jj resolve --list -r @-`:

1. Read the file to see its conflict markers. jj's format differs from
   git's, and jj has two marker styles. The default (`diff`) shows one
   side as a diff against the base:

   ```
   <<<<<<< conflict 1 of 1
   %%%%%%% diff from: <base commit>
   \\\\\\\        to: <side #1 commit>
   -base line
   +side #1 line
   +++++++ <side #2 commit>
   side #2 content
   >>>>>>> conflict 1 of 1 ends
   ```

   The `%%%%%%%` block is a diff (`-` base, `+` side) turning the base
   into one side; the `+++++++` block is the other side's full content.
   Apply the diff mentally or take one side, then delete every marker line
   (`<<<`, `%%%`, `\\\`, `+++`, `>>>`).

   The `snapshot` style (set via `ui.conflict-marker-style`) instead shows
   every side and the base in full:

   ```
   <<<<<<< conflict 1 of 1
   +++++++ <side #1 commit>
   side #1 content
   ------- <base commit>
   base content
   +++++++ <side #2 commit>
   side #2 content
   >>>>>>> conflict 1 of 1 ends
   ```

   Here the `+++++++` sections are the sides and `-------` is the common
   ancestor. Either way, remove all marker lines and keep the correct
   merged content. Each label carries the commit's change ID and
   description, which orients which side is which.

   jj also emits a **diff-style** form where only one side is literal
   content and the other is a diff from the base:

   ```
   <<<<<<< conflict 1 of 1
   +++++++ yuwoklmp 1056139b "mm" (rebase destination)
   (full content of this side)
   %%%%%%% diff from: yuwoklmp 80b2d213 "mm" (parents of rebased revision)
   \\\\\\\        to: omkzmwrk cc06fc10 (rebased revision)
   -(lines the other side removed from the base)
   +(lines the other side added)
   >>>>>>> conflict 1 of 1 ends
   ```

   The `%%%%%%%` section is **not** file content — deleting its markers
   would splice `-`/`+` prefixes into the file. Reconstruct each side with
   `jj file show -r <rev> <path>` (the revisions are named in the marker
   lines) and compare those instead of editing the hunks in place.

2. Run `jj diff -r @-` for context on what each side was trying to
   accomplish.

3. Use the Edit tool to resolve the conflict — remove the markers and
   write the correct merged content.

4. Move to the next conflicted file.

After editing all files, run `jj resolve --list -r @-` to confirm no
conflicts remain in the parent.

> The Read and Edit tools handle file-level resolution directly. They are not
> restricted by `allowed-tools`, which only governs Bash commands.

## Step 4 — Squash the resolution and clean up

Do not run `jj squash` automatically. Prompt the user:

> All conflicts are resolved. Run `jj squash` (from
> `work/resolve-<change-id>`) to fold the resolution back into
> `<change-id>`, or review the diff first with `jj diff`.

Once the user confirms the squash, `<change-id>` is fixed up and the
workspace's working-copy commit is left empty. Clean up per
`jj-workspaces`' cleanup recipe:

```
jj workspace forget resolve-<change-id>
rm -rf work/resolve-<change-id>
```

Then, from the main workspace, sync so it sees the resolved change:

```
jj workspace update-stale
```

---

> **Self-improving note:** This is a self-improving skill. If you used it and
> it came up short — a new conflict marker format, an edge case with mergiraf,
> a better resolution pattern — invoke the `self-improving-skills` skill and
> follow it before you finish.
