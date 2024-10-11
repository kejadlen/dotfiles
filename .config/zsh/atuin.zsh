### atuin

# export ATUIN_NOBIND=true
# eval "$(atuin init zsh)"

# Reference: https://github.com/junegunn/fzf/discussions/3099
fzf-atuin-history-widget() {
  local selected
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases noglob nobash_rematch 2> /dev/null
  selected="$(atuin history list --format "{time} {command}" --reverse false --print0 |
    FZF_DEFAULT_OPTS=$(__fzf_defaults "" "-n3..-2 --scheme=history --bind=ctrl-r:toggle-sort --wrap-sign '\t↳ ' --highlight-line ${FZF_CTRL_R_OPTS-} --query=${(qqq)LBUFFER} +m --read0") \
    FZF_DEFAULT_OPTS_FILE='' $(__fzfcmd))"
  local ret=$?
  if [ -n "$selected" ]; then
    if [[ $(awk '{print $1; exit}' <<< "$selected") =~ ^[1-9][0-9]* ]]; then
      zle vi-fetch-history -n $MATCH
    else # selected is a custom query, not from history
      LBUFFER="$selected"
    fi
  fi
  zle -U "$selected"
  zle kill-buffer
  zle reset-prompt
  return $ret
}
# zle      -N       fzf-history-widget
# bindkey '^R'      fzf-history-widget

# vim: ft=zsh
