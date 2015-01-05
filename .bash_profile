[[ -d /usr/local/share/npm/bin ]] && export PATH="/usr/local/share/npm/bin:$PATH"
[[ -d /usr/local/bin ]] && export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
# [[ -d "$HOME/.rbenv" ]] && export PATH="$HOME/.rbenv/bin:$PATH"

export PATH=~/bin:~/Dropbox/bin:$PATH

[[ -f ~/.bashrc ]] && . ~/.bashrc

[[ -s "$HOME/.bash_profile.local" ]] && . "$HOME/.bash_profile.local"
