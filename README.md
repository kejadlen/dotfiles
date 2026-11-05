# dotfiles

## Bootstrapping

macOS things:

- In System Settings
  - General > Sharing
    - [ ] Set computer name (to make SSH easier)
    - [ ] Enable Remote Login
  - Menu Bar
    - [ ] Automatically hide and show the menu bar: Always
    - [ ] Show menu bar background
  - Displays
    - [ ] More Space
  - Keyboard > Keyboard Shortcuts > Modifier Keys
    - [ ] Caps Lock (⇪) -> Control (⌃)

```sh
git clone https://git.kejadlen.dev/alpha/dotfiles.git ~/.dotfiles
~/.dotfiles/bootstrap.sh
```

`bootstrap.sh` installs Homebrew and DotSlash, then runs `frork` to handle
the rest.

Other non-automatable things:

- [ ] Unlock with Apple Watch
- [ ] 1Password
- [ ] CleanShot X
- [ ] Hamerspoon
- Firefox Developer Edition
  - [ ] [uBlock Origin hard mode](https://github.com/gorhill/uBlock/wiki/Blocking-mode:-hard-mode)
- [ ] MailMate
- [ ] Syncthing

## Packages from nix

CLI tools without a DotSlash file in `bin/` come from the `profile`
package in `flake.nix`. Homebrew still provides the GUI apps and the
formulae that haven't moved to nix.

`bootstrap.sh` doesn't install nix. On a new machine, install it with
the [upstream installer][nix], then add the profile:

[nix]: https://nixos.org/download/

```sh
nix profile add ~/.dotfiles#profile
```

After editing `flake.nix` or running `nix flake update`, apply the
change with `nix profile upgrade profile`. `nix profile rollback`
returns to the previous generation.

The flake only sees files that git tracks, and new files in a jj change
aren't in the git index until they're committed. Commit a new `.nix`
file before the flake refers to it.

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
