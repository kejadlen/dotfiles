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

## Open Issues

Track work at: https://git.kejadlen.dev/alpha/dotfiles/issues
