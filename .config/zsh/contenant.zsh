#!/usr/bin/env zsh

if (( $+commands[contenant] )); then
  source <(contenant completions zsh)
fi
