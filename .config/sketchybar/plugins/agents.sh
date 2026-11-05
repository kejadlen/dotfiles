#!/usr/bin/env bash

# The agents item: how many agent sessions ,agent-state finds in Rex, and a way
# into whichever one needs attention. Three roles in one script, picked by the
# first argument, so the state colors and the Rex logic have one home:
#
#   (none)              draw the item — most urgent state and its count, hidden if idle
#   click               left jumps to the most urgent session, right opens the popup
#   jump SESSION BLOCK  focus that Rex block and bring Rex forward
#
# State is re-read on every invocation rather than cached, so a click lands on
# what is true now instead of what the bar last drew. Nothing pushes state
# changes here, so the item polls on update_freq.
#
# sketchybar runs under launchd with a minimal PATH, and ,agent-state needs rex
# and sqlite3. Without them `list` fails and the item stays hidden instead of
# visibly broken — hence the explicit PATH.

set -uo pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

# Rex puts its CLI on PATH only inside its own blocks.
export PATH="$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS:$HOME/.dotfiles/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

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

# The same colors ,agents uses, so the bar and the picker agree.
readonly COLOR_BLOCKED=0xffff5f5f
readonly COLOR_DONE=0xffffd75f
readonly COLOR_WORKING=0xff888888

# Nerd Font glyphs rather than emoji, because these go in a *label* and a label
# takes one font — the default SauceCodePro Nerd Font, which has no emoji
# coverage. An emoji there would draw as nothing at all, the way icon=🤖 did
# before it got an explicit Apple Color Emoji font. These are Material Design
# icons (alert-circle, check-circle, sleep, cog), which Nerd Fonts v3 carries at
# the codepoints MDI itself assigns.
readonly GLYPH_BLOCKED=󰀨
readonly GLYPH_DONE=󰗠
readonly GLYPH_IDLE=󰒲
readonly GLYPH_WORKING=󰒓

state_rows() {
    [[ -x $STATE_SCRIPT ]] || return 0
    "$STATE_SCRIPT" list 2>/dev/null
}

color_for() {
    case ${1-} in
        blocked | error) printf '%s' "$COLOR_BLOCKED" ;;
        done) printf '%s' "$COLOR_DONE" ;;
        *) printf '%s' "$COLOR_WORKING" ;;
    esac
}

glyph_for() {
    case ${1-} in
        blocked | error) printf '%s' "$GLYPH_BLOCKED" ;;
        done) printf '%s' "$GLYPH_DONE" ;;
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

    # list already orders blocked, done, idle, then working, so the first row
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
    local row
    row=$(state_rows | head -n 1)
    [[ -n $row ]] || return 0
    cmd_jump "$(cut -f 9 <<<"$row")" "$(cut -f 6 <<<"$row")"
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
        local state _label dir age message block _app kind session
        # Fields are re-joined on US (0x1f) before reading them. Tab counts as
        # IFS whitespace, so `read` collapses a run of tabs into one delimiter
        # and silently shifts every later field left — a session with no message
        # would land its block id in `message` and leave `block` empty. US is
        # not whitespace, so empty fields survive.
        # session:window is read but not shown: clicking a row goes to the block
        # directly, so the coordinate is noise here. ,agents still lists it.
        while IFS=$'\x1f' read -r state _label dir age message block _app kind session; do
            [[ -n $message ]] || message=$kind
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
                click_script="\"$SELF\" jump $session $block"
            index=$((index + 1))
        done <<<"$(tr '\t' '\037' <<<"$rows")"
    fi

    sketchybar --set "$ITEM" popup.drawing=on
}

cmd_jump() {
    local session=${1:-} block=${2:-}
    [[ -n $session && -n $block ]] || return 0

    # Harmless when the popup is already closed, which is the left-click case.
    sketchybar --set "$ITEM" popup.drawing=off >/dev/null 2>&1 || true

    # Selecting the session is what makes the app show it; focusing the block
    # makes its window active.
    rex --autostart=false "do" session.select session_id="$session" >/dev/null 2>&1 || return 0
    rex --autostart=false focus -s "$session" "$block" >/dev/null 2>&1 || return 0

    # Sinks a blocked session to the bottom of its state group in `list`, so the
    # next left click reaches for a different one, and shows a done one as idle.
    # A visit can change the leading state, so the item redraws after.
    [[ -x $STATE_SCRIPT ]] && "$STATE_SCRIPT" visited "$block" 2>/dev/null
    cmd_status

    open -b com.superlogical.rex
}

main() {
    local command=${1-status}
    shift || true

    case $command in
        status) cmd_status ;;
        click) cmd_click ;;
        jump) cmd_jump "$@" ;;
        *)
            echo "usage: agents.sh <status|click|jump SESSION BLOCK>" >&2
            return 2
            ;;
    esac
}

main "$@"
