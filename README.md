# Dotfiles

This repo contains both my dotfiles as well as [Ansible][ansible] playbooks to
provision new machines.

**Use at your own risk.** Untested except on my own El Capitan installs.

[ansible]: https://github.com/ansible/ansible

# Playbooks

- `bootstrap.yml`: SSH and Homebrew setup
- `main.yml`: Pretty much everything else
- `imac.yml`: For quieting down the broken HDD fan on my iMac
- `macbook_pro.yml`: Remap Caps Lock to Control on the laptop

# Usage

First, some steps need to be performed on the remote machine that I couldn't
figure out how to automate:

- Enable Remote Login in System Preferences -> Sharing.
- Install the command line developer tools: `xcode-select --install`. (It looks
like the Homebrew installer [_should_][xcode-select-cli] be able to handle
this, but I haven't been able to get it to work headless.)
- Install [Xcode](https://itunes.apple.com/us/app/xcode/id497799835?mt=12): `open 'https://itunes.apple.com/us/app/xcode/id497799835?mt=12'`
- Accept the Xcode license: `sudo xcodebuild -license`

[xcode-select-cli]: https://github.com/Homebrew/install/blob/master/install#L207-L216

On the control machine:

```
brew install ansible
git clone --recursive git@github.com:kejadlen/dotfiles
cd dotfiles/ansible

echo HOST > hosts.private

ansible-playbook bootstrap.yml --ask-pass --ask-become-pass
ansible-playbook main.yml --ask-become-pass
```

A couple items that I haven't gotten around to automating yet that need to be
manually run post-provisioning:

``` shell
# Apply personal Terminal settings
open ~/.dotfiles/Alpha.terminal

# Symlink ~/.dotfiles to Dropbox
rm -rf ~/.dotfiles
ln -s ~/Dropbox/dotfiles ~/.dotfiles

# Add private SSH keys
ruby ~/.dotfiles/scripts/setup_ssh_keys.rb

# Install apps from the Mac App Store
open 'https://itunes.apple.com/us/app/reeder-3/id880001334?ls=1&mt=12'
open 'https://itunes.apple.com/us/app/paprika-recipe-manager/id451907568?mt=12'
```

## Provisioning Locally

You can also use this to provision a machine by itself, although this won't
be able to copy over OS X application settings, for obvious reasons.

``` shell
# Install Homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install ansible
brew install ansible

# Clone dotfiles
git clone --recursive https://github.com/kejadlen/dotfiles.git ~/.dotfiles

# Run Ansible
cd ~/.dotfiles/ansible
echo "localhost ansible_connection=local" > hosts.private
ansible-playbook main.yml --ask-pass --ask-become-pass
```

# Development

Ansible tags are indispensible when tweaking the config:

```
- command: echo debug
  tags: debug
```

``` shell
ansible-playbook main.yml --ask-become-pass --tags=debug
```

# TODO

See [issues](https://github.com/kejadlen/dotfiles/issues).
