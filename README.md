# claudo

**claudo** = **clau**de in po**d**man (or d**o**cker) / (**claudō**, [latin for "to restrict", "to imprison"](https://en.wiktionary.org/wiki/claudo))

Run Claude Code inside a Podman container for isolation, mounting the current
directory for easy access to your project.

The idea: It is so effective to run claude with `--dangerously-skip-permissions`, but also dangerous. Claude might go wild and [delete your home directory](https://www.reddit.com/r/ClaudeAI/comments/1pgxckk/claude_cli_deleted_my_entire_home_directory_wiped/).
It might be attacked by a prompt injection.

To develop with claude code, I would usually setup a devcontainer environment to isolate the project - but in quick and dirty cases where I just need AI help with filesystem access, I would not bother to do the 2 minute setup. I just want a quick command like `claude` on the CLI which gives me the AI powers.

`claudo` does that, by running `claude --dangerously-skip-permissions` in a Podman container.

At its core `claudo` is a shortcut that translates into this (plus a few more additional features, see below):

```bash
podman run -it --rm \
    --userns=keep-id:uid=1000,gid=1000 \
    --hostname claudo \
    -v $HOME/.claudo:/claude-config \
    -v $HOME/.claude/skills:/claude-config/skills:ro \
    -e CLAUDE_CONFIG_DIR=/claude-config \
    -v $PWD:/workspaces/$(basename $PWD) \
    -w /workspaces/$(basename $PWD) \
    ghcr.io/c0ffee0wl/claudo:latest \
    claude --dangerously-skip-permissions
```

Note: The container uses `~/.claudo` (not `~/.claude`) on the host for its config, keeping it separate from your host Claude Code installation. Skills from `~/.claude/skills` are mounted read-only at `/claude-config/skills`.

![claudo demo](demo/demo.gif)

## Features

- Mounts the current directory into `/workspaces/`
- Mounts `~/.claudo` at `/claude-config` for authentication persistence (no re-login required)
- Mount additional directories with `-m` (read-only by default, append `:rw` for read-write)
- Automatic UID/GID mapping - works with any host user including root
- Host Docker socket mounting (`--docker-socket`) for sibling containers
- Git config mounting for commits inside container (`--git`)
- Named persistent containers (`-n`)
- Security hardening with `--no-sudo` or `--no-privileges`
- Isolated mode without directory mount (`--tmp`)
- Custom image support (`-i` or `$CLAUDO_IMAGE`)
- See the `podman run` command without executing it so you can inspect how it works under the hood (`--dry-run`)

## Usecases

A few things I do regularly with `claudo`:

### Exploring code bases

Exploring a code base. Agents are exceptionally good at exploring code bases quickly. So if you have a question about an undocumented feature, just ask claude to clone the repo and work with it.

E.g.:

1. start `claudo --tmp`
2. Prompt with something like `Clone https://github.com/leeoniya/uPlot Give me an architectural overview of the library.`

### Chore on your local files

Have a bunch of scanned files with strange filenames?

Ask claudo to rename them appropriately:

```bash
claudo -p 'This directory contains a set of scanned sheet music. Please read them, find the composer name and the title of the song and rename the files appropriatelly in the format: "<SONG TITLE>, <COMPOSER>, <YEAR> (<MUSICAL KEY>).pdf Skip the year if nothing is mentioned in the PDF.'
```

### Create one-of scripts

I had the need to geocode a few images. I just asked claude to create a script for this, but since I don't want it to have access to all my images I just placed a `.jpg` for it to work on in a directory and then prompted it to create a bash script to use a free geocoding API.

Boom, worked. Without exposing all my private images to Claude.

I then could use the generated script on all my images without privacy concerns.

This is how these scripts were created: https://gist.github.com/gregmuellegger/3699d8ffb26ea39fb617c6e153f1775f

## Security Considerations

`claudo` runs inside a Podman container. This safeguards from the most obvious attacks. However keep in mind that the code still runs on your local computer, so any security vulnerability in Podman might be exploited. Also there are a few specifics about `claudo` that you should be aware of:

- **`~/.claudo` is mounted read-write** as the container's Claude config directory. Code running in the container can modify this configuration. Your host's `~/.claude` is not directly exposed (only skills are shared read-only).
- **`--docker-socket` grants host root equivalent access.** The Docker socket allows full control of the host via Docker. Only use when you trust the code running inside.

The default image used is `ghcr.io/c0ffee0wl/claudo:latest`. It is based on Ubuntu 24.04 with Claude Code pre-installed. Includes common dev tools: git, ripgrep, fd, fzf, jq, make, nano, tree, zsh (with oh-my-zsh), Node.js, uv, and docker-cli.

The image is updated weekly to incorporate latest Ubuntu security patches (using `apt upgrade`). But you need to `claudo --pull` yourself to get the updates.

## Installation

Requires [Podman](https://podman.io/) to be installed.

Install by placing the `claudo` script in your `~/.local/bin` directory. Make sure it is on `$PATH`.

```bash
curl -fsSL https://raw.githubusercontent.com/c0ffee0wl/claudo/main/claudo -o ~/.local/bin/claudo && chmod +x ~/.local/bin/claudo
```

## Examples

```bash
claudo                        # run claude interactively
claudo -- zsh                 # open zsh shell
claudo -- claude --help       # run claude with args
echo "fix the bug" | claudo   # pipe prompt to claude
claudo --docker-socket        # use host Docker socket (sibling containers)
```

## Usage

<!--[[[cog
import cog
import subprocess
result = subprocess.run(['./claudo', '--help'], capture_output=True, text=True)
cog.outl('```')
cog.out(result.stdout)
cog.outl('```')
]]]-->
```
claudo - Run Claude Code in a Podman container

Usage: claudo [OPTIONS] [--] [COMMAND...]

Options:
  -e KEY=VALUE    Set environment variable in container (can be used multiple times)
  -p, --prompt PROMPT  Run claude with -p (prompt mode)
  -i, --image IMG Use specified container image (default: $CLAUDO_IMAGE or built-in)
  --host          Use host network mode
  --no-sudo       Disable sudo (adds no-new-privileges restriction)
  --no-privileges Drop all capabilities (most restrictive)
  --no-network    Disable network access (breaks Claude Code)
  --docker-socket Mount host Docker socket (sibling containers, host root equivalent)
  --git           Mount git config (~/.gitconfig and credentials) for committing
  --pull          Always pull the latest image before running
  -n, --name NAME Create a named container 'claudo-NAME' that persists after exit
  -a, --attach NAME  Attach to existing container 'claudo-NAME'
  --tmp           Run isolated (no directory mount, workdir /workspaces/tmp)
  -v, --verbose   Display podman command before executing
  --dry-run       Show podman command without executing (implies --verbose)
  --docker-opts OPTS  Pass additional options to podman run
  -h, --help      Show this help message

Arguments after -- are passed to claude if they start with -, otherwise as the container command.

Examples:
  claudo                          Run claude --dangerously-skip-permissions (default)
  claudo -e API_KEY=xxx           Start with environment variable
  claudo -i claudo-base:latest    Use a different image
  claudo --host                   Start with host networking
  claudo --no-sudo                Start without sudo privileges
  claudo --no-privileges          Start with all caps dropped
  claudo --no-network             Start without network access
  claudo --docker-socket          Use host Docker socket (sibling containers)
  claudo --git                    Enable git commits from inside container
  claudo -n myproject             Start named persistent container
  claudo -a myproject             Attach to existing container
  claudo -- --resume              Resume a conversation (shows picker)
  claudo -- --resume last         Resume the last conversation
  claudo -- -c                    Continue the most recent conversation
  claudo -- zsh                   Run zsh instead of claude
  claudo -n dev -e DEBUG=1 -- -c  Combined options with claude flags

The current directory is mounted at /workspaces/<dirname>.
~/.claudo is mounted at /claude-config for container config.
~/.claude/skills is mounted at /claude-config/skills (read-only).

LLM API environment variables are automatically passed through if set:
  ANTHROPIC_API_KEY, OPENAI_API_KEY, AZURE_OPENAI_API_KEY, GOOGLE_API_KEY,
  GEMINI_API_KEY, MISTRAL_API_KEY, GROQ_API_KEY, and others (AWS, HuggingFace, etc.)
```
<!--[[[end]]]-->

## Use your own container image

You don't trust my container image? I wouldn't trust yours either! Since we
established mutual distrust, lets talk about how you can use this project
anyways.

If you inspected the `claudo` script and installed it, you can specify your own
image by setting the `CLAUDO_IMAGE` env variable, e.g. in your
`.bashrc`/`.zshrc`.

Another alternative is to install the `claudo` script and during installation
adjust the used image name:

```bash
curl -fsSL https://raw.githubusercontent.com/c0ffee0wl/claudo/main/claudo | \
  sed 's|ghcr.io/c0ffee0wl/claudo:latest|<YOUR-IMAGE-HERE>:latest|' | \
  tee ~/.local/bin/claudo > /dev/null && chmod +x ~/.local/bin/claudo
```

Your image must fulfill these requirements:

- `claude` installed and on PATH
- User home directory at `/home/claudo`
- `/workspaces/` directory exists (for working directory mounts)
- `/claude-config/` directory exists with correct ownership (for config and skills mounts)
- For `--tmp` to work: `/workspaces/tmp/` needs to exist and writable for `claudo` user

### Forking

The other approach is, to just fork this repo. Feel free to! Then review the
Dockerfile, adjust it to your needs and push your fork. The Github Actions are
setup so that the new image is built after push, and an updated image is created
every week.

Then go ahead and either set `CLAUDO_IMAGE` or also adjust the `claudo` script
of your fork to use your own image.
