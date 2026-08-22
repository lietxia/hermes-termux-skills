# Termux Android Build — Key External Resources

## ARM64 Pre-built Tools (Critical)

| Tool | Repo | Purpose |
|------|------|---------|
| termux-ndk | [lzhiyong/termux-ndk](https://github.com/lzhiyong/termux-ndk) | NDK with ARM64 clang (musl static, 802★) |
| android-sdk-tools | [lzhiyong/android-sdk-tools](https://github.com/lzhiyong/android-sdk-tools) | ARM64 aapt2/aidl/adb (629★) |
| ndk-aarch64-linux | [SnowNF/ndk-aarch64-linux](https://github.com/SnowNF/ndk-aarch64-linux) | ARM64 NDK (glibc, needs /lib/ld-linux) |

**lzhiyong** is the authoritative source for Termux-compatible Android tooling.

## Why Official Tools Don't Work

- Google NDK clang: x86_64 ELF, needs `/lib64/ld-linux-x86-64.so.2`
- SnowNF ARM64 NDK: aarch64 ELF but needs `/lib/ld-linux-aarch64.so.1` (glibc)
- lzhiyong termux-ndk: aarch64 ELF, musl static linked — **works on Termux**
- Official AAPT2/build-tools: x86_64 only
- lzhiyong android-sdk-tools: aarch64 native — **works on Termux**

## 7z File Handling

p7zip 17.05 in Termux may fail on newer 7z archives. Workaround:
1. `7z t file.7z` to verify integrity first
2. If "Can't open as archive", re-download — file may be incomplete
3. `7z x file.7z -y -oDIR` works if integrity check passes
4. py7zr Python package often fails to build on Termux

## Gradle on Termux

- Use `--no-daemon` to avoid OOM (11GB RAM device, JVM takes 4GB)
- Clear `.gradle/caches/` when changing NDK/AGP versions
- `org.gradle.dependency.verification=off` is mandatory
- `android.aapt2FromMavenOverride` must point to ARM64 aapt2

## AGP 9.x Migration Notes

When upgrading from AGP 8.x to 9.x:
1. Remove `alias(libs.plugins.kotlin.android)` from ALL build.gradle.kts (AGP 9 has built-in Kotlin)
2. Hilt 2.58 does NOT work with AGP 9.x — keep AGP 8.x if using Hilt
3. `includeBuild` submodules must use same AGP version
4. maven.publish 0.36.0 requires AGP 8.13+ — use 0.30.0 or remove
5. KSP version must match Kotlin: e.g. Kotlin 2.3.10 → KSP 2.3.9
