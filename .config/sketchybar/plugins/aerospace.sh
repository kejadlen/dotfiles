#!/usr/bin/env bash

# Original source:
#   https://nikitabobko.github.io/AeroSpace/goodness#show-aerospace-workspaces-in-sketchybar

# Function to get focused workspace for a specific monitor
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

# Function to update a specific monitor's workspace
update_monitor_workspace() {
    local monitor_id=$1
    local item_name="aerospace_$monitor_id"

    local workspace=$(get_focused_workspace_for_monitor $monitor_id)

    if [ -n "$workspace" ]; then
        local focused_workspace=$(aerospace list-workspaces --focused 2>/dev/null)

        if [ "$workspace" = "$focused_workspace" ]; then
            # Highlight the focused workspace
            sketchybar --set $item_name \
                label="$workspace" \
                background.drawing=on \
                background.color=0xffcccccc \
                background.border_color=0xffcccccc \
                background.corner_radius=6 \
                background.height=26 \
                label.padding_left=8 \
                label.padding_right=8 \
                padding_left=3 \
                padding_right=3 \
                label.color=0xff000000
        else
            # Normal appearance for non-focused workspaces
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
    # Get list of monitors and update each one
    aerospace list-monitors | while IFS= read -r monitor; do
        monitor_id=$(echo "$monitor" | awk '{print $1}')
        update_monitor_workspace $monitor_id
    done
fi
