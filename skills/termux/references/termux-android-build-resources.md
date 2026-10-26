# External Android Tool Repos

Where to get ARM64 Android toolchain binaries, and which ones actually work on Termux.

## Termux-compatible (Bionic libc)

| Tool | Repo | Purpose |
|------|------|---------|
| termux-ndk | [lzhiyong/termux-ndk](https://github.com/lzhiyong/termux-ndk) | NDK r29 with aarch64 clang, musl-static |
| android-sdk-tools | [lzhiyong/android-sdk-tools](https://github.com/lzhiyong/android-sdk-tools) | aarch64 aapt2/aidl/zipalign/adb |

**lzhiyong is the authoritative source for Termux-compatible Android tooling.**

## Not usable on Termux (glibc)

| Repo | Why it fails |
|------|--------------|
| [Commit451/android-arm-build-tools](https://github.com/Commit451/android-arm-build-tools) | aarch64 ELF, but links glibc; needs `ld-linux-aarch64.so.1` |
| [SnowNF/ndk-aarch64-linux](https://github.com/SnowNF/ndk-aarch64-linux) | aarch64 ELF, built for "gnu/linux"; same glibc loader problem |

Both download fine and report the correct architecture. They then fail at exec time
with `cannot execute: required file not found`, because Bionic has no
`/lib/ld-linux-aarch64.so.1`. Do not spend time on these for a pure Termux host.

## Why the official tools do not work

- Google NDK clang: x86_64 ELF, needs `/lib64/ld-linux-x86-64.so.2`.
- Google AAPT2/build-tools: x86_64 only.
- AGP's Maven aapt2: x86_64 only — hence `android.aapt2FromMavenOverride`.

## 7z handling

p7zip 17.05 in Termux may reject newer 7z archives:

```bash
7z t file.7z                    # verify integrity first
7z x file.7z -y -oDIR           # extract if the check passes
```

If `7z t` reports the archive cannot be opened, re-download — the file is incomplete.
`py7zr` usually fails to build on Termux; use the `7z` binary.

## Gradle on Termux

- `--no-daemon` to avoid OOM on 11GB devices.
- Clear `.gradle/caches/` when changing NDK or AGP versions.
- `org.gradle.dependency.verification=off` is effectively mandatory.
- `android.aapt2FromMavenOverride` must point at the ARM64 aapt2.

## AGP 9.x migration notes

1. Remove `alias(libs.plugins.kotlin.android)` from every `build.gradle.kts` — AGP 9
   has Kotlin built in.
2. Hilt 2.58 does not work with AGP 9.x. Stay on AGP 8.x if the project uses Hilt.
3. `includeBuild` submodules must use the same AGP version as the root.
4. maven.publish 0.36.0 requires AGP 8.13+ — use 0.30.0, or remove the plugin.
5. KSP tracks the Kotlin minor version; there is no KSP 2.4.x yet, so Kotlin 2.4.x
   is unusable with KSP/Hilt.
