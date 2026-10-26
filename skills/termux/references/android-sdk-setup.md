# Android SDK Setup on Termux (ARM64)

Google's SDK build-tools and platform-tools ship **x86_64 only**. On aarch64 Termux
they fail with `Exec format error`, or with `cannot execute: required file not found`
when the replacement is a glibc build. Fix: replace them with Bionic-linked ARM64
builds.

## Install the SDK

```bash
export ANDROID_HOME="$HOME/android-sdk"
mkdir -p "$ANDROID_HOME/cmdline-tools"
curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" -o ~/cmdline-tools.zip
unzip -o ~/cmdline-tools.zip -d "$ANDROID_HOME/cmdline-tools/"
mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" "platforms;android-35" "build-tools;35.0.1"
```

## Replace the x86_64 tools

The ARM64 replacement set is [lzhiyong/android-sdk-tools](https://github.com/lzhiyong/android-sdk-tools)
(Bionic libc). `Commit451/android-arm-build-tools` and `SnowNF/ndk-aarch64-linux`
are glibc builds — they need `ld-linux-aarch64.so.1`, which Bionic does not provide,
and fail on Termux.

```bash
curl -fsSL "https://github.com/lzhiyong/android-sdk-tools/releases/download/35.0.2/android-sdk-tools-static-aarch64.zip" -o ~/lzhiyong-aarch64.zip
unzip -o ~/lzhiyong-aarch64.zip -d ~/lzhiyong-tools

for ver in "$ANDROID_HOME"/build-tools/*/; do
    for tool in aapt2 aidl zipalign split-select dexdump aapt; do
        [ -f "$ver/$tool" ] && cp ~/lzhiyong-tools/build-tools/$tool "$ver/$tool" && chmod +x "$ver/$tool"
    done
done

cp ~/lzhiyong-tools/platform-tools/adb "$ANDROID_HOME/platform-tools/adb"
chmod +x "$ANDROID_HOME/platform-tools/adb"
```

Files in the release: `aapt2`, `aidl`, `zipalign`, `split-select`, `dexdump`, `aapt`
(build-tools) and `adb` (platform-tools).

## Override the Maven aapt2 (AGP 8.x and 9.x)

AGP downloads its own aapt2 from Maven — also x86_64. Point it at the ARM64 build:

```properties
# gradle.properties (project root)
android.aapt2FromMavenOverride=/absolute/path/to/android-sdk/build-tools/35.0.1/aapt2
```

The path is a **file**, not a directory. A malformed value here produces the
`Daemon startup failed` error below.

## CMake and Ninja

The SDK's bundled CMake is x86_64 too. Use the Termux-native ones and symlink:

```bash
pkg install cmake ninja
ln -sf "$PREFIX/bin/cmake"  "$ANDROID_HOME/cmake/3.22.1/bin/cmake"
ln -sf "$PREFIX/bin/ninja"  "$ANDROID_HOME/cmake/3.22.1/bin/ninja"
```

## Symptoms

| Error | Cause |
|-------|-------|
| `Exec format error` | x86_64 binary on an aarch64 host |
| `AAPT2 aapt2-<ver>-linux Daemon #0: Daemon startup failed` | AGP ran a Maven-downloaded x86_64 aapt2 |
| `cannot execute: required file not found` | ARM64 binary built against glibc, on Bionic |

## Verify

```bash
readelf -h "$ANDROID_HOME/build-tools/35.0.1/aapt2" | grep Machine
# AArch64 — good.  "Advanced Micro Devices X86-64" — needs replacement.
"$ANDROID_HOME/build-tools/35.0.1/aapt2" version
"$ANDROID_HOME/platform-tools/adb" version
```

Or run the bundled audit: `bash scripts/verify-arm64-sdk.sh`.

## Reference

- lzhiyong/android-sdk-tools: https://github.com/lzhiyong/android-sdk-tools
- Commit451 (glibc — not for Termux): https://github.com/Commit451/android-arm-build-tools
- Google issue: https://issuetracker.google.com/issues/227219818
