---
name: termux
description: "Complete Termux/Android environment guide for Hermes Agent. Covers Python/venv, Android SDK/NDK, Gradle/AGP, and ARM64 workarounds. Use when: running on Termux, building Android on ARM64, Python venv issues, or Termux-specific errors."
version: 9.0.0
author: lietxia
license: MIT
platforms: [android, termux]
metadata:
  hermes:
    tags: [termux, android, python, venv, sdk, ndk, gradle, agp, arm64]
    related_skills: []
triggers:
  - "termux environment"
  - "android arm64 build"
  - "python venv android"
  - "aapt2 arm64"
  - "gradle build arm64"
  - "psutil android"
  - "hermes tui xiaomi"
  - "termux python 3.14"
  - "hermes update fail"
  - "gateway restart"
  - "nettle termux"
  - "apt broken android 16"
---

# Termux/Android Environment Guide

## Quick Reference

```bash
# Pin Python (Hermes requires <3.14)
apt-mark hold python && apt-mark hold python-ensurepip-wheels

# Install uv
pkg install uv

# Create venv
uv venv venv --python /data/data/com.termux/files/usr/bin/python3.13 --system-site-packages --seed

# Install Hermes
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# Update (hermes update may fail)
cd ~/hermes-agent && git pull && uv pip install -e . --no-deps

# Gateway restart
hermes gateway restart

# psutil fix
cd ~/hermes-agent && python scripts/install_psutil_android.py
```

## Critical Differences from Standard Linux

| Standard Linux | Termux/Android |
|----------------|-----------------|
| `apt install` | `pkg install` |
| `/tmp` writable | `/tmp` → use `$HOME` |
| `systemd` | Use `tmux` |
| `python3 -m venv` | `uv venv` (ensurepip fails) |
| `which` | `command -v` |
| x86_64 binaries | ARM64 only |
| glibc | Bionic libc |

## Known Issues & Status

### Python Environment

| Issue | Status | Workaround |
|-------|--------|------------|
| **Python 3.14 breaks Hermes** | — | `apt-mark hold python` + `uv venv --python python3.13` |
| **`python -m venv` fails** | — | Use `uv venv` instead |
| **psutil compile fails** | — | `--system-site-packages` or `scripts/install_psutil_android.py` |
| **cryptography import error** | — | `--system-site-packages` to inherit system package |
| **pip broken on Python 3.13.12-2** | CLOSED (no fix) | Use `uv pip` instead |

### Hermes Operations

| Issue | Status | Workaround |
|-------|--------|------------|
| **`hermes update` fails** | — | Use `git pull && uv pip install -e . --no-deps` |
| **Gateway can't self-restart** | — | Run `hermes gateway restart` from SEPARATE shell |
| **TUI text disappears (Xiaomi Android 16)** | CLOSED (unfixed, #18390) | Switch to CLI mode: `display.interface: cli` |

### Termux System

| Issue | Status | Notes |
|-------|--------|-------|
| **apt/pkg broken on Android 16** | CLOSED (unfixed, #5077) | Bionic stdio errno bug — reinstalling Termux does NOT fix it |
| **nettle breaks apt** | CLOSED (#28411) | nettle package update breaks apt update and ffmpeg |
| **`/tmp` not writable** | — | Use `$HOME` for all temp files |
| **`which` not found** | — | Use `command -v` |
| **curl HTTP/2 errors on GitHub** | — | Use `curl --http1.1` |

## Environment Variables

```bash
# ~/.bashrc
export ANDROID_HOME="$HOME/android-sdk"
export JAVA_HOME=/data/data/com.termux/files/usr/lib/jvm/java-21-openjdk
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
export SEARXNG_URL=http://searxng.r-mj.com
```

## Search Tools

| Tool | Status | Config |
|------|--------|--------|
| **SearXNG** | ✅ Active | `SEARXNG_URL` env var |
| **web_search** | ✅ Via SearXNG | Free, self-hosted |
| **browser** | ✅ Available | Browser Use cloud |
| **hackernews** | ✅ Available | Free skill |
| **github-trending** | ✅ Available | Free skill |

## Hermes on Termux

### Install
```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

### Update
```bash
cd ~/hermes-agent && git pull && uv pip install -e . --no-deps
```

### Gateway
```bash
# Separate shell
hermes gateway restart

# Or tmux
tmux new -s hermes 'hermes gateway run'
tmux attach -t hermes
```

## Android Development

### JDK
```bash
pkg install -y openjdk-17 openjdk-21
export JAVA_HOME=/data/data/com.termux/files/usr/lib/jvm/java-21-openjdk
```

### SDK
```bash
ANDROID_HOME="$HOME/android-sdk"
mkdir -p "$ANDROID_HOME/cmdline-tools"
curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" -o ~/cmdline-tools.zip
unzip -o ~/cmdline-tools.zip -d "$ANDROID_HOME/cmdline-tools/"
mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platforms;android-35" "build-tools;35.0.1"
```

### ARM64 Binary Replacement (CRITICAL)
```bash
curl -fsSL "https://github.com/lzhiyong/android-sdk-tools/releases/download/35.0.2/android-sdk-tools-static-aarch64.zip" -o ~/lzhiyong-aarch64.zip
unzip -o ~/lzhiyong-aarch64.zip -d ~/lzhiyong-tools

for ver in $ANDROID_HOME/build-tools/*/; do
  cp ~/lzhiyong-tools/build-tools/{aapt2,aidl,zipalign} "$ver/"
  chmod +x "$ver"/{aapt2,aidl,zipalign}
done
cp ~/lzhiyong-tools/platform-tools/adb "$ANDROID_HOME/platform-tools/adb"
```

### AAPT2 Override
```properties
# gradle.properties
android.aapt2FromMavenOverride=/data/data/com.termux/files/home/android-sdk/build-tools;35.0.1/aapt2
```

## References

- [Android SDK Setup](references/android-sdk-setup.md)
- [NDK Setup](references/ndk-setup.md)
- [AGP Compatibility](references/agp-compatibility.md)
- [Common Pitfalls](references/pitfalls.md)
- [Hermes Termux](references/hermes-termux.md)
- [vTerm Build](references/haven-termux-build.md)