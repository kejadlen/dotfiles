# https://tratt.net/laurie/blog/2024/faster_shell_startup_with_shell_switching.html
case $- in
  *i* )
    if command -v zsh > /dev/null; then
        # make sure zsh actually runs
        zsh --version > /dev/null && exec zsh
        echo "Couldn't run 'zsh'" > /dev/stderr
    fi
    ;;
esac
