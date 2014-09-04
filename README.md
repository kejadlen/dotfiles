A new beginning for what used to be my
[conf_dir](https://github.com/kejadlen/conf_dir) project, since `dotfiles`
appears to be the conventional name of these types of repos nowadays.

This uses [Ansible](https://github.com/ansible/ansible) to provision new
machines and [stow](http://www.gnu.org/software/stow/) for managing conf
files that can be symlinked.

# Usage

``` shell
sudo xcode-select --install
open 'https://itunes.apple.com/us/app/xcode/id497799835?mt=12'
sudo xcodebuild -license
curl -L https://raw.github.com/kejadlen/dotfiles/master/bootstrap.sh | sh
cd ~/.dotfiles/ansible && ansible-playbook main.yml --ask-sudo-pass
rm -f ~/*.retry
ln -sF ~/Dropbox/dotfiles ~/.dotfiles
```

# Caveats

There are some things that aren't automated.

## App Store

- Fantastical
- Reeder

## Preferences

- Tap to click
- Drag lock
