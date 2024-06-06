#!/usr/bin/env bash

if [ -n "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set "$NAME" label="$FOCUSED_WORKSPACE"
fi
