#!/bin/sh

CALENDAR=
MEETING=$("$CONFIG_DIR/meetingbar.swift" "$CALENDAR")

sketchybar --set "$NAME" label="$MEETING"
