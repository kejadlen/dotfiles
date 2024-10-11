#!/usr/bin/env zsh

# Original source:
#   https://nikitabobko.github.io/AeroSpace/goodness#show-aerospace-workspaces-in-sketchybar

if (($argv[(Ie)$FOCUSED_WORKSPACE])); then
    sketchybar --set "$NAME" label="$FOCUSED_WORKSPACE" background.drawing=on
else
    sketchybar --set "$NAME" label="$FOCUSED_WORKSPACE" background.drawing=off
fi
