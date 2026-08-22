# Android SDK Development on Termux (ARM64)

## Critical: ARM64 Build-Tools

Google's Android SDK Manager **only ships x86_64 native binaries** for `aapt2`, `aidl`, `zipalign`, `split-select`, `dexdump`. On Termux (aarch64), these cause `Exec format error` or `Daemon startup failed`.

### Solution: lzhiyong/android-sdk-tools

```bash
# Download ARM64 build-tools
curl -fsSL "https://github.com/lzhiyong/android-sdk-tools/releases/download/35.0.2/android-sdk-tools-static-aarch64.zip" -o ~/lzhiyong-aarch64.zip
unzip -o ~/lzhiyong-aarch64.zip -d ~/lzhiyong-tools

# Replace in SDK
BUILD_TOOLS="$ANDROID_HOME/build-tools/<VERSION>"
cp ~/lzhiyong-tools/build-tools/aapt2 "$BUILD_TOOLS/aapt2"
cp ~/lzhiyong-tools/build-tools/aidl "$BUILD_TOOLS/aidl"
cp ~/lzhiyong-tools/build-tools/zipalign "$BUILD_TOOLS/zipalign"
cp ~/lzhiyong-tools/build-tools/split-select "$BUILD_TOOLS/split-select"
cp ~/lzhiyong-tools/build-tools/dexdump "$BUILD_TOOLS/dexdump"
chmod +x "$BUILD_TOOLS/aapt2" "$BUILD_TOOLS/aidl" "$BUILD_TOOLS/zipalign" "$BUILD_TOOLS/split-select" "$BUILD_TOOLS/dexdump"

# Also replace platform-tools (adb)
cp ~/lzhiyong-tools/platform-tools/adb "$ANDROID_HOME/platform-tools/adb"
chmod +x "$ANDROID_HOME/platform-tools/adb"
```

### AGP Maven aapt2 Override

AGP 8.x+ downloads its own `aapt2` from Maven (x86_64 only). Must override in `gradle.properties`:

```properties
android.aapt2FromMavenOverride=/data/data/com.termux/files/home/android-sdk/build-tools/<VERSION>/aapt2
```

Also replace the Maven-cached copy:
```bash
find ~/.gradle -name "aapt2-*-linux" -type f 2>/dev/null  # find cached x86_64 version
# Replace with ARM64 version from lzhiyong-tools
```

## JDK Setup

```bash
pkg install openjdk-17 openjdk-21
# Set JAVA_HOME based on project requirements:
export JAVA_HOME=/data/data/com.termux/files/usr/lib/jvm/java-21-openjdk
```

- **AGP 8.x**: JDK 17 works
- **AGP 9.x / Kotlin 2.3+**: May need JDK 21 (e.g., `rnsh-kt` requires `languageVersion=21`)

## Android SDK Installation

```bash
export ANDROID_HOME="$HOME/android-sdk"
mkdir -p "$ANDROID_HOME/cmdline-tools"
curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" -o ~/cmdline-tools.zip
unzip -o ~/cmdline-tools.zip -d "$ANDROID_HOME/cmdline-tools/"
mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"

# Accept licenses and install components
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platforms;android-36" "build-tools;36.0.0" "platform-tools"
```

## Environment Variables (~/.bashrc)

```bash
export JAVA_HOME=/data/data/com.termux/files/usr/lib/jvm/java-21-openjdk
export ANDROID_HOME="$HOME/android-sdk"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```

## Gradle Configuration

### local.properties
```properties
sdk.dir=/data/data/com.termux/files/home/android-sdk
```

### gradle.properties additions
```properties
# ARM64 aapt2
android.aapt2FromMavenOverride=/data/data/com.termux/files/home/android-sdk/build-tools/<VERSION>/aapt2

# Disable dependency verification (submodule builds often fail verification)
org.gradle.dependency.verification=off
```

## AGP Version Compatibility Pitfalls

| Issue | Solution |
|-------|----------|
| `kotlin.android` plugin error with AGP 9.x | AGP 9.0+ has built-in Kotlin; remove `alias(libs.plugins.kotlin.android)` from all `build.gradle.kts` |
| Hilt `Could not find AGP base extension` | Hilt 2.58 not compatible with AGP 9.x; use AGP 8.x |
| `maven.publish` requires AGP 8.13+ | Downgrade `com.vanniktech.maven.publish` or disable publishing in submodule builds |
| AGP 9.x + 8.x mixed in same build | **Not allowed** — all modules and `includeBuild` must use same AGP major version |
| KSP version mismatch | KSP version must match Kotlin version (e.g., Kotlin 2.3.21 → KSP 2.3.9) |
| Dependency verification failure | Delete all `gradle/verification-metadata.xml` and set `org.gradle.dependency.verification=off` |

## Git Submodules

When cloning with `--depth 1`, submodules won't initialize automatically:

```bash
# Manual clone of each submodule
for sub in termlib mosh-kotlin et-kotlin; do
    url=$(git config --file .gitmodules --get "submodule.$sub.url")
    git clone --depth 1 "$url" "$sub"
done
```

## /tmp Not Writable

Termux's `/tmp` is owned by `shell:shell` and not writable by the app user. Always write to `$HOME` instead.
