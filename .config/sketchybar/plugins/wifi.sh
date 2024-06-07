#!/bin/sh

# source "$HOME/.config/colors.sh" # Loads all defined colors

IP_ADDRESS=$(scutil --nwi | grep address | sed 's/.*://' | tr -d ' ' | head -1)

if [[ $IP_ADDRESS != "" ]]; then
	COLOR=$BLUE
	ICON=􀙇
	LABEL=
else
	COLOR=$WHITE
	ICON=􀙈
	LABEL="Not Connected"
fi

sketchybar --set $NAME background.color=$COLOR \
	icon=$ICON \
	label="$LABEL"
