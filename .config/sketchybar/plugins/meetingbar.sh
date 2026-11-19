#!/bin/sh

CALENDAR=
# An untracked local.sh can set CALENDAR.
# shellcheck source=/dev/null
[ -f "$CONFIG_DIR/local.sh" ] && . "$CONFIG_DIR/local.sh"

if [ -z "$CALENDAR" ]; then
    sketchybar --set "$NAME" drawing=off
    exit 0
fi

# On failure the swift script prints nothing, so jq emits no output and the
# `//` default never fires — leaving a blank label that looks like a working
# plugin with no meetings. Surface it instead; stderr lands in sketchybar's log.
if ! JSON=$("$CONFIG_DIR/meetingbar.swift" "$CALENDAR"); then
    sketchybar --set "$NAME" label="calendar unavailable"
    exit 1
fi

DISPLAY=$(echo "$JSON" | jq -r '.primary.display // "No meetings"')

sketchybar --set "$NAME" label="${DISPLAY:-No meetings}"
