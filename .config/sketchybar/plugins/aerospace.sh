#!/usr/bin/env bash

# Original source:
#   https://nikitabobko.github.io/AeroSpace/goodness#show-aerospace-workspaces-in-sketchybar

get_focused_workspace_for_monitor() {
    local monitor_id=$1

    # Get all workspaces for this monitor and check which one has focus
    # We'll use aerospace focus to determine which workspace is active on which monitor
    local workspaces=$(aerospace list-workspaces --monitor $monitor_id 2>/dev/null)
    local focused_workspace=$(aerospace list-workspaces --focused 2>/dev/null)

    # Check if the focused workspace belongs to this monitor
    if echo "$workspaces" | grep -q "^$focused_workspace$"; then
        echo "$focused_workspace"
    else
        # If focused workspace is not on this monitor, get the first workspace
        echo "$workspaces" | head -n 1
    fi
}

is_monitor_connected() {
    local monitor_id=$1
    aerospace list-monitors 2>/dev/null | grep -q "^$monitor_id "
}

update_monitor_workspace() {
    local monitor_id=$1
    local item_name="aerospace_$monitor_id"

    # Hide the item if monitor is not connected
    if ! is_monitor_connected $monitor_id; then
        sketchybar --set $item_name drawing=off
        return
    fi

    local workspace=$(get_focused_workspace_for_monitor $monitor_id)

    if [ -n "$workspace" ]; then
        # Show the item since monitor is connected
        sketchybar --set $item_name drawing=on

        local focused_workspace=$(aerospace list-workspaces --focused 2>/dev/null)
        local monitor_count=$(aerospace list-monitors | wc -l)

        # Highlight the focused workspace if there are multiple monitors
        if [ "$monitor_count" -gt 1 ] && [ "$workspace" = "$focused_workspace" ]; then
            sketchybar --set $item_name \
                label="$workspace" \
                background.drawing=on \
                label.color=0xff000000
        else
            sketchybar --set $item_name \
                label="$workspace" \
                background.drawing=off \
                label.color=0xffffffff
        fi
    fi
}

# If NAME is provided (called for specific item), update that item
if [ -n "$NAME" ]; then
    # Extract monitor ID from item name (aerospace_1 -> 1)
    monitor_id=${NAME#aerospace_}
    update_monitor_workspace $monitor_id
else
    # Update all monitors
    aerospace list-monitors | while IFS= read -r monitor; do
        monitor_id=$(echo "$monitor" | awk '{print $1}')
        update_monitor_workspace $monitor_id
    done
fi
