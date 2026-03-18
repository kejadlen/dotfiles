# Agent Guide

## Repository Overview

This is a macOS dotfiles repo managed with [jj](https://martinvonz.github.io/jj/) (not git). The repo lives at `~/.dotfiles` (synced via Syncthing to `~/sync/dotfiles`). Config files are symlinked into `$HOME` by [frork](https://git.kejadlen.dev/alpha/flork), a Fennel-based config management tool — see `frork/` for the manifests (especially `_dotfiles.fnl` for the symlink declarations).

Key directories:

- `.config/` — app configs (aerospace, ghostty, nvim, jj, etc.)
- `.hammerspoon/` — Hammerspoon config in Fennel (`.fnl` files compiled to Lua)
- `.claude/` — Claude Code settings
- `.pi/` — pi agent settings and extensions
- `.ssh/` — SSH config
- `.zsh/` — Zsh config
- `src/` — git submodules (Alfred workflows, fzf-git, tpm)
- `Brewfile` — Homebrew dependencies

## Version Control

This repo uses **jj**, not git. Use `jj` commands for all VCS operations:

- `jj status` / `jj diff` / `jj log` — inspect state
- `jj describe -m "message"` — set change description
- `jj new` — start a new change
- `jj bookmark set <name>` — set a bookmark (jj's equivalent of branches)

Main branch: `main`. Don't commit directly to `main` — work on the `@` change or create new ones.

## Issue Tracker

Issues are on Gitea at `git.kejadlen.dev`. Use the `tea` CLI:

```bash
tea issues list -r alpha/dotfiles -l git.kejadlen.dev
tea issues create -r alpha/dotfiles -l git.kejadlen.dev -t "Title" -d "Description"
tea comment -r alpha/dotfiles -l git.kejadlen.dev <index> "Comment body"
```

## Conventions

- **Hammerspoon**: Config is written in Fennel, not Lua. `init.lua` bootstraps Fennel; all logic lives in `.fnl` files.
- **Shell**: Zsh with [zsh4humans](https://github.com/romkatv/zsh4humans) (z4h). Main config in `.zshrc`, additional sourced files in `.config/zsh/`.
- **No secrets in repo**: API keys are managed via 1Password / `op` CLI, not committed. `.envrc` is a local-only file (not tracked) and should never be committed.
- **Submodules**: Use shallow clones with `--depth 1` when adding submodules.

## Pinch (Plugin Manager)

Pinch is a pi extension (`.pi/agent/extensions/pinch.ts`) that manages plugins from git repos. It caches repo clones in `$XDG_CACHE_HOME/pinch/` and copies selected plugins into scope-appropriate directories, registering their skills automatically.

Plugins are scoped by which manifest defines them. Sources in the global manifest only install to `~/.pi/pinch/` (user scope). Sources referenced in a project manifest install to `.pi/pinch/` (project scope). This keeps user-specific plugins out of project repositories.

- Global manifest: `~/.pi/agent/pinch.json` — user-wide sources
- Project manifest: `.pi/pinch.json` — per-project, can reference global sources or define new ones
- Lock files: `~/.pi/agent/pinch-lock.json` (user) and `.pi/pinch-lock.json` (project)
- Commands: `/pinch:install`, `/pinch:update`, `/pinch:status`

To add a plugin, add an entry to `pinch.json` and run `/pinch:install`. See the pinch skill for manifest format and troubleshooting.

## Open Issues

Track work at: https://git.kejadlen.dev/alpha/dotfiles/issues
