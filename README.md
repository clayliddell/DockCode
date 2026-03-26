# OpenCode + OpenRouter Docker Sandbox

Custom Docker Sandbox template for running [OpenCode](https://opencode.ai) with [OpenRouter](https://openrouter.ai) as the LLM provider.

## Why

Docker Sandboxes' built-in credential proxy only supports a fixed set of providers (OpenAI, Anthropic, Google, xAI, Groq, AWS). OpenRouter isn't one of them, so the proxy strips its Authorization header. This template works around that by:

1. Bypassing the MITM proxy for OpenRouter domains
2. Injecting the API key via OpenCode's `auth.json`

## Prerequisites

- Docker Desktop for Linux (with `docker sandbox` CLI)
- An OpenRouter API key

## Quick Start

```bash
# Launch from any project directory
cd ~/my-project
./setup.sh launch
```

## Usage

```
Usage: setup.sh <command> [args...]

Commands:
  config show                          Print config file paths
  config update <key> <value>          Update a config value

      Keys:
        opencode.json    Path to opencode.json
        auth.json        Path to auth.json

  launch [-n name] [-w workspace]      Launch or create a sandbox

      -n    Sandbox name (default: current directory name)
      -w    Workspace directory (default: current directory)
```

## Config Management

Settings are stored in `~/.config/dockcode/config`:

| Key | Default | Description |
|---|---|---|
| `OPENCODE_CONFIG` | `~/.config/dockcode/opencode.json` | Path to OpenCode config |
| `AUTH_CONFIG` | `~/.config/dockcode/auth.json` | Path to auth credentials |

### Show current config

```bash
./setup.sh config show
```

### Update config values

```bash
# Use a custom opencode.json
./setup.sh config update opencode.json ~/my-opencode.json

# Use a custom auth.json
./setup.sh config update auth.json ~/my-auth.json
```

### First-run behavior

The `launch` command is non-interactive. On first run:

1. If `~/.config/dockcode/opencode.json` doesn't exist, the project default is copied
2. If `~/.config/dockcode/auth.json` doesn't exist, the project default is copied
3. Edit `~/.config/dockcode/auth.json` to set your API key before launching

## Launch Command

```bash
# Launch in current directory (sandbox named after directory)
cd ~/my-project
./setup.sh launch

# Launch with custom name and workspace
./setup.sh launch -n my-sandbox -w ~/other-project

# Re-launch existing sandbox (no rebuild)
./setup.sh launch -n my-sandbox
```

If a sandbox with the given name already exists, it is launched directly. Otherwise, a new sandbox is created with proxy bypass and auth injection.

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | Extends `docker/sandbox-templates:opencode` with OpenCode config |
| `opencode.json` | Default OpenCode config (OpenRouter models, permissions) |
| `auth.json` | Default auth template (edit to set your API key) |
| `setup.sh` | CLI with config management and sandbox launch |

## Configuration

### Models

Edit `~/.config/dockcode/opencode.json` to change the default models:

```json
{
  "model": "openrouter/anthropic/claude-sonnet-4-5",
  "small_model": "openrouter/anthropic/claude-haiku-4-5",
  "provider": {
    "openrouter": {
      "models": {
        "anthropic/claude-sonnet-4-5": {},
        "openai/gpt-4.1": {}
      }
    }
  }
}
```

### Permissions

Edit the `permission` section to restrict agent capabilities:

```json
{
  "permission": {
    "bash": "ask",
    "edit": "allow",
    "read": "allow"
  }
}
```

### API key

Edit `~/.config/dockcode/auth.json` to set your OpenRouter API key:

```json
{
  "openrouter": {
    "type": "api",
    "key": "sk-or-v1-your-key-here"
  }
}
```

## How It Works

1. **Build** — The Dockerfile bakes `opencode.json` into the image.
2. **Create** — A sandbox is created with the custom template, and OpenRouter domains are bypassed from the MITM proxy.
3. **Inject** — The contents of `auth.json` are written into `~/.local/share/opencode/auth.json` inside the sandbox.

The API key is never stored in the image — only injected at sandbox creation time.

## Troubleshooting

**"Missing Authentication header"** — The proxy bypass isn't configured. Run:
```bash
docker sandbox network proxy <sandbox-name> --bypass-host api.openrouter.ai
```

**"User not found"** — The API key is invalid. Verify your key at [openrouter.ai/settings/keys](https://openrouter.ai/settings/keys).

**"OpenRouter API key is missing"** — The auth.json wasn't injected or has the wrong format. It must be:
```json
{
  "openrouter": {
    "type": "api",
    "key": "sk-or-v1-..."
  }
}
```
