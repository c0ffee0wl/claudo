# claudo

*claudo* = *claud*e in *do*cker

Run Claude Code inside a Docker container for isolation, mounting the current
directory for easy access to your project.

The idea: It is so effective to run claude without `--dangerously-skip-permissions`, but also dangerous. Claude might go wild and [delete your home directory](https://www.reddit.com/r/ClaudeAI/comments/1pgxckk/claude_cli_deleted_my_entire_home_directory_wiped/).
It might be attacked by a prompt injection.

To develop with claude code, I would usually setup a devcontainer environment to isolate the project - but in quick and dirty cases where I just need AI help with filesystem access, I would not bother to do the 2 minute setup. I just want a quick command like `claude` on the CLI which gives me the AI powers.

`claudo` does that, but runs `claude --dangerously-skip-permissions` in a docker container. It will:

- mount the current directory into `/workspaces/`
- mounts your `~/.claude` directory inside the container and sets `CLAUDE_CONFIG_DIR=~/.claude` (this is needed so you dont need to re-authenticate with your subscription everytime)

Optionally it allows you to:

- run docker-in-docker (use `--dind`)
- mount your gitconfig (readonly) into the container so you can commit inside the container (use `--git`)


## Usage

```bash
./claudo                      # run claude interactively
./claudo -- zsh               # open zsh shell
./claudo -- claude --help     # run claude with args
echo "fix the bug" | ./claudo # pipe prompt to claude
```

### Options

- `-e KEY=VALUE` - set environment variable
- `--host` - use host network
- `-n NAME` - create persistent container `claudo-NAME`
- `--no-sudo` - use image without sudo

See `./claudo --help` for more.
