#!/bin/sh

CALENDAR=
JSON=$("$CONFIG_DIR/meetingbar.swift" "$CALENDAR")

DISPLAY=$(echo "$JSON" | jq -r '.primary.display // "No meetings"')

sketchybar --set "$NAME" label="$DISPLAY"
