# Termux Pitfalls — status table

Verified against the upstream trackers. Statuses change; re-check the linked issue
before telling the user something is unfixable.

## Python and environment

| Issue | Status | Workaround |
|-------|--------|------------|
| `python -m venv` fails / ensurepip broken | Open | Use `uv venv` instead |
| psutil fails to build | Handled upstream | The APT package pins a prebuilt psutil; no local build needed |
| cryptography import error | Open | Install with `--system-site-packages`, or use the APT package |
| pip broken on Python 3.13.12-2 | Closed, no fix | Use `uv pip` |
| Python 3.14 "breaks Hermes" | **Myth** | Hermes supports 3.11–3.14 (`requires-python >=3.11,<3.15`). Do not pin or downgrade Python |
| `sys.platform == "android"` | By design | Skills/deps gated only to `linux` will not load; test against `android` |

## Hermes operations

| Issue | Status | Workaround |
|-------|--------|------------|
| `hermes update` fails on APT install | Expected | `pkg update && pkg upgrade hermes-agent` |
| Gateway cannot self-restart | By design | Restart from a separate shell, or `nohup ... &` in tmux |
| TUI text disappears (Xiaomi Android 16) | Closed (NousResearch/hermes-agent#18390) | Run in tmux, or set `display.interface: cli` |
| GIL event-loop stall | Closed (NousResearch/hermes-agent#58576) | See [gil-stall-fix.md](gil-stall-fix.md) |
| SQLite locked under GIL | Closed (NousResearch/hermes-agent#57921) | See [gil-stall-fix.md](gil-stall-fix.md) |
| linux/arm64 Docker ships x86_64 wheels | Open (NousResearch/hermes-agent#74554) | Use the APT package; do not build from source on ARM64 |

## Termux system

| Issue | Status | Notes |
|-------|--------|-------|
| `apt` / `pkg` broken on Android 16 | Closed as not-planned (termux/termux-app#5077) | Bionic stdio errno bug (`fdopen`/`getline`). Reinstalling Termux does **not** fix it. Workaround: an `LD_PRELOAD` errno shim |
| nettle breaks `apt` | Closed (termux/termux-packages#28411) | A nettle update broke `apt update` and ffmpeg; avoid the bad nettle build |
| `/tmp` not writable | Open | Use `$HOME` for every temp file |
| `which` not found | Open | Use `command -v` |
| curl HTTP/2 errors against GitHub | Open | Use `curl --http1.1` |
| No systemd | By design | Use tmux |

## Android toolchain

| Issue | Status | Notes |
|-------|--------|-------|
| Google SDK/NDK binaries are x86_64 | By design | Replace with `lzhiyong/android-sdk-tools` and `lzhiyong/termux-ndk` |
| glibc ARM64 builds fail on Bionic | By design | `Commit451/android-arm-build-tools` and `SnowNF/ndk-aarch64-linux` need `ld-linux-aarch64.so.1` |
| KSP has no 2.4.x | By design | Kotlin 2.4.21 is current; KSP stops at 2.3.12. Pin Kotlin 2.3.x with KSP/Hilt |
| AGP 9.x breaks Hilt ≤ 2.58 | By design | Stay on AGP 8.x when using Hilt |
