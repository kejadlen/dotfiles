# https://tratt.net/laurie/blog/2024/faster_shell_startup_with_shell_switching.html
if [[ $- == *"i"* ]]; then
  exec zsh
fi
