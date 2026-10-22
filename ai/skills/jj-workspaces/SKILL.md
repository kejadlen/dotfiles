---
name: jj-workspaces
user-invocable: false
description: Use when needing isolated workspace for experiments, parallel development, or subagent coordination - covers creating, placing, finalizing, and removing jj workspaces, alone or alongside other agents
---

# jj Workspaces

A workspace is a second working copy attached to the same repo, with its
own working-copy commit, named `<name>@` from any workspace. All
workspaces share history, so comparing or combining their work needs no
extra setup.

jj only snapshots a working copy when a command runs in it, so run `jj st`
after a batch of edits.

Put workspaces under `work/` at the repo root. The global git ignore
excludes `/work`, so they never show up as untracked files. Name them in
lowercase, prefixed with the ticket ID when the work is tracked
(`abc-123-auth-feature`, `async-refactor`).

## Create

`-r` sets the new working-copy commit's parents, so the workspace starts
on trunk, or on whatever `<rev>` the work belongs on:

```bash
mkdir -p work
jj workspace add --name=<name> -r trunk work/<name>
```

With a megamerge, also add the workspace as a parent of `mm`:

```bash
jj rebase -s mm -o 'mm- | <name>@'
```

Rebase `mm` rather than the workspace. Moving `<name>@` from the main
workspace leaves `<name>` stale, and edits written there before jj next
runs in it come out divergent.

## Finalize

From inside the workspace:

```bash
jj split -m '<description>' .
```

This moves every change into a new commit beneath the working-copy
commit, which is left empty. Use it instead of `jj commit` when the
workspace sits under `mm`: the working-copy commit is one of the
megamerge's parents, and `jj commit` would start a new one on top of it,
outside `mm`, so follow-up edits (review fixes, a retry) would miss the
megamerge. After `split`, the working copy stays wired into `mm`.

## Inspect

From any workspace:

```bash
jj log -r 'working_copies()'
jj diff -r <name>@-                              # finalized work
jj diff --from approach-a@- --to approach-b@-
```

## Remove

From the main workspace:

```bash
jj workspace remove <name>
jj abandon 'empty() & description(exact:"") & ~working_copies() & ~merges() & mutable()'
```

`jj workspace remove` snapshots the working copy, forgets the workspace,
and deletes its directory; `jj workspace forget` only forgets. The
`abandon` drops the empty commit `split` left under `mm`. Without a
megamerge, `remove` discards it on its own. Don't use `jj sweep` here: it
also abandons other workspaces' empty working copies and unwires them
from `mm`.

Finalized work survives removal. To throw a workspace away instead, run
`jj restore` inside it (and abandon any commits it finalized), then
remove it as above and run `jj simplify-parents -r mm`: the abandoned
commit's parent was trunk, which `mm` inherits as a redundant parent.
Don't abandon `<name>@` before removing it, since that leaves the
workspace stale and `remove` refuses it.

## Sharing the repo with other agents

Create every workspace before dispatching anyone, and give each
agent exactly one workspace path to `cd` into first, since jj resolves
the repo from the current directory. Each agent edits and finalizes only
its own workspace. Creating, placing, removing, and pushing stay with
whoever dispatched them, after reviewing the work.

## Gotchas

| Symptom | Cause and fix |
|---------|---------------|
| Files written in one workspace vanish | A concurrent rewrite left the change divergent. See the `jj` skill's Divergent changes section; recover, don't rewrite |
| mise errors "Config files ... are not trusted" | The new workspace's `mise.toml` is a new path. Ask the user to run `mise trust <workspace>/mise.toml` |
| Conflicts after another workspace's rewrite | Expected. Resolve them with the `resolve-conflicts` skill |

## References

- [jj-workspace-experiments](https://github.com/thoughtpolice/a/blob/canon/.claude/skills/jj-workspace-experiments/SKILL.md) - Original source for workspace patterns
