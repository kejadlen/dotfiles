if status is-interactive
    # disable default greeting
    set -g fish_greeting

    bind tab complete-and-search

    starship init fish | source
    fzf --fish | source
end
