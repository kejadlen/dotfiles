# Agent Guide

## Repository Overview

This is a macOS dotfiles repo managed with [jj](https://martinvonz.github.io/jj/) (not git). The repo lives at `~/.dotfiles` (synced via Syncthing to `~/sync/dotfiles`). Config files are symlinked into `$HOME` by [frork](https://git.kejadlen.dev/alpha/flork), a Fennel-based config management tool — see `frork/` for the manifests (especially `_dotfiles.fnl` for the symlink declarations).

Key directories:

- `.config/` — app configs (aerospace, ghostty, nvim, jj, etc.)
- `.hammerspoon/` — Hammerspoon config in Fennel (`.fnl` files compiled to Lua)
- `ai/claude/` — Claude Code config: `CLAUDE.md`, `rules/`, settings, and hooks (symlinked in as `~/.claude`)
- `ai/pi/` — pi agent settings and extensions (symlinked in as `~/.pi/agent`)
- `ai/skills/` — skills, shared by both agents
- `ai/_AGENTS.md` — global agent conventions shared by both agents (symlinked in as `~/.pi/agent/AGENTS.md`; `ai/claude/CLAUDE.md` imports it)
- `.ssh/` — SSH config
- `.zsh/` — Zsh config
- `src/` — git submodules (Alfred workflows, fzf-git, tpm)
- `Brewfile` — Homebrew dependencies

## Version Control

Main bookmark: `main`. Don't commit directly to `main` — work on the `@` change or create new ones.

`ai/_AGENTS.md` owns the jj rules; reach for the `jj` skill before free-handing commands.

## Issue Tracker

Issues are on Gitea at https://git.kejadlen.dev/alpha/dotfiles/issues. Use the `tea` CLI:

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

## Skills

Skills live in `ai/skills/<name>/SKILL.md`. See the `skill-notes` skill for authoring conventions.

Pi loads these via `ai/pi/settings.json`, which points to `~/.dotfiles/ai/skills`. Claude reaches them through `ai/claude/skills` (a symlink to `../skills`), so both agents read the same files — only ever edit `ai/skills/`.

## Pi Packages

Pi manages plugins natively via `pi install` / `pi remove` / `pi update` / `pi list`. Global packages are declared in `~/.pi/agent/settings.json` under `packages`. Project-scoped packages use `.pi/settings.json` with the `-l` flag.

Use the object form with `skills` filters to load specific plugins from multi-plugin repos.
