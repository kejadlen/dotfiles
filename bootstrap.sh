#!/bin/sh

ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
/usr/local/bin/brew install ansible

git clone https://github.com/kejadlen/dotfiles.git ~/.dotfiles
