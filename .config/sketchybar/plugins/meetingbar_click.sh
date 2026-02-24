#!/bin/sh

CALENDAR=alpha.chen@gusto.com

if [ "$BUTTON" = "right" ]; then
    # Toggle popup off if already open
    DRAWING=$(sketchybar --query meetingbar | jq -r '.popup.drawing')
    if [ "$DRAWING" = "on" ]; then
        sketchybar --set meetingbar popup.drawing=off
        exit 0
    fi

    JSON=$("$CONFIG_DIR/meetingbar.swift" "$CALENDAR")

    # Remove old popup items
    sketchybar --remove '/meetingbar\.popup\./' 2>/dev/null

    EVENT_COUNT=$(echo "$JSON" | jq '.events | length')

    if [ "$EVENT_COUNT" -eq 0 ]; then
        sketchybar --add item meetingbar.popup.0 popup.meetingbar \
                   --set meetingbar.popup.0 \
                         icon.drawing=off \
                         label="No more meetings today"
    else
        INDEX=0
        while IFS= read -r EVENT; do
            TIME=$(echo "$EVENT" | jq -r '.time')
            TITLE=$(echo "$EVENT" | jq -r '.title')
            URL=$(echo "$EVENT" | jq -r '.url // empty')
            CURRENT=$(echo "$EVENT" | jq -r '.current')
            ITEM_NAME="meetingbar.popup.$INDEX"

            LABEL="$TIME  $TITLE"
            ICON=""
            if [ "$CURRENT" = "true" ]; then
                ICON="▶ "
            fi

            if [ -n "$URL" ]; then
                sketchybar --add item "$ITEM_NAME" popup.meetingbar \
                           --set "$ITEM_NAME" \
                                 icon="$ICON" \
                                 icon.padding_left=6 \
                                 label="$LABEL" \
                                 label.padding_right=6 \
                                 click_script="open '$URL'; sketchybar --set meetingbar popup.drawing=off"
            else
                sketchybar --add item "$ITEM_NAME" popup.meetingbar \
                           --set "$ITEM_NAME" \
                                 icon="$ICON" \
                                 icon.padding_left=6 \
                                 label="$LABEL" \
                                 label.padding_right=6
            fi

            INDEX=$((INDEX + 1))
        done <<< "$(echo "$JSON" | jq -c '.events[]')"
    fi

    sketchybar --set meetingbar popup.drawing=on
else
    # Left click: open the primary event's meeting URL
    JSON=$("$CONFIG_DIR/meetingbar.swift" "$CALENDAR")
    URL=$(echo "$JSON" | jq -r '.primary.url // empty')

    if [ -n "$URL" ]; then
        open "$URL"
    fi
fi
