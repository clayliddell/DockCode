# DockCode

Wrapper for building and managing custom Docker Sandbox templates for running [OpenCode](https://opencode.ai) with [OpenRouter](https://openrouter.ai) as the LLM provider.

## Why Sandbox OpenCode?

OpenCode puts up guardrails to try preventing LLMs running in it from modifying the host system without approval. This approach, however, has 2 problems:

1. OpenCode has to continually prompt for any permissions you don't grant it from the outset (reading/writing files outside of its permitted directory, running CLI commands which could modify the host, etc.)
2. Even with these guardrails in place, more clever LLMs will still try to bypass these guardrails by finding clever ways to do things (i.e. running obfuscated scripts). So your host computer is never truly protected against a rogue LLM looking to do something destructive...

**Enter Docker Sandboxes**

## Why not use one of the Standard Docker Sandbox images?

Docker Sandboxes' built-in credential proxy only supports a fixed set of providers (OpenAI, Anthropic, Google, xAI, Groq, AWS). OpenRouter isn't one of them, so the proxy strips its Authorization header. This template works around that by:

1. Bypassing the MITM proxy for OpenRouter domains
2. Injecting the API key via OpenCode's `auth.json`

## How It Works

1. **Build** — The Dockerfile bakes `opencode.json` into the image.
2. **Create** — A sandbox is created with the custom template, and OpenRouter domains are bypassed from the MITM proxy.
3. **Inject** — The contents of `auth.json` are written into `~/.local/share/opencode/auth.json` inside the sandbox.

The API key is never stored in the image — only injected at sandbox creation time.

---

## Prerequisites

- Docker Desktop for Linux (with `docker sandbox` CLI)
- An OpenRouter API key
- `jq` CLI tool (see [jq Download page](https://jqlang.org/download/) for install instructions)

## Quick Start

```bash
# Launch from any project directory
cd ~/my-project
dockcode launch
```

## Usage

```
Usage: dockcode <command> [args...]

Commands:
  config show                          Print config file paths
  config update <key> <value>          Update a config value

      Keys:
        opencode.json    Path to opencode.json
        auth.json        Path to auth.json

  launch [-n name] [-w workspace]      Launch or create a sandbox

      -n    Sandbox name (default: current directory name)
      -w    Workspace directory (default: current directory)

Options:
  -h, --help                           Show this help message
  --version                            Show version
```

## Config Management

Settings are stored in `~/.config/dockcode/config`:

| Key | Default | Description |
|---|---|---|
| `OPENCODE_CONFIG` | `~/.config/dockcode/opencode.json` | Path to OpenCode config |
| `AUTH_CONFIG` | `~/.config/dockcode/auth.json` | Path to auth credentials |

### Show current config

```bash
dockcode config show
```

### Update config values

```bash
# Use a custom opencode.json
dockcode config update opencode.json ~/my-opencode.json

# Use a custom auth.json
dockcode config update auth.json ~/my-auth.json
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
dockcode launch

# Launch with custom name and workspace
dockcode launch -n my-sandbox -w ~/other-project

# Re-launch existing sandbox (no rebuild)
dockcode launch -n my-sandbox
```

If a sandbox with the given name already exists, it is launched directly. Otherwise, a new sandbox is created with proxy bypass and auth injection.

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | Extends `docker/sandbox-templates:opencode` with OpenCode config |
| `opencode.json` | Default OpenCode config (OpenRouter models, permissions) |
| `auth.json` | Default auth template (edit to set your API key) |
| `dockcode` | CLI with config management and sandbox launch |

## Configuration

### Default Models

Edit `~/.config/dockcode/opencode.json` or provide your own `opencode.json` via `dockcode config update opencode.json <path/to/opencode.json>`.

### Permissions

All permissions are set to "allow" by default since OpenCode is run in a VM. You can modify this behavior by changing the `opencode.json` config passed into the script.

### API key

After first running the script once, a default `~/.config/dockcode/auth.json` should be created. You can point the script config to a different location. Or, you can edit `~/.config/dockcode/auth.json` to set your OpenRouter API key:

```json
{
  "openrouter": {
    "type": "api",
    "key": "sk-or-v1-your-key-here"
  }
}
```

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
