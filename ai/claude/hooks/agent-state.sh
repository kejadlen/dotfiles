#!/usr/bin/env bash

# Reports this Claude Code session's state to ,agent-state, which backs the
# prefix+A session picker in tmux.
#
# Registered in ~/.claude/settings.json against the events in the case
# statement below. Hooks run synchronously inside Claude's tool loop, so this
# stays quiet and always exits 0 — a session picker is never worth breaking a
# session over.

set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
# ,agent-state complains to stderr when sqlite3 is missing, which is right for
# a human at a prompt but would repeat on every tool call in here.
command -v sqlite3 >/dev/null 2>&1 || exit 0

# The pane is the row's identity, so there is nothing to record outside tmux.
# It has to come from $TMUX_PANE, which tmux sets for every process in a pane:
# an untargeted `tmux display-message -p '#{pane_id}'` reports whichever pane
# the client is *looking at*, which is rarely the one Claude runs in.
[[ -n "${TMUX_PANE:-}" ]] || exit 0

state_script="$HOME/.dotfiles/ai/bin/,agent-state"
[[ -x $state_script ]] || exit 0

payload=$(cat) || exit 0

# Fields are joined on US (0x1f) rather than @tsv's tab. Tab counts as IFS
# whitespace, so `read` would collapse a run of them into one delimiter and
# silently shift every later field left — an absent agent_id would land the cwd
# in agent_id and trip the subagent guard below on every event. US is not
# whitespace, so empty fields survive. Newlines are scrubbed in jq because
# `read` stops at the first one.
fields=$(jq -r '
    # Each `| flat` needs its own parens: jq binds `,` tighter than `|`, so
    # without them the whole filter reads as one pipeline and errors out.
    def flat: (. // "") | tostring | gsub("[\r\n\t]"; " ");
    [
      (.hook_event_name | flat),
      (.agent_id        | flat),
      (.cwd             | flat),
      (.message         | flat),
      (.tool_name       | flat)
    ] | join("\u001f")
' <<<"$payload" 2>/dev/null) || exit 0

IFS=$'\x1f' read -r event agent_id cwd message tool <<<"$fields"

# A subagent's hooks carry an agent_id and share their parent's pane, so
# letting them report would have background tool calls overwrite the state of
# the session the user actually interacts with.
[[ -z $agent_id ]] || exit 0

# SubagentStop is deliberately absent from the case below and must stay that
# way. It is a completion event that recap and away-summary can fire *after*
# the main turn has already stopped, which would flip a finished session back
# to working and drop it to the bottom of the picker.
changed=""
case $event in
    Notification|PreToolUse)
        # Wired only for permission_prompt notifications and for
        # AskUserQuestion, which raises no notification of its own. Both mean
        # Claude has stopped and cannot continue without the user.
        #
        # What gets recorded is the *reason*, short enough to read in one
        # column. A notification's own text is nearly all boilerplate —
        # "Claude needs your permission to use Bash" — so the prefix comes off
        # and whatever names the tool is what remains. PreToolUse doesn't set
        # message at all, but it names the tool in a field.
        if [[ -n $tool ]]; then
            message=$tool
        else
            message=${message#Claude needs your permission to use }
            message=${message#Claude needs your permission to }
            message=${message#Claude needs your permission}
            message=${message%.}
            # Distinct from the 'waiting for input' a question gets: this
            # session is stopped on a permission prompt, tool unknown.
            [[ -n $message ]] || message='needs permission'
        fi
        "$state_script" record blocked "$cwd" "$message" || true
        changed=1
        ;;
    Stop)
        "$state_script" record idle "$cwd" 'turn finished' || true
        changed=1
        ;;
    UserPromptSubmit|PostToolUse|PermissionDenied)
        "$state_script" record working "$cwd" '' || true
        changed=1
        ;;
    SessionEnd)
        "$state_script" clear || true
        changed=1
        ;;
esac

# Pushes the new state at sketchybar's agents item instead of leaving it to
# poll. --trigger is a message to the running instance over its socket, so this
# costs one short-lived process and never blocks on the bar redrawing.
#
# Absent in ramekin containers and on any non-macOS host, so a missing binary is
# a silent skip, not an error. The opt path is the fallback because Claude's
# hook environment does not always carry a Homebrew PATH.
if [[ -n $changed ]]; then
    sketchybar_bin=$(command -v sketchybar) ||
        sketchybar_bin=/opt/homebrew/opt/sketchybar/bin/sketchybar
    if [[ -x $sketchybar_bin ]]; then
        "$sketchybar_bin" --trigger agent_state_change >/dev/null 2>&1 || true
    fi
fi

exit 0
