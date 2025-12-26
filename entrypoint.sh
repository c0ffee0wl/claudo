#!/bin/zsh

if [[ $# -eq 0 ]]; then
    exec /bin/zsh -li
elif [[ -t 0 ]]; then
    # Interactive with TTY - load full config
    exec /bin/zsh -lic "$*"
else
    # Non-interactive (piped input) - source zshrc and execute command directly
    source ~/.zshrc
    "$@"
fi
