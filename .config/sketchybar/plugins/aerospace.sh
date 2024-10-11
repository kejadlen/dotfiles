#!/usr/bin/env zsh

# Original source:
#   https://nikitabobko.github.io/AeroSpace/goodness#show-aerospace-workspaces-in-sketchybar

workspaces=("${(@f)$(aerospace list-workspaces --monitor $1)}")

if (($workspaces[(Ie)$FOCUSED_WORKSPACE])); then
    sketchybar --set "$NAME" label="$FOCUSED_WORKSPACE" background.drawing=on
else
    sketchybar --set "$NAME" label="$FOCUSED_WORKSPACE" background.drawing=off
fi
