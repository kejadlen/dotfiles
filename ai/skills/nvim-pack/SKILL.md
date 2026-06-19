---
name: nvim-pack
description: Use when adding, updating, removing, or configuring Neovim plugins with the built-in vim.pack plugin manager - covers vim.pack.add, vim.pack.update, vim.pack.del, lockfile management, version pinning, and PackChanged hooks
---

# Neovim Built-in Plugin Manager (vim.pack)

Use `:help vim.pack` for authoritative API reference and current behavior.

## Overview

`vim.pack` is Neovim's built-in plugin manager (experimental but stable for daily use). It manages plugins as Git repos in `$XDG_DATA_HOME/nvim/site/pack/core/opt/` with a lockfile at `$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json`.

## Core Workflow

1. Add `vim.pack.add({specs})` calls to `init.lua` (or Fennel equivalent)
2. `:restart` — new plugins install automatically on first `add()` call
3. `:lua vim.pack.update()` — fetch updates, review in confirmation buffer
4. `:write` to confirm updates, `:quit` to discard

## Quick Reference

| Operation | Command |
|---|---|
| Add plugin (string shorthand) | `vim.pack.add({"https://github.com/user/plugin.git"})` |
| Add with version | `vim.pack.add({{src = "https://…", version = "v1.0.0"}})` |
| Add with semver range | `vim.pack.add({{src = "https://…", version = vim.version.range("1.0")}})` |
| Add following a branch | `vim.pack.add({{src = "https://…", version = "main"}})` |
| Custom name | `vim.pack.add({{src = "https://…", name = "my-name"}})` |
| Update all plugins | `:lua vim.pack.update()` |
| Update specific plugin | `:lua vim.pack.update({"plugin-name"})` |
| Offline browse (explore installed) | `:lua vim.pack.update(nil, {offline = true})` |
| Sync to lockfile | `:lua vim.pack.update(nil, {target = "lockfile"})` |
| Delete plugin | `:lua vim.pack.del({"plugin-name"})` |
| List all plugin info | `:lua vim.print(vim.pack.get())` |
| List inactive plugins | `:lua vim.print(vim.iter(vim.pack.get()):filter(function(x) return not x.active end):map(function(x) return x.spec.name end):totable())` |

## Spec Fields

- **`src`** (string, required) — Git URI. Any format `git clone` accepts.
- **`name`** (string, optional) — Directory name. Defaults to repo name.
- **`version`** (string or `vim.VersionRange`, optional) — Branch, tag, commit hash, or `vim.version.range()`. Default: repo's default branch.
- **`data`** (any, optional) — Arbitrary user data.

## Lockfile

Located at `$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json`. Tracks `rev`, `src`, and `version` for each plugin. Put under version control for reproducible setups.

**Freeze a plugin:** Set `version` to the current commit hash (find it in the lockfile's `rev` field). `:restart`.

**Unfreeze:** Change `version` back to a branch/tag/range. `:restart`.

**Revert after update:** Restore lockfile from VCS (`git checkout HEAD -- nvim-pack-lock.json` or `jj restore`), then `:restart` and `:lua vim.pack.update(nil, {offline = true, target = "lockfile"})`.

**Cross-machine sync:** Commit the lockfile, pull on the other machine, `:restart`, then run `:lua vim.pack.update(nil, {target = "lockfile"})`.

## PackChanged Events

Hook into install/update/delete with `PackChangedPre` and `PackChanged` autocmds. Event data fields: `active`, `kind` ("install"/"update"/"delete"), `spec`, `path`.

```lua
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
      if not ev.data.active then vim.cmd.packadd("nvim-treesitter") end
      vim.cmd.TSUpdate()
    end
  end
})
```

Register hooks **before** `vim.pack.add()` if they need to run on initial install.

## Shorter Source URLs

Use Git's `insteadOf` config:

```bash
git config --global url."https://github.com/".insteadOf "gh:"
```

Then in init.lua: `vim.pack.add({"gh:user/plugin"})`.

Note: these short URLs appear verbatim in the lockfile, so other machines need the same Git config.

## Removing Plugins

1. Remove the spec from `vim.pack.add()` in your config
2. `:restart`
3. `:lua vim.pack.del({"plugin-name"})` to delete from disk

## add() Options

- **`load`** — `false` (default during init.lua), `true` (default after), or custom function. Controls whether `plugin/` and `ftdetect/` files load.
- **`confirm`** — Whether to prompt user on first install. Default `true`.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Plugin not loading after add | Ensure `add()` is called; if needed during init.lua, plugin loads via `:packadd` semantics. Check `:scriptnames`. |
| Hook not firing on install | Register `PackChanged` autocmd **before** the `vim.pack.add()` call |
| Lockfile conflicts after update | Discard with `:quit` in confirmation buffer, restore lockfile from VCS |
| Version mismatch on disk | Run `vim.pack.update({"plugin"})` to sync disk to declared version |
| `add()` called twice for same plugin | Second call is a no-op; only first registration counts per session |
