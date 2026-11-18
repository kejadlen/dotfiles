#!/bin/bash

vpn_connected() { tailscale status --self; }
# An untracked local.sh can redefine vpn_connected.
# shellcheck source=/dev/null
[ -f "$CONFIG_DIR/local.sh" ] && . "$CONFIG_DIR/local.sh"

if vpn_connected; then
	ICON=􀎡
else
	ICON=􀎥
fi

sketchybar --set "$NAME" icon="$ICON"
