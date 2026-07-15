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

1. Read the file to see its conflict markers. jj uses a different format
   than git:

   ```
   <<<<<<< Conflict N of M
   +++++++ Contents of side #1
   (lines added on one side)
   ------- Contents of base
   (lines from the common ancestor)
   +++++++ Contents of side #2
   (lines added on the other side)
   >>>>>>> Conflict N of M ends
   ```

   The `+++++++` sections are the two sides being merged. The `-------`
   section is the common ancestor. Remove all marker lines and keep the
   correct final content.

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
