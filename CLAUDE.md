# Claudo

Podman container for running Claude Code in an isolated environment.

## Structure

- `Dockerfile` - Ubuntu 24.04 with zsh, claude and a few tools pre-installed
- `claudo` - Bash script to run the container with various options
- `entrypoint.sh` - Handles interactive vs piped input, sources zsh config
- `justfile` - Build and push commands
- `test.sh` - Test suite for claudo script behavior
- `.github/workflows` - Github Actions to test and build the container image

## Building

```bash
just build   # build image
just push    # build and push to registry
just update-readme  # runs cogapp on the README.md
```

## Key Behaviors

- Default command is `claude --dangerously-skip-permissions`
- Piped input goes to `claude --dangerously-skip-permissions -p`
- `~/.claudo` mounted at `/claude-config` for auth persistence
- `~/.claude/skills` mounted at `/claude-config/skills` (read-only)
- Current directory mounted at `/workspaces/<dirname>`
- `-m PATH` mounts additional directories (read-only by default, append `:rw` for read-write)
- Automatic UID/GID mapping via Podman user namespaces
- `--tmp` runs isolated without mounting current directory
- `--no-sudo` adds `no-new-privileges` security restriction
- `--no-privileges` drops all Linux capabilities

## Guidelines

- All `claudo` options must be documented in `claudo --help`
- New behavior must be tested in `./test.sh`
- Tests must not invoke `claude` in the container
