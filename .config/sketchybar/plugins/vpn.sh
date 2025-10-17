#!/bin/bash

if tailscale status --self; then
	ICON=􀎡
else
	ICON=􀎥
fi

sketchybar --set "$NAME" icon="$ICON"
