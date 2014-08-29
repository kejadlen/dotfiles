#!/bin/sh

ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
brew install ansible

mkdir -p ~/Dropbox/dotfiles
git clone git@github.com:kejadlen/dotfiles.git ~/Dropbox/dotfiles
ln -s ~/Dropbox/dotfiles ~/.dotfiles
