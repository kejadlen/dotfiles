#!/usr/bin/env bash

# The workspace items: one per OmniWM workspace, its name followed by an icon
# per app on it. The focused one is filled, ones visible on another monitor are
# outlined, and empty ones are dimmed. Workspaces are grouped by monitor in the
# column order of OmniWM's routing grid, with a separator between monitors. Two
# roles, picked by the first argument:
#
#   (none)       redraw every workspace item, adding and removing items to match
#   focus NAME   switch to the workspace OmniWM calls NAME
#
# Hammerspoon runs `omniwmctl watch`, which fires omniwm_workspace_change on
# every change. Each redraw re-reads the whole bar rather than the event, so the
# items converge on OmniWM's state even when an event goes missing.
#
# sketchybar runs under launchd with a minimal PATH, and this needs omniwmctl,
# jq, and yq.

set -uo pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

export PATH="$HOME/.nix-profile/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

# Each item's click_script points back here, so the script needs its own path.
self="${BASH_SOURCE[0]}"
[[ $self == /* ]] || self="$PWD/$self"
readonly SELF="$self"

readonly PREFIX=workspace.
readonly SEP_PREFIX=workspace-separator.
readonly OMNIWM_SETTINGS="$HOME/.config/omniwm/settings.toml"

# OmniWM app names to sketchybar-app-font ligatures, which the font draws as
# icons; anything unlisted gets the generic one. The font has no Glide glyph,
# and Glide is a Firefox fork.
readonly ICONS='{
  "1Password": ":one_password:",
  "Calendar": ":calendar:",
  "Dash": ":dash:",
  "Discord": ":discord:",
  "Finder": ":finder:",
  "Firefox Developer Edition": ":firefox_developer_edition:",
  "Ghostty": ":ghostty:",
  "Glide": ":firefox:",
  "Hammerspoon": ":hammerspoon:",
  "Mail": ":mail:",
  "MailMate": ":mail:",
  "Messages": ":messages:",
  "Music": ":music:",
  "Notion": ":notion:",
  "Obsidian": ":obsidian:",
  "OrbStack": ":orbstack:",
  "Preview": ":preview:",
  "Rex": ":rex:",
  "Rex Beta": ":rex:",
  "Safari": ":safari:",
  "Slack": ":slack:",
  "Steam": ":steam:",
  "System Settings": ":gear:",
  "zoom.us": ":zoom:"
}'

# Prints a JSON object from monitor name to its position in OmniWM's routing
# grid, or {} when OmniWM routes by the macOS arrangement and has no grid.
grid_positions() {
    yq -p toml -o json '[.routing.arrangements[].monitors[]]' "$OMNIWM_SETTINGS" 2>/dev/null |
        jq -c 'map({(.monitorName): (.gridRow * 1000 + .gridColumn)}) | add // {}' 2>/dev/null ||
        echo '{}'
}

draw() {
    local active grid rows existing
    # Leave the items as they are when OmniWM isn't answering; blanking the bar
    # would read as having no workspaces.
    active=$(omniwmctl query active-workspace --format json |
        jq -re '.result.payload.workspace.rawName') || return 0
    grid=$(grid_positions)
    # isFocused marks each monitor's active workspace, so it only means "has
    # focus" for the one active-workspace names; the rest are merely visible.
    # A monitor missing from the grid keeps OmniWM's order, after the rest.
    rows=$(omniwmctl query workspace-bar --format json |
        jq -re --argjson icons "$ICONS" --arg active "$active" --argjson grid "$grid" '
            .result.payload.monitors | to_entries
            | sort_by($grid[.value.name] // (1000000 + .key))[] | .value
            | .id as $monitor
            | .workspaces | sort_by(.number)[]
            | [$monitor, .rawName, .displayName,
               (if .rawName == $active then "focused"
                elif .isFocused then "visible"
                elif (.windows | length) > 0 then "occupied"
                else "empty" end),
               ([.windows[].appName | $icons[.] // ":default:"]
                | reduce .[] as $i ([]; if index([$i]) then . else . + [$i] end)
                | join(""))]
            | @tsv') || return 0
    existing=$(sketchybar --query bar | jq -r '.items[]')

    local args=() wanted=() monitor previous="" separators=0
    local raw name state apps item color bg border
    while IFS=$'\t' read -r monitor raw name state apps; do
        if [[ -n $previous && $monitor != "$previous" ]]; then
            separators=$((separators + 1))
            item="$SEP_PREFIX$separators"
            wanted+=("$item")
            grep -qxF "$item" <<<"$existing" ||
                args+=(--add item "$item" left
                    --set "$item"
                    icon.drawing=off
                    label="|"
                    label.color=0x80ffffff
                    padding_left=3
                    padding_right=3)
        fi
        previous=$monitor

        item="$PREFIX$raw"
        wanted+=("$item")
        if ! grep -qxF "$item" <<<"$existing"; then
            args+=(--add item "$item" left
                --set "$item"
                background.border_color=0xffcccccc
                background.corner_radius=6
                background.height=26
                icon.padding_left=8
                icon.y_offset=1
                label.font="sketchybar-app-font:Regular:14.0"
                label.padding_left=8
                label.padding_right=8
                padding_left=3
                padding_right=3
                click_script="$(printf '%q focus %q' "$SELF" "$raw")")
        fi

        # Focused fills the pill, visible-on-another-monitor outlines it.
        case $state in
            focused) color=0xff000000 bg=0xffcccccc border=0 ;;
            visible) color=0xffffffff bg=0x00000000 border=1 ;;
            occupied) color=0xffffffff bg=0x00000000 border=0 ;;
            *) color=0x80ffffff bg=0x00000000 border=0 ;;
        esac
        args+=(--set "$item"
            icon="$name"
            icon.color="$color"
            label="$apps"
            label.color="$color"
            label.drawing="$([[ -n $apps ]] && echo on || echo off)"
            background.drawing=on
            background.color="$bg"
            background.border_width="$border")
    done <<<"$rows"

    while IFS= read -r item; do
        [[ $item == "$PREFIX"* || $item == "$SEP_PREFIX"* ]] || continue
        printf '%s\n' "${wanted[@]}" | grep -qxF "$item" || args+=(--remove "$item")
    done <<<"$existing"

    # New items land at the end of the bar, so put them back in order.
    args+=(--reorder workspaces "${wanted[@]}")

    sketchybar "${args[@]}"
}

case "${1-}" in
    "") draw ;;
    focus) omniwmctl workspace focus-name "$2" ;;
    *)
        echo "usage: $0 [focus NAME]" >&2
        exit 64
        ;;
esac
