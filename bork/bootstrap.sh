# TODO use scutil to set the machine name

ok directory ~/src

# ok git ~/src/dotfiles https://git.kejadlen.dev/alpha/dotfiles.git

register brew-bundle.sh

# symlink dotfiles directly in $HOME
declare -a dotfiles=(
  ".config"
  ".digrc"
  ".gemrc"
  ".gitconfig"
  ".hammerspoon"
  ".inputrc"
  ".local"
  ".p10k.zsh"
  ".profile"
  ".ruby-version"
  ".tmux.conf"
  ".zsh"
  ".zshenv"
  ".zshrc"

  ".bundle/config"
  ".cargo/config.toml"
  ".docker/config.json"
)
for file in "${dotfiles[@]}"; do
  ok directory "$(dirname $file)"
  ok symlink "$HOME/$file" "$HOME/.dotfiles/$file"
done

### macos

ok brew
ok brew-bundle "$HOME/.dotfiles/bork/Brewfile"

ok symlink "$HOME/Library/Application\ Support/LibreWolf/NativeMessagingHosts" "$HOME/Library/Application\ Support/Mozilla/NativeMessagingHosts"

### jujutsu

jj_config=$(jj config path --user)
ok directory "$(dirname "$jj_config")"
ok symlink "$jj_config" "$HOME/.config/jj/config.toml"

include _defaults.sh

# TODO set the default shell to /bin/sh
# dscl . -read ~/ UserShell
# https://tratt.net/laurie/blog/2024/faster_shell_startup_with_shell_switching.html
# - name: Set default shell to sh
#   ansible.builtin.user:
#     name: alpha
#     shell: /bin/sh --login

# TODO
# luarocks install fennel

# TODO tridactyl: https://librewolf.net/docs/faq/#how-can-i-get-tridactyls-native-messaging-to-work-when-i-install-librewolf-with-flatpak
