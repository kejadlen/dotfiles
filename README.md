A new beginning for what used to be my
[conf_dir](https://github.com/kejadlen/conf_dir) project, since `dotfiles`
appears to be the conventional name of these types of repos nowadays.

This uses [Ansible](https://github.com/ansible/ansible) to provision new
machines.

# Usage

There are two ways to go about using this - either locally or remotely. The main
difference is that OS X application settings are only copied over when running
this on a remote machine.

Either way, we start with installing Xcode:

``` shell
xcode-select --install
open 'https://itunes.apple.com/us/app/xcode/id497799835?mt=12'
sudo xcodebuild -license
```

**After running Ansible**, there are some optional tasks for full desktop setup:

``` shell
# Remove the bootstrap directory for the canonical one in Dropbox
rm -rf ~/.dotfiles
ln -s ~/Dropbox/dotfiles ~/.dotfiles

# Apply personal Terminal settings
open ~/.dotfiles/Alpha.terminal

# Add private SSH keys
ruby ~/.dotfiles/scripts/setup_ssh_keys.rb
```

## Local

``` shell
# Install Homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install ansible
brew install ansible

# Clone dotfiles
git clone --recursive https://github.com/kejadlen/dotfiles.git ~/.dotfiles

# Run Ansible
cd ~/.dotfiles/ansible && ansible-playbook main.yml --ask-sudo-pass
rm -f ~/*.retry
```

## Remote

On the remote machine, SSH access must first be enabled (under System
Preferences -> Sharing) and the Xcode Command Line Tools need to be installed
(`xcode-select --install`).

``` shell
cd ~/.dotfiles/ansible && ansible-playbook main.yml --ask-pass --ask-sudo-pass
```

# Misc

To update submodules:

``` shell
git submodule foreach git pull
```

# Development

Ansible tags are indispensible when tweaking the config.

```
- command: echo debug
  tags: debug
```

``` shell
ansible-playbook main.yml --ask-sudo-pass --tags debug
```

# Vagrant

``` shell
vagrant up
ansible vagrant -m ping
```

# TODO

See [issues](https://github.com/kejadlen/dotfiles/issues).
