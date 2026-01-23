#!/bin/zsh

# Ensure hostname resolves (needed for sudo when using --host network mode)
grep -q "$(hostname)" /etc/hosts 2>/dev/null || echo "127.0.0.1 $(hostname)" | sudo tee -a /etc/hosts >/dev/null 2>&1

# Ensure Claude Code config has required flags to skip first-run prompts in piped mode
config_file="$HOME/.claude/.claude.json"
required_flags='{"hasCompletedOnboarding": true, "bypassPermissionsModeAccepted": true}'
if [[ -f "$config_file" ]]; then
    # Add any missing flags from required_flags
    jq -s '.[0] * .[1]' "$config_file" <(echo "$required_flags") > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
else
    echo "$required_flags" > "$config_file"
fi

# Fix plugin/marketplace paths - create symlinks for foreign home directories
# This allows plugins installed on host (e.g., /root/.claude) to work in container (/home/claudo/.claude)
for f in ~/.claude/plugins/installed_plugins.json ~/.claude/plugins/known_marketplaces.json ~/.claude.json; do
    [[ -f "$f" ]] || continue
    # Match any path containing /.claude (handles installPath, installLocation, etc.)
    grep -oE '"/[^"]+/.claude[^"]*"' "$f" 2>/dev/null | tr -d '"' | \
        sed 's|/.claude.*|/.claude|' | sort -u | while read -r claude_dir; do
        foreign_home="${claude_dir%/.claude}"
        if [[ -n "$foreign_home" && "$foreign_home" != "$HOME" && ! -e "$claude_dir" ]]; then
            sudo mkdir -p "$foreign_home"
            sudo ln -sfn "$HOME/.claude" "$claude_dir"
        fi
    done
done

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
