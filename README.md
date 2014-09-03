A new beginning for what used to be my
[conf_dir](https://github.com/kejadlen/conf_dir) project, since `dotfiles`
appears to be the conventional name of these types of repos nowadays.

This uses [Ansible](https://github.com/ansible/ansible) to provision new
machines and [stow](http://www.gnu.org/software/stow/) for managing conf
files that can be symlinked.

# Usage

First, install [Xcode](https://itunes.apple.com/us/app/xcode/id497799835?mt=12)
and the Command Line Tools.

``` shell
sudo xcode-select --install
open 'https://itunes.apple.com/us/app/xcode/id497799835?mt=12'
```

Then run the bootstrapping script. This installs Homebrew and Ansible, clones
the dotfiles repo into `~/Dropbox/dotfiles`, and creates a symlink to that repo
in `~/.dotfiles`.

``` shell
curl -L https://raw.github.com/kejadlen/dotfiles/master/bootstrap.sh | sh
```

Now ansible can be run to set up mostly everything.

``` shell
cd ~/.dotfiles/ansible && ansible-playbook main.yml --ask-sudo-pass
rm -f ~/*.retry
```
