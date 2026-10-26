# Termux Environment

How Termux differs from desktop Linux, and the settings that make Hermes work on it.

## Differences that matter

| Desktop Linux | Termux / Android |
|---------------|------------------|
| `apt install` | `pkg install` (apt is a wrapper; on Android 16 it can be broken) |
| `/tmp` writable | `/tmp` is not writable — use `$HOME` |
| systemd | no init system — use tmux |
| `python3 -m venv` | `uv venv` (ensurepip is broken) |
| `which` | `command -v` |
| x86_64 binaries | aarch64 only |
| glibc | Bionic libc |
| background processes persist | Android suspends/kills background Termux processes |

## Environment variables

```bash
# ~/.bashrc
export ANDROID_HOME="$HOME/android-sdk"
export JAVA_HOME=/data/data/com.termux/files/usr/lib/jvm/java-21-openjdk
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
export SEARXNG_URL=http://searxng.r-mj.com
```

Set `JAVA_HOME` to the JDK your AGP version needs: 17 for AGP 8.x, 21 for AGP 9.x.

## Search tools

| Tool | Status | Config |
|------|--------|--------|
| SearXNG | Active | `SEARXNG_URL` env var |
| `web_search` | Via SearXNG | Free, self-hosted |
| hackernews | Available | Free skill, needs `jq` |
| github-trending | Available | Free skill |
| browser | Conditional | Needs a system chromium on `PATH`; see [termux-browser-automation.md](termux-browser-automation.md) |

## Proot rule

Never propose proot-distro. The user rejected it explicitly. Everything in this
skill runs on the Termux host directly.

## Background work

Android terminates background Termux processes. For anything long-running, run it in
a tmux session rather than relying on `&`:

```bash
tmux new -d -s hermes 'hermes gateway run'
tmux attach -t hermes
```

See [remote-machine-management.md](remote-machine-management.md) for the same pattern
applied to SSH sessions.

## Updating portable tools

Many CLI tools are distributed as Termux `.deb` files from GitHub releases. See
[termux-software-update.md](termux-software-update.md) for the extraction recipe.
