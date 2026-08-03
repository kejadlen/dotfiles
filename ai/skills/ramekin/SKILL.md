---
name: ramekin
description: Use when working inside a ramekin container — proposing agent config or skill changes via the outbox, handling read-only config mounts, persisting dependencies across sessions, or debugging ephemeral-filesystem and bind-mount issues.
---

# Ramekin containers

Ramekin runs Claude Code sessions inside Docker containers. The project
workspace is bind-mounted (the container starts there); agent config
(`~/.claude`: memory files, `skills/`, settings) is mounted read-only.

*This is a self-improving skill. If you used it and it came up short — a
missing command, path, gotcha, or workflow — invoke the
`self-improving-skills` skill and follow it before you finish.*

## Proposing config changes (the outbox)

Editing anything under the read-only config mount fails. To propose a
change instead:

1. Write the **complete updated file** (not a diff) into
   `/root/.ramekin/outbox/`, mirroring its layout relative to the
   config directory. Examples:
   - `~/.claude/skills/jj/SKILL.md` → `/root/.ramekin/outbox/skills/jj/SKILL.md`
   - a new skill → `/root/.ramekin/outbox/skills/<name>/SKILL.md`
2. Tell the user what you proposed and why. They review and apply on
   the host with `ramekin outbox`.

New files (e.g., a skill that doesn't exist yet) go through the same
path — the outbox is for creations as well as edits.

## Reviewing proposals on the host

```bash
ramekin outbox list                       # pending proposals across all repos
ramekin outbox diff                       # each proposal against its host baseline
ramekin outbox apply <slug>/<session>/<path>
ramekin outbox discard <slug>/<session>[/<path>]   # one proposal or a whole session
```

`apply` copies the proposal **over** the host file, so it discards
anything the host gained since the container mounted its baseline —
proposals sit in the outbox indefinitely and go stale. Read
`ramekin outbox diff` first: when the host has moved on, hand-merge the
proposal's idea instead of applying it, then `discard`.

Check where the host path actually leads before applying. Paths under
`~/.claude` are often symlinks into a dotfiles or gists repo, so
`readlink -f` first — the file you are about to overwrite may live in a
different repo than the one you are standing in, and its working copy
may hold uncommitted work.

## Ephemeral filesystem

Only the workspace bind mount survives the session. Everything else is
lost, so:

- `apt-get install` does not persist — add permanent dependencies to a
  custom `.ramekin/Dockerfile` instead.
- Toolchains installed at runtime (rustup, uv, …) need reinstalling
  each session, or a Dockerfile entry. Check `~/.cargo/bin` and the
  like before reinstalling — sometimes they survive within a host
  session.

## Bind-mount gotchas

The workspace is a host bind mount: the **host** can run out of disk
while `df` inside the container shows plenty free on the overlay.
Symptom: writes to the workspace fail mysteriously. Keep build
artifacts on the container side — e.g.
`CARGO_TARGET_DIR=/tmp/<something>` — which also speeds up builds.
