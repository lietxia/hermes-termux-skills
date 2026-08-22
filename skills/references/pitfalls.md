# Complete Termux Pitfall Guide

Based on real-world experience running Hermes Agent on Termux/Android (2025-2026).

## Python Environment

### Python 3.14 Breaks Everything
- **Symptom**: `ModuleNotFoundError: No module named 'hermes_cli'`
- **Cause**: `pkg upgrade` auto-upgrades Python; Hermes requires `<3.14`
- **Fix**:
  ```bash
  apt-mark hold python
  apt-mark hold python-ensurepip-wheels
  ```
- **If already upgraded**:
  ```bash
  apt-get install --allow-downgrades -y python=3.13.12-3
  apt-mark hold python
  ```

### `python -m venv` Fails
- **Symptom**: `ensurepip` errors
- **Fix**: Use `uv venv` instead:
  ```bash
  uv venv venv --python /data/data/com.termux/files/usr/bin/python3.13
  ```

### psutil Won't Compile
- **Symptom**: `platform android is not supported`
- **Fix**: Two options:
  1. Use `--system-site-packages`:
     ```bash
     uv venv venv --python python3 --system-site-packages
     ```
  2. Use official prebuild:
     ```bash
     python scripts/install_psutil_android.py
     ```

### cryptography Import Error
- **Symptom**: `dlopen failed: cannot locate symbol "PyLong_Type"`
- **Cause**: System Python's cryptography compiled against wrong Python
- **Fix**: Use `--system-site-packages` or rebuild venv

### pip Broken on Python 3.13.12-2
- **Symptom**: Various pip errors after Termux update
- **Fix**: Use `uv pip` instead:
  ```bash
  uv pip install <package>
  ```

## Hermes Operations

### `hermes update` Fails
- **Fix**:
  ```bash
  cd ~/hermes-agent && git pull && uv pip install -e . --no-deps
  ```

### Gateway Can't Self-Restart
- **Symptom**: `hermes gateway restart` from within Hermes kills itself
- **Fix**: Run from SEPARATE Termux shell

### TUI Text Disappears (Xiaomi Android 16)
- **Symptom**: Response text disappears when closing keyboard
- **GitHub Issue**: #18390, #16072
- **Fix**: Switch to CLI mode:
  ```yaml
  # ~/.hermes/config.yaml
  display:
    interface: cli
  ```

## Termux-Specific

### `/tmp` Not Writable
- **Fix**: Write to `$HOME` instead

### `which` Not Found
- **Fix**: Use `command -v`

### `apt/pkg` Broken on Android 16
- **GitHub Issue**: #5077
- **Symptom**: `getline (25: Inappropriate ioctl for device)`
- **Root Cause**: Bionic stdio errno bug — reinstalling Termux does NOT fix it
- **Workaround**: Wait for APT/Termux patch, or use mirrors that don't trigger the bug

### curl HTTP/2 Errors
- **Fix**: Always use `curl --http1.1`

## Android SDK Build

### AAPT2 Daemon Failed
- **Cause**: x86_64 binary on ARM64
- **Fix**: Replace with lzhiyong's ARM64 build + `aapt2FromMavenOverride`

### `Exec format error`
- **Cause**: x86_64 binary
- **Fix**: Replace with ARM64 build

### NDK clang Won't Run
- **Cause**: x86_64 binary
- **Fix**: Use lzhiyong's termux-ndk

### protoc Won't Run
- **Cause**: Maven-downloaded protoc is x86_64
- **Fix**:
  ```kotlin
  protobuf { protoc { path = "/data/data/com.termux/files/usr/bin/protoc" } }
  ```

### Protobuf Version Mismatch
- **Symptom**: `cannot find symbol: class Generated`
- **Fix**: Add `compileOnly("com.google.protobuf:protobuf-java:4.33.1")`

### Git Submodules Empty
- **Cause**: `git clone --depth 1` doesn't init submodules
- **Fix**:
  ```bash
  git submodule init && git submodule update --depth 1
  # If still empty, clone manually:
  git clone --depth 1 <url> <name>
  ```

### Gradle Daemon OOM
- **Fix**: Kill with `pkill -f GradleDaemon` between builds

### FileAlreadyExistsException
- **Fix**:
  ```bash
  rm -rf build/reports/dependency-verification/
  echo 'org.gradle.dependency.verification=off' >> gradle.properties
  ```

## Security

### Android Seccomp
- Blocks syscalls: `futex_wait_requeue_pi`, `pselect`, `pipe2`
- **Effect**: Static-linked ELFs crash with SIGSYS (31)
- **Fix**: Run exploits in ADB shell, not Termux
- **Check**: `grep "Seccomp:" /proc/self/status` (2 = filter active)