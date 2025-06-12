#!/usr/bin/env bash

# Original source:
#   https://nikitabobko.github.io/AeroSpace/goodness#show-aerospace-workspaces-in-sketchybar

# Update the current workspace label
CURRENT_WORKSPACE=$(aerospace list-workspaces --focused)
sketchybar --set $NAME label="$CURRENT_WORKSPACE"
