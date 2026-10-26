# `hermes doctor` output

How to read the common warnings.

## Must fix

| Warning | Meaning | Fix |
|---------|---------|-----|
| `No API key found in ~/.hermes/.env` | Model and voice features cannot work | `hermes setup`, or write the key manually |
| `terminal (system dependency not met)` | The shell command channel is broken | `pkg install zsh util-linux procps`, then `hermes setup terminal` |
| `Run 'hermes setup' to configure API keys` | A required credential is missing | `hermes setup` |

## Optional

| Warning | Meaning | Fix |
|---------|---------|-----|
| `discord.py (optional, not installed)` | Discord integration lacks its dependency | Ignore if Discord is unused |
| `browser-cdp (system dependency not met)` | Chrome DevTools unavailable | Usually unfixable on Android; see [termux-browser-automation.md](termux-browser-automation.md) |
| `computer_use (system dependency not met)` | Desktop control unavailable | Not applicable on Android |
| `homeassistant (system dependency not met)` | Smart-home integration unconfigured | Needs a Home Assistant instance |
| `x_search (missing XAI_API_KEY)` | X/Twitter search unavailable | Needs an xAI key |
| `spotify (system dependency not met)` | Spotify unconfigured | Needs Spotify OAuth |
| `discord (missing DISCORD_BOT_TOKEN)` | Discord bot unconfigured | Ignore if unused |
| `OpenAI Codex auth (not logged in)` | Codex not authenticated | `hermes auth add openai-codex` |
| `No GITHUB_TOKEN` | Skills Hub rate limit is low | Write the token to `~/.hermes/.env` |

## Normal, no action needed

| Output | Meaning |
|--------|---------|
| `✓ Python 3.x.x` | Python is fine |
| `✓ Virtual environment active` | venv is active |
| `✓ Version files consistent` | Version metadata matches |
| `✓ Nous Portal auth (logged in)` | Portal is authenticated |
| `Docker backend is not available inside Termux` | Expected — Android has no Docker |
| `agent-browser is not installed` | Optional; install on demand |

## Repair sequence

```bash
hermes doctor

# Package dependencies
pkg install zsh util-linux procps openssh termux-api tmux

# Terminal tool
hermes setup terminal

# API keys
hermes setup

# Sync the GitHub token for Skills Hub
echo "GITHUB_TOKEN=$(gh auth token)" >> ~/.hermes/.env

hermes doctor
```

## Note on Python

`hermes doctor` reporting a Python version is not a problem by itself. Hermes supports
3.11 through 3.14. Do not downgrade Python to satisfy an older note — see
[termux-pitfalls.md](termux-pitfalls.md).
