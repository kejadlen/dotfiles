#!/usr/bin/env bash

# The agents item: how many Claude Code sessions ,agent-state is tracking, and
# a way into whichever one needs attention. Three roles in one script, picked by
# the first argument, so the state colors and the tmux logic have one home:
#
#   (none)      draw the item — most urgent state and its count, hidden if idle
#   click       left jumps to the most urgent session, right opens the popup
#   jump PANE   switch to that tmux pane and bring Ghostty forward
#
# State is re-read on every invocation rather than cached, so a click lands on
# what is true now instead of what the bar last drew.
#
# sketchybar runs under launchd with a minimal PATH, and ,agent-state needs tmux
# to tell which panes are still alive. Without tmux its `list` prints nothing
# rather than failing, so a missing PATH entry would leave this item permanently
# hidden instead of visibly broken — hence the explicit PATH.

set -uo pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

readonly STATE_SCRIPT="$HOME/.dotfiles/ai/bin/,agent-state"

# Popup rows point their click_script back here, so the script needs its own
# path. sketchybar invokes it by the absolute path built from $PLUGIN_DIR, but a
# relative one would land in each row's click_script and resolve against
# whatever cwd sketchybar happens to have, failing silently on click.
self="${BASH_SOURCE[0]}"
[[ $self == /* ]] || self="$PWD/$self"
readonly SELF="$self"

# sketchybar sets NAME to the item it is invoking, which for a popup row is
# agents.popup.N rather than the item that owns the popup. Stripping the suffix
# keeps every path pointed at the same item without hardcoding its name.
item="${NAME:-agents}"
readonly ITEM="${item%%.popup.*}"

# The same colors prefix+A uses in ,agents, so the bar and the picker agree.
readonly COLOR_BLOCKED=0xffff5f5f
readonly COLOR_IDLE=0xffffd75f
readonly COLOR_WORKING=0xff888888

# Nerd Font glyphs rather than emoji, because these go in a *label* and a label
# takes one font — the default SauceCodePro Nerd Font, which has no emoji
# coverage. An emoji there would draw as nothing at all, the way icon=🤖 did
# before it got an explicit Apple Color Emoji font. These are Material Design
# icons (alert-circle, check-circle, cog), which Nerd Fonts v3 carries at the
# codepoints MDI itself assigns.
readonly GLYPH_BLOCKED=󰀨
readonly GLYPH_IDLE=󰗠
readonly GLYPH_WORKING=󰒓

state_rows() {
    [[ -x $STATE_SCRIPT ]] || return 0
    "$STATE_SCRIPT" list 2>/dev/null
}

color_for() {
    case ${1-} in
        blocked) printf '%s' "$COLOR_BLOCKED" ;;
        idle) printf '%s' "$COLOR_IDLE" ;;
        *) printf '%s' "$COLOR_WORKING" ;;
    esac
}

glyph_for() {
    case ${1-} in
        blocked) printf '%s' "$GLYPH_BLOCKED" ;;
        idle) printf '%s' "$GLYPH_IDLE" ;;
        *) printf '%s' "$GLYPH_WORKING" ;;
    esac
}

cmd_status() {
    local rows
    rows=$(state_rows)

    if [[ -z $rows ]]; then
        sketchybar --set "$ITEM" drawing=off
        return 0
    fi

    # list already orders blocked, then idle, then working, so the first row
    # names the most urgent state and the label counts how many share it. The
    # ordering within a state doesn't matter here — only which state leads.
    # BSD head and cut have no long forms for these, so short flags it is.
    local state count
    state=$(head -n 1 <<<"$rows" | cut -f 1)
    count=$(cut -f 1 <<<"$rows" | grep --count --line-regexp --fixed-strings "$state")

    sketchybar --set "$ITEM" \
        drawing=on \
        label="$count $state" \
        label.color="$(color_for "$state")"
}

cmd_click() {
    case "${BUTTON:-left}" in
        right) show_popup ;;
        *) jump_to_top ;;
    esac
}

# list orders blocked first, so the top row is the session most likely to be
# waiting on a human — and puts the ones already jumped to last within that
# group, so repeated clicks walk the blocked sessions instead of sticking on
# whichever one has been blocked longest.
jump_to_top() {
    local pane
    pane=$(state_rows | head -n 1 | cut -f 6)
    [[ -n $pane ]] || return 0
    cmd_jump "$pane"
}

show_popup() {
    # Toggle off when it is already open, so a second right click closes it.
    local drawing
    drawing=$(sketchybar --query "$ITEM" 2>/dev/null | jq -r '.popup.drawing' 2>/dev/null) || drawing=off
    if [[ $drawing == "on" ]]; then
        sketchybar --set "$ITEM" popup.drawing=off
        return 0
    fi

    sketchybar --remove "/${ITEM}\\.popup\\./" 2>/dev/null

    local rows
    rows=$(state_rows)

    if [[ -z $rows ]]; then
        # Only reachable if the last session ended between the bar drawing the
        # item and the click landing, since the item hides itself when empty.
        sketchybar --add item "$ITEM.popup.0" "popup.$ITEM" \
            --set "$ITEM.popup.0" \
            icon.drawing=off \
            label="No sessions tracked" \
            label.padding_left=6 \
            label.padding_right=6
    else
        local index=0
        local state _session dir age message pane
        # Fields are re-joined on US (0x1f) before reading them. Tab counts as
        # IFS whitespace, so `read` collapses a run of tabs into one delimiter
        # and silently shifts every later field left — a session with no message
        # would land its pane id in `message` and leave `pane` empty, which is
        # the same trap ai/claude/hooks/agent-state.sh calls out. US is not
        # whitespace, so empty fields survive.
        # session:window is read but not shown: clicking a row goes to the pane
        # directly, so the tmux coordinate is noise here. ,agents still lists it.
        while IFS=$'\x1f' read -r state _session dir age message pane; do
            local row="$ITEM.popup.$index"
            # Padded here rather than in ,agent-state, which stays a plain data
            # source. The label font is monospace, so columns line up.
            sketchybar --add item "$row" "popup.$ITEM" \
                --set "$row" \
                icon.drawing=off \
                label="$(printf '%s  %-14s %5s  %s' \
                    "$(glyph_for "$state")" "$dir" "$age" "$message")" \
                label.color="$(color_for "$state")" \
                label.padding_left=6 \
                label.padding_right=6 \
                click_script="\"$SELF\" jump $pane"
            index=$((index + 1))
        done <<<"$(tr '\t' '\037' <<<"$rows")"
    fi

    sketchybar --set "$ITEM" popup.drawing=on
}

cmd_jump() {
    local pane=${1:-}
    [[ -n $pane ]] || return 0

    # Harmless when the popup is already closed, which is the left-click case.
    sketchybar --set "$ITEM" popup.drawing=off >/dev/null 2>&1 || true

    local session
    session=$(tmux display-message -p -t "$pane" '#{session_name}' 2>/dev/null) || return 0

    # Prefer a client already looking at that session: switching a client that
    # sits on some other session would yank that window away from whatever the
    # user left in it. With no match, -c is omitted so tmux falls back to its
    # own idea of the most recently active client.
    local client
    client=$(tmux list-clients -F '#{client_name}	#{client_session}' 2>/dev/null |
        awk -F'\t' -v session="$session" '$2 == session { print $1; exit }')

    local target=()
    [[ -n $client ]] && target=(-c "$client")

    # A pane target resolves session, window and pane in one step; the
    # three-step form races, as ,agents' comment explains at more length.
    tmux switch-client ${target[@]+"${target[@]}"} -t "$pane" 2>/dev/null || return 0

    # Sinks this pane to the bottom of its state group in `list`, so the next
    # left click reaches for a different session. Ignored unless the pane is
    # blocked, which ,agent-state decides for itself.
    [[ -x $STATE_SCRIPT ]] && "$STATE_SCRIPT" visited "$pane" 2>/dev/null

    # Raises the most recently used Ghostty window, which is the right one when
    # a single window holds the tmux client. With several, macOS decides. The
    # bundle id rather than -a Ghostty, since a name lookup can find the wrong
    # copy.
    open -b com.mitchellh.ghostty
}

main() {
    local command=${1-status}
    shift || true

    case $command in
        status) cmd_status ;;
        click) cmd_click ;;
        jump) cmd_jump "$@" ;;
        *)
            echo "usage: agents.sh <status|click|jump PANE>" >&2
            return 2
            ;;
    esac
}

main "$@"
