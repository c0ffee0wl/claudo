#!/bin/zsh

# Ensure Claude Code config has hasCompletedOnboarding to skip first-run prompts in piped mode
config_file="/claude-config/.claude.json"
if [[ -f "$config_file" ]]; then
    if ! jq -e '.hasCompletedOnboarding' "$config_file" &>/dev/null; then
        jq '. + {hasCompletedOnboarding: true}' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
    fi
else
    echo '{"hasCompletedOnboarding": true}' > "$config_file"
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
