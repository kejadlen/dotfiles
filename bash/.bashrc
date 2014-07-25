# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

if [ -z "$SSH_CLIENT" ]; then
  # PS1='\[\e[32m\]\h\[\e[00m\]:\[\e[36m\]\w\[\e[00m\]\$ '
  PS1='\[\e[36m\]\w\[\e[00m\]\$ '
else
  PS1='\[\e[32m\]\h\[\e[00m\]:\[\e[36m\]\w\[\e[00m\]\$ '
  [[ -d /usr/local/bin ]] && export PATH=/usr/local/bin:/usr/local/sbin:$PATH
  function spbcopy { ssh `echo $SSH_CONNECTION | awk '{print $1}'` pbcopy; }
fi

#history 
shopt -s histappend
export HISTCONTROL=ignoreboth
export HISTSIZE=200000
export HISTFILESIZE=200000
export PROMPT_COMMAND='history -a'
trap "history -a" EXIT

export IGNOREEOF=1

export GREP_OPTIONS='--color=auto'
export LESS=RX
export EDITOR=vim
export VISUAL=vim

# export RUBYOPT=rubygems

# export NODE_PATH=/usr/local/lib/node_modules

export LSCOLORS=dxfxcxdxbxegedabagacad

# alias pbconvert="pbpaste | ruby -pe '\$_.gsub!(/\r\n|\r/, \"\n\")' | pbcopy"
alias ls="ls -GF"
alias ql="qlmanage -p"
alias be="bundle exec"

function eject { command hdiutil eject `df | grep Volumes | grep "$@" | ruby -ne 'puts $_[/^[^ ]*/]'`; }
function tabname { printf "\e]1;$1\a"; }
# function winname { printf "\e]2;$1\a"; }
# function ssh { command tabname $1 && ssh $@; }
# function ssh() { echo "$@" | echo `sed -E 's/(.*@)?([-a-zA-Z0-9\.]*)(.*)/\2/'`; } # ssh "$@"; tabname; }

# [[ -s "$HOME/Dropbox/src/z/z.sh" ]] && . "$HOME/Dropbox/src/z/z.sh"
# [[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
# [[ -s "$HOME/Dropbox/src/external/autojump/autojump.bash" ]] && . "$HOME/Dropbox/src/external/autojump/autojump.bash"

hash rbenv 2>&- && eval "$(rbenv init -)"
hash lesspipe 2>&- && eval "$(SHELL=/bin/sh lesspipe)"

if hash fasd 2>&-; then
  eval "$(fasd --init auto)"
  alias a='fasd -a'
  alias d='fasd -d'
  alias f='fasd -f'
  alias z='fasd_cd -d'
  # alias zz='fasd_cd -d -i'
  alias v='f -e vim'
  # alias mv='f -e mvim'
  _fasd_bash_hook_cmd_complete v
fi

# if which brew; then
if command -v brew &> /dev/null; then
  [[ -f `brew --prefix`/etc/bash_completion ]] && . `brew --prefix`/etc/bash_completion
  # [[ -f `brew --prefix`/etc/autojump.sh ]] && . `brew --prefix`/etc/autojump.sh
fi

[[ -s "$HOME/.bashrc.local" ]] && . "$HOME/.bashrc.local"
