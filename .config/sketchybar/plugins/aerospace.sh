#!/usr/bin/env bash

# Original source:
#   https://nikitabobko.github.io/AeroSpace/goodness#show-aerospace-workspaces-in-sketchybar

# https://stackoverflow.com/a/47541882
if printf '%s\0' "${argv[@]}" | grep -F -x -z -- "$FOCUSED_WORKSPACE"; then
    sketchybar --set "$NAME" label="$FOCUSED_WORKSPACE" background.drawing=on
else
    sketchybar --set "$NAME" label="$FOCUSED_WORKSPACE" background.drawing=off
fi
