#!/bin/sh

CALENDAR=alpha.chen@gusto.com
PIN_FILE="${TMPDIR}meetingbar_pin"

if [ "$BUTTON" = "right" ]; then
    # Toggle popup off if already open
    DRAWING=$(sketchybar --query meetingbar | jq -r '.popup.drawing')
    if [ "$DRAWING" = "on" ]; then
        sketchybar --set meetingbar popup.drawing=off
        exit 0
    fi

    if ! JSON=$("$CONFIG_DIR/meetingbar.swift" "$CALENDAR"); then
        sketchybar --remove '/meetingbar\.popup\./' 2>/dev/null
        sketchybar --add item meetingbar.popup.0 popup.meetingbar \
                   --set meetingbar.popup.0 \
                         icon.drawing=off \
                         label="Calendar unavailable — check sketchybar's log" \
                   --set meetingbar popup.drawing=on
        exit 1
    fi

    PINNED_ID=""
    if [ -f "$PIN_FILE" ]; then
        PINNED_ID=$(cat "$PIN_FILE")
    fi

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
            EVENT_ID=$(echo "$EVENT" | jq -r '.id')
            CURRENT=$(echo "$EVENT" | jq -r '.current')
            ITEM_NAME="meetingbar.popup.$INDEX"

            LABEL="$TIME  $TITLE"
            ICON=""
            if [ "$EVENT_ID" = "$PINNED_ID" ]; then
                ICON="📌 "
            elif [ "$CURRENT" = "true" ]; then
                ICON="▶ "
            fi

            # Toggle pin: unpin if already pinned, pin otherwise.
            CLICK="PIN=\${TMPDIR}meetingbar_pin; if [ -f \"\$PIN\" ] && [ \"\$(cat \"\$PIN\")\" = '${EVENT_ID}' ]; then rm \"\$PIN\"; else printf '%s' '${EVENT_ID}' > \"\$PIN\"; fi; sketchybar --set meetingbar popup.drawing=off; sketchybar --update"

            sketchybar --add item "$ITEM_NAME" popup.meetingbar \
                       --set "$ITEM_NAME" \
                             icon="$ICON" \
                             icon.padding_left=6 \
                             label="$LABEL" \
                             label.padding_right=6 \
                             click_script="$CLICK"

            INDEX=$((INDEX + 1))
        done <<< "$(echo "$JSON" | jq -c '.events[]')"
    fi

    sketchybar --set meetingbar popup.drawing=on
else
    # Left click: open the displayed event's meeting URL.
    JSON=$("$CONFIG_DIR/meetingbar.swift" "$CALENDAR") || exit 1
    URL=$(echo "$JSON" | jq -r '.primary.url // empty')

    if [ -n "$URL" ]; then
        open "$URL"
    fi
fi
