---
name: termux-meta
---

# Hermes on Termux

## Installation (Official Installer)

The official installer auto-detects Termux and uses the correct setup:

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

**Auto-fallback chain:**
1. `.[termux-all]` (broad profile)
2. `.[termux]` (conservative profile)
3. `.` (base package)

**Automatic psutil fix:**
Official installer runs `scripts/install_psutil_android.py` to patch psutil before pip install.

## venv Creation

```bash
# Standard venv (lightweight, no system packages)
uv venv venv --python /data/data/com.termux/files/usr/bin/python3.13

# With system packages (needed for psutil, cryptography)
uv venv venv --python /data/data/com.termux/files/usr/bin/python3.13 --system-site-packages --seed
```

**PITFALL**: `python3 -m venv` may fail with ensurepip errors. Use `uv`.

## Hermes Update

**PITFALL**: `hermes update` may fail on Termux due to dependency resolution issues.

```bash
# Manual update (recommended)
cd ~/hermes-agent && git pull && uv pip install -e . --no-deps
```

## Gateway Management

**PITFALL**: Hermes cannot self-restart (SIGTERM propagates to child processes).

```bash
# From a SEPARATE Termux shell
hermes gateway restart

# Or use tmux for persistent background
tmux new -s hermes 'hermes gateway run'
tmux attach -t hermes  # to reattach
```

## Known Issues

| Issue | Fix |
|-------|-----|
| TUI text disappears (Xiaomi Android 16) | Switch to CLI mode: `display.interface: cli` |
| pip broken on Python 3.13.12-2 | Use `uv pip` instead |
| psutil compile fails | Use `--system-site-packages` or prebuild script |
| `hermes update` fails | Use manual update with `uv pip install -e . --no-deps` |