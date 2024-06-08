#!/bin/bash

IP_ADDRESS=$(scutil --nwi | grep address | sed 's/.*://' | tr -d ' ' | head -1)

if [[ $IP_ADDRESS != "" ]]; then
	ICON=􀙇
else
	ICON=􀙈
fi

sketchybar --set $NAME icon=$ICON
