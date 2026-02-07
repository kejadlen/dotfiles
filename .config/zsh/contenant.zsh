#!/usr/bin/env zsh

if (( $+commands[contenant] )); then
  source <(COMPLETE=zsh contenant)
fi
