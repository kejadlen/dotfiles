# Moving the dotfiles to nix

Status: `flake.nix` builds a package profile, and imperishable-night
installs it for `alpha`. The Mac still uses its hand-installed
`nix profile` entries (2026-11-05).

This note records a plan to install packages with nix, so the dotfiles
work on Linux hosts as well as the Mac. frork keeps creating the
symlinks on every machine, with or without nix. The note covers the
current setup, the Linux gap, how the work splits between nix and frork,
a proposed order, and open questions. It doesn't cover the Ansible
playbooks in `meta/` or the ramekin container image.

## The current setup

The following table lists what sets up a machine today and where each
layer goes under this plan:

| Layer | Today | Planned |
|---|---|---|
| CLI tools | About 25 Homebrew formulae, plus about 30 DotSlash files in `bin/` | A nix package profile, with DotSlash for machines without nix |
| GUI apps | About 20 casks, `Brewfile.personal`, and `mas` | Homebrew, optionally driven by nix-darwin |
| Symlinks | `frork/_dotfiles.fnl`, mostly whole directories (`~/.config`, `~/.claude`, `~/.hammerspoon`) | frork, unchanged |
| macOS state | `frork/_defaults.fnl`, dockutil, `scutil` hostname, `chsh` | frork, or nix-darwin later |
| One-off commands | luarocks fennel for Hammerspoon, `bat cache`, sketchybar restart | frork |
| Editor and shell plugins | vim.pack (with a lockfile), tpm, and zsh4humans | Unchanged |

Nix is already installed with the upstream installer (there's no
`/nix/receipt.json`, which Determinate's installer writes), and
`.config/nix/nix.conf` enables flakes. `nix profile` holds bash and
nix-direnv, installed by hand. `.config/zsh/local.zsh` points
`DIRENV_BASH` at that bash.

## The Linux gap

Almost nothing in the package layer runs on Linux. Of the 30 DotSlash
files in `bin/`, 29 declare only `macos-aarch64`; shellcheck is the
exception. frork is one of the 29, so frork can't bootstrap a Linux host
either. The cause is the Rakefile: `dotslash_tag` reads only the
`macos-aarch64` entry, and the update task writes only that platform
(`Rakefile:85`).

The Brewfile formulae have no Linux counterpart beyond whatever each
distro packages. The shell config is mostly portable already; `.zshrc`
guards its one Homebrew call behind `type brew`.

## Links from frork

The config directories must stay live. Syncthing edits them, agents
write into `~/.claude` constantly, and changes take effect without a
rebuild. home-manager's default `home.file` copies files into the
read-only nix store, which breaks all three.

home-manager's escape hatch, `config.lib.file.mkOutOfStoreSymlink`,
links through the store to a path in the repo. It needs an absolute
string such as `"/Users/alpha/.dotfiles/.config"`; under flakes, a path
literal resolves to the flake's store copy, so edits wait for a rebuild.
frork already makes plain links and runs without nix, so it keeps that
job. jade's [post on dotfiles without nix][jade] makes the same case: a
symlink script for config, and nix for packages and user services.

[jade]: https://jade.fyi/blog/use-nix-less/

frork needs two changes to run on Linux:

- A Linux build. Its DotSlash file points only at
  `frork-aarch64-apple-darwin.tar.gz` from the kejadlen/frork releases.
- A links-only entrypoint. `frork/main.fnl` calls `brew`, `dscl` and
  `chsh`, `bat cache`, and sketchybar unconditionally.
  `frork/_dotfiles.fnl` is close to standing alone, but it needs to load
  without `_macos`.

On Linux, the `~/.config` link also brings along Mac-only directories
like `aerospace` and `sketchybar`. Nothing reads them there, so they
aren't worth splitting out.

## Packages from nix

Most DotSlash tools are in nixpkgs: age, bat, difftastic, direnv,
efm-langserver, fd, fzf, gh, git-lfs, hyperfine, jujutsu, jq, just,
ripgrep, shellcheck, sops, tea, tree-sitter, yamlfmt, yt-dlp, zizmor,
zoekt, and zoxide. So are the portable formulae, such as tmux, zsh,
neovim, entr, eza, ffmpeg, restic, and the language servers. One package
list then covers both platforms.

The exceptions are frork, ramekin, ranger, and cq. Each needs either a
`flake.nix` (in its own repo, or a package expression here) or Linux
entries in its DotSlash file.

Moving a tool from DotSlash to nixpkgs trades per-tool version pins for
one lockfile. nixpkgs-unstable usually trails upstream releases by days
to weeks, which matters most for fast-moving tools like jj.

Three formulae build from HEAD. neovim and tree-sitter can come from
[neovim-nightly-overlay][nno]. fennel-ls HEAD comes from the personal
Homebrew tap and would need its own derivation. universal-ctags is on
HEAD for a reason nobody remembers, so a nixpkgs release is probably
fine.

[nno]: https://github.com/nix-community/neovim-nightly-overlay

### Choosing the package profile

Every option below builds a nix profile: a symlink to numbered
generations, each one a store path. All of them give atomic switches and
rollbacks. They differ in how the next generation is built, what else
they manage, and which profile format they write. The current profile
was created by `nix profile` (manifest version 3), and `nix-env` refuses
to operate on that format.

The following table compares the options:

| Option | Pros | Cons |
|---|---|---|
| home-manager | Manages user services such as `services.syncthing` (launchd on macOS, systemd on Linux). frork can run from a `home.activation` step after `writeBoundary`, so one switch does both jobs. | Evaluates the whole module system for what is mostly a package list. Adds a large tool to learn and keep updated. |
| [flakey-profile][fp] | Replaces the whole profile on each switch, so stray imperative installs can't linger. Its `pin` command points the flake registry and channels at the locked nixpkgs. | Uses `nix-env`, so it needs a fresh profile. Manages packages only, and the last commit is from April 2024. |
| `buildEnv` with `nix-env --set` | Does what flakey-profile does in about ten lines, with no dependency. | Needs a fresh profile. A registry pin must be written by hand, including the `-source` path check from NixOS/nix#7075. |
| `buildEnv` with `nix profile` | Keeps the existing profile format. Needs no dependency, since `nix profile upgrade` and `nix profile rollback` do the rest. | A stray `nix profile install` adds an element outside the flake. A registry pin must be written by hand. |
| nix-darwin or NixOS system packages | One switch covers system settings and packages. | Unavailable on other Linux distros. Packages go into the system profile, which root manages. |
| Hand-run `nix profile install`, as today | Needs no setup. | Has no declarative list, so each machine drifts. |

[fp]: https://github.com/lf-/flakey-profile

flakey-profile, also by jade, is a thin wrapper: `pkgs.buildEnv` for the
package list, plus one-line `switch` and `rollback` scripts around
`nix-env --set` and `nix-env --rollback`. Both hand-rolled options start
from the same `buildEnv`:

```nix
packages.${system}.profile = pkgs.buildEnv {
  name = "profile";
  paths = with pkgs; [ bash nix-direnv jujutsu ripgrep tmux zsh ];
};
```

With `nix profile`, install it once with `nix profile install .#profile`,
then run `nix profile upgrade profile` after each edit.

Every option except home-manager leaves frork and syncthing to a wrapper
script. The script runs `frork satisfy` and then the switch, and a
machine without nix runs the same script minus the switch. Syncthing
then needs its own service setup on each platform.

Whichever option wins, bash and nix-direnv move from hand installs into
the package list.

bash is there only for nix-direnv, which needs bash 4 or later; macOS
ships 3.2. The `DIRENV_BASH` export that points direnv at it lives in
`.config/zsh/local.zsh`, which isn't tracked, so another Mac would run
nix-direnv under 3.2. Once bash is in the package list, move the export
into tracked config and set it only on macOS.

## Machines without nix

Nix needs root once, to create `/nix`. Where that's not possible, such
as locked-down servers or container images, frork and DotSlash cover the
machine:

- frork creates the same links.
- `bin/` provides the single-binary tools, once the Rakefile's
  `update_dotslash_release` writes `linux-x86_64` and `linux-aarch64`
  entries. Most of those projects publish Linux release assets.
- zsh, tmux, neovim, and other tools with a dependency tree come from
  the distro, at whatever versions it ships.

Rootless nix exists but doesn't help much. [nix-portable][np] fakes
`/nix` with user namespaces or proot and is slow. A store outside `/nix`
misses the binary cache, because store paths include the prefix, so
everything builds from source.

[np]: https://github.com/DavHau/nix-portable

The ramekin image already installs tools with DotSlash and apt. If it
needs more of `bin/`, the same Linux entries cover it.

## nix-darwin on the Mac

nix-darwin could take over the Mac-specific parts of frork. This is
optional, since frork handles them today:

- `system.defaults` covers nearly all of `_defaults.fnl`, such as
  `dock.autohide`, `dock.orientation`, `NSGlobalDomain.KeyRepeat`, and
  `spaces.spans-displays`
- `system.defaults.CustomUserPreferences` covers the rest, such as
  MailMate and the Safari debug menu, including the dictionary and
  array values that frork's `defaults` type doesn't support
- `networking.computerName` and `networking.localHostName` replace the
  `scutil` calls in `_local.fnl`
- `fonts.packages` with `nerd-fonts.sauce-code-pro` and friends replaces
  the font casks
- The `homebrew` module generates a Brewfile from nix and runs
  `brew bundle` on activation

Homebrew doesn't go away; casks and `mas` apps still come from it, and
activation still pays the `brew bundle` cost that `_macos.fnl` complains
about. Start with `homebrew.onActivation.cleanup = "none"`, then switch
to `"zap"` once the nix lists match what's installed.

Because nix came from the upstream installer, nix-darwin should manage
nix itself (`nix.enable = true`) and takes over `/etc/nix/nix.conf`.
nix-darwin runs activation as root, so frork must not run from it; the
links would land in root's home directory.

Some steps don't map onto nix-darwin and would stay in frork:

- `chsh` to `/bin/sh`, since nix-darwin only manages shells for users
  listed in `users.knownUsers`
- The Firefox `chrome` link, since profile directories are found by
  glob
- `bat cache --build`
- The dockutil setup, unless `system.defaults.dock.persistent-others`
  can express the Downloads stack

Hammerspoon's fennel currently comes from luarocks, built against
Homebrew's `lua@5.4`. nix could provide `lua54Packages.fennel` instead,
but `.hammerspoon/init.lua` would then need a nix store path on
`package.path`.

## Proposed order

1. Split frork's manifests so the links load without the macOS parts,
   and publish a Linux build of frork.
2. Add `flake.nix` with a package profile holding the portable formulae,
   the DotSlash tools in nixpkgs, bash, and nix-direnv. Hook frork into
   the switch, and remove the hand-installed `nix profile` entries.
3. Bring up one Linux host with the same flake.
4. Extend the Rakefile to write Linux DotSlash entries, for machines
   without nix and for the tools nixpkgs doesn't have.
5. Update `bootstrap.sh` to install nix where possible and run the same
   switch.
6. Optionally, add nix-darwin.

## Risks

Nix flakes in a git repo only see files that are in the git index. In a
colocated jj repo, new files in `@` are missing from the index, so
evaluating fails with "path is not tracked by Git" until the file is
committed. The `path:` flake URL skips the git check, but it
copies the whole directory into the store, including untracked and
ignored paths like `ai/claude/projects` and `.direnv`.

Every package change costs a full evaluation and switch. Config edits
don't, since frork's links point straight at the repo.

## Open questions

- Which Linux hosts: a desktop, servers (the `meta/` playbooks cover
  `ramble-hard` and a Pi), development VMs, or containers?
- NixOS or another distro? On NixOS, packages would likely move into the
  system configuration; frork's links stay the same.
- Which architectures? A Pi needs `aarch64-linux`.
- Which option builds the package profile?
- Should frork, ramekin, and ranger get flakes, or stay on DotSlash with
  Linux entries?

---

Drafted with Claude Code.
