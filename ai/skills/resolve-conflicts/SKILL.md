---
name: resolve-conflicts
description: Use when resolving jj conflicts after rebase, squash, or merge — handles conflict markers, mergiraf automation, and file-by-file manual resolution
argument-hint: [change-id]
allowed-tools: [Bash(jj new *), Bash(jj status *), Bash(jj resolve *), Bash(jj diff *), Bash(jj log *)]
---

# Resolve Conflicts

`$ARGUMENTS`

## Step 1 — Set up the resolution change

If `$ARGUMENTS` contains a change ID, create a new change on top of it:

```
jj new $ARGUMENTS
```

If no argument was given, run `jj status` to verify:

- The current change `@` is empty (no pending edits)
- The parent `@-` has conflicts

If `@` is not empty, stop and tell the user to `jj new` first.

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

## Step 4 — Squash the resolution

Do not run `jj squash` automatically. Prompt the user:

> All conflicts are resolved. Run `jj squash` to fold the resolution back
> into the conflicted change, or review the diff first with `jj diff`.

---

> **Self-improving note:** If you discover new conflict marker formats, edge
> cases with mergiraf, or better resolution patterns, update this skill using
> the `self-improving-skills` skill.
