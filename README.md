A new beginning for what used to be my
[conf_dir](https://github.com/kejadlen/conf_dir) project, since `dotfiles`
appears to be the conventional name of these types of repos nowadays.

This uses [Ansible](https://github.com/ansible/ansible) to provision new
machines and [stow](http://www.gnu.org/software/stow/) for managing conf
files that can be symlinked.

# Requirements

- [Ansible](https://github.com/ansible/ansible)

# Usage

On a fresh install, the bootstrap script installs Homebrew and Ansible, clones
the dotfiles repo into `~/Dropbox/dotfiles`, and creates a symlink to that repo
in `~/.dotfiles`.

``` shell
curl -L https://raw.github.com/kejadlen/dotfiles/master/bootstrap.sh | sh
```

``` shell
cd ~/.dotfiles/ansible && /usr/local/bin/ansible-playbook main.yml --inventory=hosts --ask-sudo-pass
```
