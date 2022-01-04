# Dotfiles

This repo contains both my dotfiles as well as [Ansible][ansible] playbooks to
provision new machines.

**Use at your own risk.**

[ansible]: https://github.com/ansible/ansible

See [ansible/README.md](ansible/README.md) for installation instructions.

## Remote provisioning

On the control machine:

```
brew install ansible
git clone --recursive git@github.com:kejadlen/dotfiles
cd dotfiles/meta

echo HOST > hosts.private

ansible-playbook bootstrap.yml --ask-pass --ask-become-pass
ansible-playbook main.yml --ask-become-pass
```

# TODO

See [issues](https://github.com/kejadlen/dotfiles/issues).
