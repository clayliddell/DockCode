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
# Launch interactively — choose an existing sandbox or create a new one
dockcode launch

# Or launch directly from a project directory
cd ~/my-project
dockcode launch -n my-project -w .
```

## Usage

```bash
Usage: dockcode <command> [args...]

Commands:
  config show                          Print config file paths
  config update <key> <value>          Update a config value

      Keys:
        opencode.json    Path to opencode.json
        auth.json        Path to auth.json

  settings print [-n name]             Print opencode.json in a sandbox
  settings update [-n name]            Update opencode.json in a sandbox
                                        (interactive if no flags given)

  ls [--json]                          List existing sandboxes
  rm [-n name]                         Destroy a sandbox
                                        (interactive if no flags given)

  launch [-n name] [-w workspace]      Launch or create a sandbox
                                        (interactive if no flags given)

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

## Settings Command

Manage `opencode.json` configuration inside running sandboxes.

### Print settings

Display the current `opencode.json` inside a sandbox:

```bash
# Interactive mode - select from available sandboxes
dockcode settings print

# Specify sandbox name
dockcode settings print -n my-sandbox
```

### Update settings

Update the `opencode.json` inside a sandbox:

```bash
# Interactive mode - select from available sandboxes
dockcode settings update

# Specify sandbox name
dockcode settings update -n my-sandbox
```

When updating, you will be prompted to choose:

```
How would you like to update the config?
  1) Manually edit (host editor)
  2) Re-import default config from host

Choice [1-2]:
```

- **Manually edit (host editor)** — Copies config to a temp file and opens it with your `$EDITOR` (defaults to `vi`), then uploads changes back to the sandbox
- **Re-import default config from host** — Overwrites the sandbox config with your host's `~/.config/dockcode/opencode.json`

## List Command

List all existing sandboxes:

```bash
dockcode ls
```

```
Sandboxes:

  1) my-project
  2) other-project

Total: 2
```

Pass `--json` for raw JSON output:

```bash
dockcode ls --json
```

## Destroy Command

### Interactive mode

Running `destroy` with no flags opens an interactive dialog to pick a sandbox:

```bash
dockcode destroy
```

```
Which sandbox would you like to destroy?

  1) my-project
  2) other-project

Choice [1-2]:
```

You will be prompted to confirm before the sandbox is removed.

### Non-interactive (flags)

```bash
dockcode destroy -n my-sandbox
```

## Launch Command

### Interactive mode

Running `launch` with no flags opens an interactive dialog:

```bash
dockcode launch
```

You will be presented with a menu:

```
What would you like to do?
  1) Launch existing sandbox: my-project
  2) Launch existing sandbox: other-project
  3) Create a new sandbox

Choice [1-3]:
```

- **Launch an existing sandbox** — select from sandboxes already created via `docker sandbox ls`.
- **Create a new sandbox** — prompts for a sandbox name (defaults to the current directory name) and a workspace path (defaults to the current directory, supports `~` expansion).

### Non-interactive (flags)

```bash
# Launch in current directory (sandbox named after directory)
cd ~/my-project
dockcode launch -n my-project -w .

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
| `opencode.example.json` | Default OpenCode config (OpenRouter models, permissions) |
| `auth.example.json` | Default auth template (copy and edit to set your API key) |
| `dockcode` | CLI with config management, sandbox launch, list, and destroy |

## Configuration

### Default Models

Edit `~/.config/dockcode/opencode.json` or provide your own `opencode.json` via `dockcode config update opencode.json <path/to/opencode.json>`.

### Permissions

All permissions are set to "allow" by default since OpenCode is run in a VM. You can modify this behavior by changing the `opencode.json` config passed into the script.

### API key

After first running the script once, a default `~/.config/dockcode/auth.json` should be created from the bundled `auth.example.json` template. You can point the script config to a different location. Or, you can edit `~/.config/dockcode/auth.json` to set your OpenRouter API key:

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
