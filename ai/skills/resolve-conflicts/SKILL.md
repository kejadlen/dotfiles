---
name: resolve-conflicts
description: Use when resolving jj conflicts after rebase, squash, or merge — handles conflict markers, mergiraf automation, and file-by-file manual resolution in an isolated workspace
argument-hint: [change-id]
allowed-tools: [Bash(mkdir -p work), Bash(jj workspace add --name=resolve-* -r * work/resolve-*), Bash(cd work/resolve-*), Bash(jj status), Bash(jj resolve *), Bash(jj diff *), Bash(jj log *), Bash(jj op log *), Bash(jj op show *), Bash(jj squash *), Bash(jj workspace forget resolve-*), Bash(jj workspace update-stale), Bash(rm -rf work/resolve-*)]
---

# Resolve Conflicts

`$ARGUMENTS`

This skill resolves conflicts in an isolated workspace so the resolution
work never touches the main workspace's `@`. Invoke the `jj-workspaces`
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

## Step 1 — Set up an isolated resolution workspace

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

> **Self-improving note:** If you discover new conflict marker formats, edge
> cases with mergiraf, or better resolution patterns, update this skill using
> the `self-improving-skills` skill.
