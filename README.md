# Dotfiles

This repo contains both my dotfiles as well as [Ansible][ansible] playbooks to
provision new machines.

**Use at your own risk.**

[ansible]: https://github.com/ansible/ansible

# Playbooks

- `bootstrap.yml`: SSH and Homebrew setup
- `main.yml`: Pretty much everything else
- `imac.yml`: For quieting down the broken HDD fan on my iMac
- `macbook_pro.yml`: Remap Caps Lock to Control on the laptop

# Usage

Use a [tracking issue][tracking-issue] as a checklist for local provisioning.

[tracking-issue]: https://github.com/kejadlen/dotfiles/issues/new?template=setup.md

## Remote provisioning

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
# Symlink ~/.dotfiles to Dropbox
rm -rf ~/.dotfiles
ln -s ~/Dropbox/dotfiles ~/.dotfiles
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
