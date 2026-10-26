---
name: termux
description: Termux/Android pitfalls, SDK, and Hermes setup on ARM64.
version: 10.0.0
author: lietxia, Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [termux, android, arm64, bionic, python, venv, sdk, ndk, gradle, agp]
    related_skills: []
---

# Termux / Android Environment Guide

Hermes Agent and Android builds on Termux (aarch64 Android). Termux is not desktop
Linux: the package manager, the libc, Python, and every Google SDK/NDK binary differ.
This file is the always-on rule set; topic depth lives in `references/`.

## When to Use

Load this skill when the task involves any of:

- Hermes on Termux or Android — install, update, gateway, TUI, `hermes doctor`
- Android SDK / NDK / Gradle builds on an ARM64 Termux host
- `Exec format error`, `cannot execute: required file not found`, Bionic-vs-glibc failures
- `apt` / `pkg` failing on Android 16
- A dependency gated only to `linux` failing because `sys.platform == "android"`

## Prerequisites

- The standard Termux app on aarch64, prefix `/data/data/com.termux/files/usr`
- Either the Hermes APT package or a git checkout of `NousResearch/hermes-agent`
- Do not use proot-distro for any of this. The user rejected it; work on the host directly.

## How to Run

| Goal | Entry point |
|------|-------------|
| Verify the Hermes install | `hermes doctor` |
| Install Hermes on Termux | `references/hermes-termux.md` |
| Fix an Android build | `references/android-build.md` |
| Check a known-issue status | `references/termux-pitfalls.md` |
| Audit SDK binary architectures | `scripts/verify-arm64-sdk.sh` |

## Quick Reference

```bash
# --- Hermes: official APT install ---
pkg install curl gnupg
mkdir -p "$PREFIX/etc/apt/keyrings"
curl -fsSL "https://hermes-assets.nousresearch.com/releases/termux/canary/key.asc" \
  -o "$PREFIX/etc/apt/keyrings/hermes-agent.asc"
printf '%s\n' "deb [signed-by=$PREFIX/etc/apt/keyrings/hermes-agent.asc] https://hermes-assets.nousresearch.com/releases/termux/canary hermes-canary main" \
  > "$PREFIX/etc/apt/sources.list.d/hermes-agent.list"
pkg update && pkg install hermes-agent

# --- Update. `hermes update` refuses on an APT-owned install. ---
pkg update && pkg upgrade hermes-agent

# --- Gateway: run in a Termux session; there is no systemd ---
hermes gateway run
nohup hermes gateway run >> "${HERMES_HOME:-$HOME/.hermes}/logs/gateway.log" 2>&1 &

# --- Android SDK: Google ships x86_64 only, replace with ARM64 builds ---
curl -fsSL "https://github.com/lzhiyong/android-sdk-tools/releases/download/35.0.2/android-sdk-tools-static-aarch64.zip" -o ~/lzhiyong-aarch64.zip
unzip -o ~/lzhiyong-aarch64.zip -d ~/lzhiyong-tools
```

## Procedure

1. Confirm the host. `uname -m` prints `aarch64` and `echo "$PREFIX"` prints the Termux prefix.
   **Done when:** both print the expected values.
2. Pick the install path — the APT package (self-contained Python 3.14) or a git checkout.
   **Done when:** `hermes --version` runs.
3. Configure a provider, then start the TUI: `hermes setup`, then `hermes --tui`.
   **Done when:** the TUI renders; if text vanishes, see `references/termux-pitfalls.md`.
4. For Android work, install the ARM64 toolchain per `references/android-sdk-setup.md`
   and `references/ndk-setup.md`.
   **Done when:** `scripts/verify-arm64-sdk.sh` exits 0.
5. Build with the project `gradle.properties` overrides from `references/android-build.md`.
   **Done when:** the APK is produced and installs on the device.

## Pitfalls

- **The Hermes Termux APT package is currently broken upstream.** The official docs
  carry a banner: the Termux package does not work right now and a fix is in progress.
  Expect the APT steps to fail until it ships.
- **The `stable` channel is not published.** Only `canary` resolves;
  `releases/termux/stable/...` returns 404. Use `canary` / `hermes-canary`.
- **Do not pin or downgrade Python.** Hermes supports 3.11–3.14
  (`requires-python >=3.11,<3.15`). The older advice (`apt-mark hold python`,
  `uv venv --python python3.13`) is wrong and now harmful.
- **`hermes update` refuses on APT installs** and prints the package-manager command
  instead. Use `pkg upgrade hermes-agent`.
- **`sys.platform == "android"`** for the APT Python. A dependency gated only to
  `linux` is not automatically available — this skill declares no `platforms:` for
  that reason, so it loads on both `linux` and `android` hosts.
- **Google SDK/NDK binaries are x86_64.** Replace with `lzhiyong/android-sdk-tools`
  and `lzhiyong/termux-ndk`. `Commit451/android-arm-build-tools` and
  `SnowNF/ndk-aarch64-linux` are glibc builds and fail on Bionic.
- **KSP lags Kotlin.** Kotlin 2.4.21 is current but KSP stops at 2.3.12 — there is
  no KSP 2.4.x. Pin Kotlin 2.3.x when using KSP or Hilt.
- **`/tmp` is not writable**; use `$HOME`. There is no systemd; use tmux.
- **`apt` / `pkg` break on Android 16** via a Bionic stdio errno bug
  (termux/termux-app#5077, closed as not-planned). The workaround is an
  `LD_PRELOAD` errno shim — reinstalling Termux does not help.

## Verification

```bash
hermes --version
hermes doctor
uname -m && echo "$PREFIX"
bash scripts/verify-arm64-sdk.sh
```

## References

- [Hermes on Termux](references/hermes-termux.md) — APT install, file layout, updates, limits
- [Termux pitfalls](references/termux-pitfalls.md) — known-issue status table
- [Termux environment](references/termux-environment.md) — apt/pkg, env vars, search tools
- [Android SDK setup](references/android-sdk-setup.md) — ARM64 tools, aapt2, adb, cmake
- [NDK setup](references/ndk-setup.md) — termux-ndk, version symlink, CMake/Ninja
- [Android build](references/android-build.md) — JDK, gradle.properties, AGP/Kotlin/KSP matrix
- [Build resources](references/termux-android-build-resources.md) — external repo table
- [Disabling native tasks](references/native-build-tasks.md)
- [Browser automation](references/termux-browser-automation.md)
- [Software updates](references/termux-software-update.md)
- [SkillHub and news skills](references/skillhub-and-news-skills.md)
- [Telegram gateway](references/telegram-gateway-setup.md)
- [hermes doctor output](references/hermes-doctor-output.md)
- [Remote machine management](references/remote-machine-management.md)
- [vTerm/Haven migration](references/haven-vterm-migration.md)
- [Haven build config](references/haven-build.md)
- [Haven native modules](references/haven-native-modules.md)
