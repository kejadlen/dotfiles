#!/bin/sh

CALENDAR=
OUTPUT=$("$CONFIG_DIR/meetingbar.swift" "$CALENDAR")

# Parse output: format is "DISPLAY_TEXT<||>ZOOM_URL" or just "DISPLAY_TEXT"
if echo "$OUTPUT" | grep -q "<||>"; then
    MEETING=$(echo "$OUTPUT" | cut -d'<' -f1)
    ZOOM_URL=$(echo "$OUTPUT" | grep -o '<||>.*' | sed 's/<||>//')

    # Create a temporary script for clicking
    CLICK_SCRIPT="open \"$ZOOM_URL\""

    sketchybar --set "$NAME" \
        label="$MEETING" \
        click_script="$CLICK_SCRIPT"
else
    # No Zoom URL, just set the label and clear any click script
    sketchybar --set "$NAME" \
        label="$OUTPUT" \
        click_script=""
fi
