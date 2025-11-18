#!/bin/sh

CALENDAR=
OUTPUT=$("$CONFIG_DIR/meetingbar.swift" "$CALENDAR")

# Parse output: format is markdown link [DISPLAY_TEXT](URL) or just DISPLAY_TEXT
if echo "$OUTPUT" | grep -q '\[.*\]('; then
    # Extract display text and URL from markdown link format
    MEETING=$(echo "$OUTPUT" | sed -E 's/\[(.*)\]\(.*/\1/')
    ZOOM_URL=$(echo "$OUTPUT" | sed -E 's/.*\((.*)\)/\1/')

    # Create a temporary script for clicking
    CLICK_SCRIPT="open \"$ZOOM_URL\""

    sketchybar --set "$NAME" \
        label="$MEETING" \
        click_script="$CLICK_SCRIPT"
else
    # No URL, just set the label and clear any click script
    sketchybar --set "$NAME" \
        label="$OUTPUT" \
        click_script=""
fi
