#!/bin/zsh

# Ensure Claude Code config has required flags to skip first-run prompts in piped mode
config_file="$HOME/.claude/.claude.json"
required_flags='{"hasCompletedOnboarding": true, "bypassPermissionsModeAccepted": true}'
if [[ -f "$config_file" ]]; then
    # Add any missing flags from required_flags
    jq -s '.[0] * .[1]' "$config_file" <(echo "$required_flags") > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
else
    echo "$required_flags" > "$config_file"
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
