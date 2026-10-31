# ctrl+t in Rex: float the fzf file picker over the pane instead of the
# inline FZF_DEFAULT_OPTS UI. The widget only launches the float and returns
# immediately; the float's command sends the pick back as typed bytes (no
# trailing newline, so it lands on the command line at the cursor) and
# refocuses this pane on its way out. Other programs (nvim, ssh) keep ctrl+t
# — the app keymap never sees it. Outside Rex the builtin fzf-file-widget
# runs unchanged.
#
# Two rex gotchas are baked into the float command, both verified the hard
# way: rex wait never observes a layer block's end on some builds (it burns
# its 10s default timeout and exits 0), so the pick is sent from inside the
# float instead of waited on; and layer commands containing newlines
# silently execute nothing on some builds, so the command is one line.

fzf-file-widget-rex() {
    if [[ -n "${REX_SESSION:-}" ]]; then
        __fzf_rex_pick
    else
        zle fzf-file-widget
    fi
}

__fzf_rex_pick() {
    emulate -L zsh
    command -v rex jq >/dev/null || return 1

    local picker="${HOME}/.dotfiles/bin/,f"
    # TODO: Drop the PATH export if new_layer gains the --interactive option from Rex af0c204.
    local cmd="export PATH=${(q)PATH}; t=\$(mktemp); ${(q)picker} \"\$t\"; if [[ -s \"\$t\" ]]; then rex block call -s ${(q)REX_SESSION} -b ${(q)REX_BLOCK} write \"\$(jq -cRs 'rtrimstr(\"\n\") | {data:.}' \"\$t\")\" >/dev/null; fi; rm -f \"\$t\"; rex focus -s ${(q)REX_SESSION} ${(q)REX_BLOCK} >/dev/null 2>&1 || true"
    rex api call -s "$REX_SESSION" session.new_layer \
        "$(jq -n --arg c "$cmd" --arg cwd "$PWD" \
            '{bounds: [0.1, 0.2, 0.8, 0.6], focus: true,
              layout: {block: {flavor: "com.superlogical.terminal.shell",
                               label: "files",
                               options: {command: ["/bin/zsh", "-c", $c],
                                         cwd: $cwd, shell: "none"}}}}')" >/dev/null
}

zle -N fzf-file-widget-rex
z4h bindkey fzf-file-widget-rex Ctrl+T
