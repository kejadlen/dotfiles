# Personal Zsh configuration file. It is strongly recommended to keep all
# shell customization and configuration (including exported environment
# variables such as PATH) in this file or in files sourced from it.
#
# Documentation: https://github.com/romkatv/zsh4humans/blob/v5/README.md.

[ -z "$ZPROF" ] || zmodload zsh/zprof

# Periodic auto-update on Zsh startup: 'ask' or 'no'.
# You can manually run `z4h update` to update everything.
zstyle ':z4h:' auto-update      'ask'
# Ask whether to auto-update this often; has no effect if auto-update is 'no'.
zstyle ':z4h:' auto-update-days '7'

# Keyboard type: 'mac' or 'pc'.
zstyle ':z4h:bindkey' keyboard  'mac'

# Don't start tmux.
zstyle ':z4h:' start-tmux       'yes'

# Mark up shell's output with semantic information.
zstyle ':z4h:' term-shell-integration 'yes'

zstyle ':z4h:' prompt-at-bottom 'yes'

# Right-arrow key accepts one character ('partial-accept') from
# command autosuggestions or the whole thing ('accept')?
zstyle ':z4h:autosuggestions' forward-char 'accept'

# Recursively traverse directories when TAB-completing files.
zstyle ':z4h:fzf-complete' recurse-dirs 'yes'
zstyle ':z4h:fzf-complete' fzf-bindings tab:repeat

# Enable direnv to automatically source .envrc files.
zstyle ':z4h:direnv'         enable 'yes'
# Show "loading" and "unloading" notifications from direnv.
zstyle ':z4h:direnv:success' notify 'yes'

# Enable ('yes') or disable ('no') automatic teleportation of z4h over
# SSH when connecting to these hosts.
# zstyle ':z4h:ssh:example-hostname1'   enable 'yes'
# zstyle ':z4h:ssh:*.example-hostname2' enable 'no'
# The default value if none of the overrides above match the hostname.
zstyle ':z4h:ssh:*'                   enable 'no'

zstyle ':completion:*:ssh:argument-1:'       tag-order  hosts users
zstyle ':completion:*:scp:argument-rest:'    tag-order  hosts files users
zstyle ':completion:*:(ssh|scp|rdp):*:hosts' hosts

zstyle ':z4h:term-title:ssh' preexec '%n@'${${${Z4H_SSH##*:}//\%/%%}:-%m}': ${1//\%/%%}'
zstyle ':z4h:term-title:ssh' precmd  '%n@'${${${Z4H_SSH##*:}//\%/%%}:-%m}': %~'

# https://github.com/romkatv/zsh4humans/issues/53#issuecomment-706493865
zstyle ':zle:up-line-or-beginning-search'   leave-cursor true
zstyle ':zle:down-line-or-beginning-search' leave-cursor true

zstyle ':z4h:*' fzf-flags --color=hl:7,hl+:7

# Send these files over to the remote host when connecting over SSH to the
# enabled hosts.
# zstyle ':z4h:ssh:*' send-extra-files '~/.nanorc' '~/.env.zsh'

# Clone additional Git repositories from GitHub.
#
# This doesn't do anything apart from cloning the repository and keeping it
# up-to-date. Cloned files can be used after `z4h init`. This is just an
# example. If you don't plan to use Oh My Zsh, delete this line.
# z4h install ohmyzsh/ohmyzsh || return

# Install or update core components (fzf, zsh-autosuggestions, etc.) and
# initialize Zsh. After this point console I/O is unavailable until Zsh
# is fully initialized. Everything that requires user interaction or can
# perform network I/O must be done above. Everything else is best done below.
z4h init || return

# Extend PATH.
path=(
  ~/.dotfiles/bin
  $path
)

# Export environment variables.
export GPG_TTY=$TTY

export EDITOR=nvim
export VISUAL=nvim

export BAT_THEME=ashes
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
export FZF_TMUX_OPTS="-p80%,60%"
export FZF_DEFAULT_COMMAND="fd --type f --strip-cwd-prefix --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --strip-cwd-prefix --hidden --follow --exclude .git"

export RUBY_YJIT_ENABLE=true

# Source additional local files if they exist.
if (( $+commands[fzf] )); then
  [[ $- == *i* ]] && z4h source ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh}
fi
z4h source ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/opt/chruby/share/chruby/chruby.sh}
z4h source ~/.dotfiles/src/fzf-git.sh/fzf-git.sh

# Use additional Git repositories pulled in with `z4h install`.
#
# This is just an example that you should delete. It does nothing useful.
# z4h source ohmyzsh/ohmyzsh/lib/diagnostics.zsh  # source an individual file
# z4h load   ohmyzsh/ohmyzsh/plugins/emoji-clock  # load a plugin

# Define key bindings.
z4h bindkey undo Ctrl+/   Shift+Tab  # undo the last command line change
# z4h bindkey redo Option+/            # redo the last undone command line change

# z4h bindkey z4h-cd-back    Shift+Left   # cd into the previous directory
# z4h bindkey z4h-cd-forward Shift+Right  # cd into the next directory
# z4h bindkey z4h-cd-up      Shift+Up     # cd into the parent directory
# z4h bindkey z4h-cd-down    Shift+Down   # cd into a child directory

# history
z4h bindkey z4h-up-prefix-local Ctrl+P
z4h bindkey z4h-down-prefix-local Ctrl+N
z4h bindkey z4h-up-prefix-global Option+P
z4h bindkey z4h-down-prefix-global Option+N

# navigation
z4h bindkey z4h-forward-zword Ctrl+F
z4h bindkey z4h-backward-zword Ctrl+B # conflicts w/tmux prefix, find a better alternative?

z4h bindkey magic-space Space

if (( $+commands[fzf] )); then
  z4h source ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh}

  # https://github.com/junegunn/fzf/issues/164#issuecomment-581837757
  z4h bindkey fzf-cd-widget ç

  # https://blog.revathskumar.com/2024/02/curl-fuzzy-search-options-using-fzf.html
  _fzf_complete_curl() {
    _fzf_complete --header-lines=1 --prompt="curl> " -- "$@" < <(
      curl -h all
    )
  }

  _fzf_complete_curl_post() {
    awk '{print $1}' | cut -d ',' -f -1
  }
fi

# Autoload functions.
autoload -Uz zmv

# Define functions and completions.
function md() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }
compdef _directories md

# https://docs.brew.sh/Shell-Completion
if type brew &>/dev/null; then
  FPATH=${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share/zsh/site-functions:${FPATH}}

  autoload -Uz compinit
  compinit
fi

# has to go after compinit
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

# Define named directories: ~w <=> Windows home directory on WSL.
# [[ -z $z4h_win_home ]] || hash -d w=$z4h_win_home

# Define aliases.
alias be='bundle exec'
alias clear=z4h-clear-screen-soft-bottom
(( $+commands[eza] )) && alias ls=eza
alias git='noglob git' # so that shortcuts like @^ work
alias rake='noglob rake' # don't match on square brackets
alias tat='tmux new-session -As `basename $PWD | ruby -e "puts ARGF.read.strip.downcase.gsub(/[^\w]+/, ?-)"`'
alias tree='eza --tree'

# Add flags to existing aliases.
alias ls="${aliases[ls]:-ls} -A"

# Set shell options: http://zsh.sourceforge.net/Doc/Release/Options.html.
setopt glob_dots  # no special treatment for file names with a leading dot
setopt auto_menu  # require an extra TAB press to open the completion menu

# https://github.com/romkatv/zsh4humans/issues/110#issuecomment-846824056
[[ ! -v functions[command_not_found_handler] ]] || unfunction command_not_found_handler

# default to ruby 3.3
which chruby &>/dev/null && chruby 3.3

for file in ~/.config/zsh/*(N); z4h source $file

[ -z "$ZPROF" ] || zprof
