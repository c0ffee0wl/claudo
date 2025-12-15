#!/bin/zsh

# Initialize Docker-in-Docker if enabled
if [[ "$DIND_ENABLED" == "true" ]]; then
    /home/claudo/.local/bin/docker-init.sh
fi

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
