# Hermes on Termux

The official, supported install path is the Hermes APT package. It is self-contained:
it ships its own Python 3.14, Node, npm, uv, ripgrep, and ffmpeg, and does not need
Termux's `python` or `nodejs` packages.

Do **not** use the desktop `install.sh` or a glibc Linux archive on this target.

## Current status (check before starting)

- **The Termux package is currently broken upstream.** The official docs carry a
  banner saying the Termux package does not work right now and a fix is in progress.
- **Only the `canary` channel is published.** `releases/termux/stable/...` returns 404
  as of 2026-10-26; `releases/termux/canary/...` resolves.

## Install

```bash
pkg install curl gnupg
mkdir -p "$PREFIX/etc/apt/keyrings"
curl -fsSL "https://hermes-assets.nousresearch.com/releases/termux/canary/key.asc" \
  -o "$PREFIX/etc/apt/keyrings/hermes-agent.asc"

# Verify the fingerprint before trusting the key.
gpg --show-keys --with-fingerprint "$PREFIX/etc/apt/keyrings/hermes-agent.asc"
# Expected: C572 B5FD D1A2 9CCF A9A9 12B6 840B 0848 E139 156D
# If it differs, stop. Do not disable signature verification.

printf '%s\n' "deb [signed-by=$PREFIX/etc/apt/keyrings/hermes-agent.asc] https://hermes-assets.nousresearch.com/releases/termux/canary hermes-canary main" \
  > "$PREFIX/etc/apt/sources.list.d/hermes-agent.list"

pkg update && pkg install hermes-agent
```

Constraints: the standard Termux app only, prefix `/data/data/com.termux/files/usr`,
aarch64. Renamed Termux forks and other architectures are unsupported. Wheels target
Android API 24 (`android_24_arm64_v8a`).

To follow prereleases instead, keep `canary` / `hermes-canary` — that is the only
published suite. To move channels later, edit the path and suite in
`hermes-agent.list`, then `pkg update && pkg upgrade hermes-agent`.

## File layout

| What | Path |
|------|------|
| Package files | `$PREFIX/lib/hermes-agent/` |
| Command symlinks | `$PREFIX/bin/hermes`, `$PREFIX/bin/hermes-agent`, `$PREFIX/bin/hermes-acp` |
| Config and user data | `~/.hermes/`, or `$HERMES_HOME` |

## Update

```bash
pkg update && pkg upgrade hermes-agent
```

`hermes update` refuses to modify an APT-owned installation and prints the
package-manager command instead. That is expected, not a failure.

Canary versions carry `~canary.<timestamp>` and sort before the matching stable
version; each suite lists only its own channel's packages.

## Configure and run

```bash
hermes setup
hermes --tui
```

Gateway — there is no systemd, launchd, or Windows Scheduled Tasks:

```bash
hermes gateway run
# or detached:
mkdir -p "${HERMES_HOME:-$HOME/.hermes}/logs"
nohup hermes gateway run >> "${HERMES_HOME:-$HOME/.hermes}/logs/gateway.log" 2>&1 &
```

Android can suspend or terminate background Termux processes. Battery-optimization
exemptions and `termux-wake-lock` help but do not guarantee persistence.

## Limits of the package

- No `nemo-relay` exporter — its vendored toolchain does not support this target.
- No Electron, bundled Chromium, or desktop computer-use tools. The browser tool
  launches a system chromium when one is on `PATH` (`pkg install chromium`); without
  one, browsing is unavailable and the tool says so.
- No local Docker daemon.
- No phone-native Termux `:API` microphone or clipboard adapters.
- Optional integrations and third-party plugins may need dependencies that do not
  support Android.

## Python platform note

On this target `sys.platform == "android"`. A dependency or skill gated only to
`linux` is **not** automatically available on Android. When checking whether a
Python dependency applies, test against `android`, not `linux`.

## Uninstall

```bash
pkg uninstall hermes-agent
```

APT removes the package and its symlinks but preserves configuration, sessions,
skills, and memories.

## Troubleshooting

| Symptom | Action |
|---------|--------|
| Package not found | Check the repository entry, then `pkg update` |
| Signature error | Verify the key fingerprint; never use an unsigned repo |
| Missing command | Confirm `$PREFIX/bin` is on `PATH`, or reinstall |
| Missing library or TUI bundle | Report `hermes --version` and the full error; the core package must not need a local rebuild |
| Gateway stops with screen off | Review Android battery and background-process limits |

Run `hermes doctor` for general diagnostics; see
[hermes doctor output](hermes-doctor-output.md) for the warning table.
