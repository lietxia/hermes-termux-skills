# AAPT2 ARM64 on Termux — Error Reference

## Symptom 1: Exec format error
```
/data/data/com.termux/files/home/android-sdk/platform-tools/adb: cannot execute binary file: Exec format error
```
**Cause**: x86-64 binary on AArch64 host.

## Symptom 2: AAPT2 Daemon startup failed
```
AAPT2 aapt2-8.7.3-12006047-linux Daemon #0: Daemon startup failed
This should not happen under normal circumstances, please file an issue if it does.
```
**Cause**: Same as above — Gradle tries to run x86-64 aapt2, it silently fails.

## Symptom 3: required file not found (glibc binary on Bionic)
```
/data/data/com.termux/files/home/android-sdk/build-tools/35.0.1/aapt2: cannot execute: required file not found
```
**Cause**: ARM64 binary compiled against glibc, but Termux uses Bionic libc. The dynamic linker `ld-linux-aarch64.so.1` is missing.

## Solution
Use [lzhiyong/android-sdk-tools](https://github.com/lzhiyong/android-sdk-tools/releases) — compiled for Termux/Android (Bionic libc).

```bash
curl -fsSL "https://github.com/lzhiyong/android-sdk-tools/releases/download/35.0.2/android-sdk-tools-static-aarch64.zip" -o ~/lzhiyong-aarch64.zip
unzip -o ~/lzhiyong-aarch64.zip -d ~/lzhiyong-tools
```

### Files included
| File | Size | Purpose |
|------|------|---------|
| aapt2 | 6.5MB | Android Asset Packaging Tool 2 |
| aidl | 3.5MB | Android Interface Definition Language |
| zipalign | 834KB | APK alignment tool |
| split-select | 1.6MB | Split APK selector |
| dexdump | 1.4MB | DEX file inspector |
| aapt | 2.6MB | Legacy AAPT (v1) |

### Do NOT use
- **Commit451/android-arm-build-tools** — compiled against glibc, fails on Termux Bionic
- **proot-distro** — user explicitly rejected; adds complexity and overhead

## Verification
```bash
~/lzhiyong-tools/build-tools/aapt2 version
# Expected: Android Asset Packaging Tool (aapt) 2.XX-...
```
