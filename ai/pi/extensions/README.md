# Agent State

Reports the session's blocked/working/idle state to `,agent-state`, so
pi sessions appear in the `,agents` picker (prefix+A) and the sketchybar
agents item alongside Claude Code ones.

## How it works

Maps pi lifecycle events to states, following the design of herdr's
bundled pi integration:

| Event | State |
|-------|-------|
| `agent_start` | working |
| `agent_settled` (when actually idle) | idle, "turn finished" |
| `session_start` | republish current state (reload-safe) |
| `session_shutdown` | clear the pane's row |

Active only in TUI mode inside tmux — RPC/JSON/print modes are headless,
and the tmux pane is the row's identity. Writes go through a serial
fire-and-forget queue to `~/.dotfiles/ai/bin/,agent-state`, then poke
sketchybar to redraw.

## Blocked state

pi has no built-in permission prompt, so `permission-gate.ts` emits
`agent-state:blocked` events on the shared extension event bus around its
dialogs, and this extension records `blocked` for their duration.

# Permission Gate

Requires explicit user confirmation before every tool call, with
declarative allowlists for commands that can run without prompting.

## How It Works

**Read tool** — auto-allowed for files tracked by `jj`, files in skills
directories, and pi documentation.

**Bash tool** — auto-allowed only if the command matches the allowlist
and contains no shell chaining (`|`, `&&`, `;`, `` ` ``, `$()`).

Everything else prompts for confirmation.

## Base Allowlist

The `BASE_COMMANDS` tree in `permission-gate.ts` defines the global
allowlist. Each entry maps a command to a rule:

```ts
const BASE_COMMANDS: CommandRule = {
  jj: ["diff", "log", "show", "status"],
};
```

### Rule Types

| Rule | Meaning | Example |
|------|---------|---------|
| `true` | Allow with any arguments | `ls: true` |
| `string[]` | Allow only these subcommands | `jj: ["diff", "log"]` |
| `{ ... }` | Recurse into subcommands | `gh: { pr: ["list", "view"] }` |
| `(args) => boolean` | Custom predicate | `rake: (a) => a.startsWith("-T")` |

Rules are recursive — arrays and objects can nest to any depth:

```ts
{
  gh: {
    pr:    ["list", "view", "checks"],
    issue: { list: true, view: true },
    repo:  true,                        // all repo subcommands
  },
}
```

`gh pr list --author me` walks `gh` → `pr` → `list` → `true` → allowed.
`gh pr create` walks `gh` → `pr` → `create` → undefined → prompted.

## Per-Project Overrides

Projects can extend the allowlist by placing a `.pi/permissions.json`
in the project root (next to `.pi/`):

```json
{
  "allow": {
    "cargo": ["test", "check", "clippy"],
    "make": ["test", "lint"],
    "docker": {
      "compose": ["up", "down", "ps"]
    }
  }
}
```

### Trust Model

Project overrides are **not trusted automatically**. On the first tool
call of a session (or when the file changes), the user sees a
confirmation prompt:

```
Project wants to auto-allow:
  cargo test
  cargo check
  cargo clippy
  make test
  make lint
  docker compose up
  docker compose down
  docker compose ps

Allow? [y/n]
```

Approvals are persisted in `~/.pi/agent/approved-permissions.json`,
keyed by project directory and a SHA-256 hash of the file content.
If `.pi/permissions.json` is modified, the hash won't match and the
user is re-prompted.

### Merge Behavior

Project rules are **additive only** — they are deep-merged with the
base allowlist. A project cannot narrow or remove base permissions.
If the base already grants `true` at some node, the project's rules
for that node are ignored (it's already fully allowed).

### JSON-Only

Project permissions use `JsonCommandRule`, which supports `true`,
`string[]`, and nested objects — but not function predicates (since
the file is JSON). Predicates are only available in `BASE_COMMANDS`.

### Non-Interactive Mode

If pi is running without a UI (e.g., RPC or print mode), project
permissions that haven't been previously approved are silently skipped.
