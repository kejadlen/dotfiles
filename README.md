# Dotfiles

This repo contains both my dotfiles as well as [Ansible][ansible] playbooks to
provision new machines.

## Hammerspoon and Fennel

Hammerspoon embeds Lua 5.4, but Homebrew's `lua` formula tracks the latest
version (currently 5.5). Fennel must be installed for the right Lua version
or Hammerspoon won't find it.

The `frork` provisioner handles this automatically. To set it up manually:

```sh
brew install lua@5.4 luarocks

# Point luarocks at the 5.4 interpreter.
luarocks --lua-version=5.4 --local config variables.LUA /opt/homebrew/opt/lua@5.4/bin/lua
luarocks --lua-version=5.4 --local config variables.LUA_DIR /opt/homebrew/opt/lua@5.4

# Install fennel for Lua 5.4.
luarocks --lua-version=5.4 --local install fennel
```

`init.lua` uses `luarocks path` to add the correct directories to
`package.path` at runtime, so Hammerspoon finds fennel regardless of which Lua
version Homebrew defaults to.

## Useful commands

```
# Adding a submodule
git submodule add -b BRANCH -f --name NAME --depth 1 GIT DIR
```
