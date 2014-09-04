A new beginning for what used to be my
[conf_dir](https://github.com/kejadlen/conf_dir) project, since `dotfiles`
appears to be the conventional name of these types of repos nowadays.

This uses [Ansible](https://github.com/ansible/ansible) to provision new
machines and [stow](http://www.gnu.org/software/stow/) for managing conf
files that can be symlinked.

# Usage

``` shell
# Install Homebrew
ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"

# Install ansible
brew install ansible

# Clone dotfiles
git clone --recursive https://github.com/kejadlen/dotfiles.git ~/.dotfiles

# Xcode
sudo xcode-select --install
open 'https://itunes.apple.com/us/app/xcode/id497799835?mt=12'
sudo xcodebuild -license

# Run Ansible
cd ~/.dotfiles/ansible && ansible-playbook main.yml --ask-sudo-pass
rm -f ~/*.retry

# Post-Dropbox syncing
rm -rf ~/.dotfiles
ln -s ~/Dropbox/dotfiles ~/.dotfiles
```

# Caveats

There are some things that aren't automated.

## App Store

- Fantastical
- Reeder

## Preferences

- Tap to click
- Drag lock
