---
name: resolve-conflicts
description: Use when resolving jj conflicts after rebase, squash, or merge — handles conflict markers, mergiraf automation, and file-by-file manual resolution in an isolated workspace
argument-hint: [change-id]
allowed-tools: [Bash(mkdir -p work), Bash(jj workspace add --name=resolve-* -r * work/resolve-*), Bash(cd work/resolve-*), Bash(jj status), Bash(jj resolve *), Bash(jj diff *), Bash(jj log *), Bash(jj squash *), Bash(jj workspace forget resolve-*), Bash(jj workspace update-stale), Bash(rm -rf work/resolve-*)]
---

# Resolve Conflicts

`$ARGUMENTS`

This skill resolves conflicts in an isolated workspace so the resolution
work never touches the main workspace's `@`. Invoke the `jj-workspaces`
skill for the general mechanics referenced below (workspace naming,
`work/` layout, sync behavior); the steps here are the conflict-specific
application of it, using the exact commands `allowed-tools` permits.

## Step 1 — Set up an isolated resolution workspace

If `$ARGUMENTS` contains a change ID, use it as the conflicted revision.
Otherwise run `jj status` in the main workspace and use `@-` if it has
conflicts; stop and ask the user for a change ID if it doesn't.

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

For each file still listed by `jj resolve --list -r @-`:

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
