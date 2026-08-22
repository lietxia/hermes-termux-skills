# Haven Project Migration Notes

## Source: GlassHaven/Haven v5.62.0 (AGPL-3.0)
- GitHub: https://github.com/GlassHaven/Haven
- Stars: 793, 1905 files, 1723 commits
- License: AGPL-3.0

## Architecture
- 25 core modules (ssh, terminal-haven, mosh, security, tunnel, fido, rclone, vnc, rdp, etc.)
- 12 feature modules (terminal, sftp, connections, keys, editor, settings, etc.)
- 8 git submodules (termlib, mosh-kotlin, et-kotlin, wayland-android, reticulum-kt, rnsh-kt, spice-kotlin, proot-termux)
- Single app module (phone only, no TV/Wear)

## Key Versions (as of 2026-06-30)
```
AGP: 8.9.1
Kotlin: 2.3.10
KSP: 2.3.6
Hilt: 2.58
compileSdk: 36
minSdk: 26
Gradle: 9.4.1
```

## Submodule URLs (GlassOnTin org)
- termlib: https://github.com/GlassOnTin/termlib.git
- mosh-kotlin (ssp-transport): https://github.com/GlassOnTin/ssp-transport.git
- et-kotlin: https://github.com/GlassOnTin/et-kotlin.git
- wayland-android: https://github.com/GlassOnTin/wayland-android.git
- reticulum-kt: https://github.com/GlassOnTin/reticulum-kt.git
- rnsh-kt: https://github.com/GlassOnTin/rnsh-kt.git
- spice-kotlin: https://github.com/GlassOnTin/spice-kotlin.git
- proot-termux: https://github.com/GlassOnTin/proot.git (branch: haven-299-fd-fix)

## Migration Steps (Haven → vTerm)
1. Clone Haven with --depth 1
2. Copy all files (except .git) to vTerm repo
3. Manually clone each submodule (git submodule update fails with shallow parent)
4. Add local.properties with sdk.dir
5. Add gradle.properties: aapt2FromMavenOverride + verification=off + ndkVersion
6. Delete all verification-metadata.xml files
7. Fix termlib/lib/build.gradle.kts: remove publish/metalava/dokka plugins, keep kotlin.android
8. Fix termlib/build.gradle.kts: minimal (android + kotlin plugins with apply false)
9. Unify Kotlin version in termlib/gradle/libs.versions.toml to match root
10. Use JDK 21 (rnsh-kt needs it)

## Multi-Device Status
- Phone: ✅ (Haven's only target)
- Tablet: ✅ (WindowSizeClass adaptive layout)
- TV: ❌ Not implemented — need new app-tv module
- Wear OS: ❌ Not implemented — need new app-wear module
- HarmonyOS/iOS/Desktop: ❌ Separate repos

## Files Modified for Termux Build
- gradle/libs.versions.toml (no changes needed — original versions work)
- termlib/lib/build.gradle.kts (removed publish/metalava/dokka, added kotlin.android back)
- termlib/build.gradle.kts (stripped to minimal: android.library + android.application + kotlin.android + kotlin.compose with apply false)
- termlib/gradle/libs.versions.toml (AGP kept at 8.9.1 to match root)
- gradle.properties (added aapt2FromMavenOverride + ndkVersion)
- settings.gradle.kts (removed mosh-kotlin, rdp-kotlin, spice-kotlin, rclone-android includeBuild blocks)
- app/build.gradle.kts (commented out core:mosh, core:rdp, core:spice, core:rclone, feature:rdp dependencies)
- core/ssh/build.gradle.kts (commented out core:mosh, core:rdp)
- core/mosh, core/rclone, core/rdp, core/spice build.gradle.kts (commented out sh.haven:*-transport dependencies)
- feature/connections, feature/sftp, feature/terminal, feature/vnc build.gradle.kts (commented out mosh/rclone deps)
- rdp-kotlin/build.gradle.kts (disabled buildRdpNative task)
- spice-kotlin/build.gradle.kts (disabled buildSpiceNative task)
- rclone-android/build.gradle.kts (disabled buildRcloneNative task)
- core/local/build.gradle.kts (disabled buildProot, buildWayvncShim, buildHavenUsb tasks)

## Native Modules Not Yet Compilable on Termux
These modules need tools not available in Termux (cargo-ndk, gomobile, protoc):
- mosh-kotlin (protobuf)
- rdp-kotlin (Rust/cargo-ndk)
- spice-kotlin (Rust/cargo-ndk)
- rclone-android (Go/gomobile)
- core/local (C cross-compilation for proot/wayvnc/usb)

Core SSH + terminal + SFTP + connections work without them.

## NDK on Termux
- Google's official NDK: x86_64 only, won't run on ARM64 Termux
- lzhiyong/termux-ndk: ARM64 musl-static clang, works on Termux
- Symlink trick: `ln -sf 29.0.14206865 27.0.12077973` to redirect AGP's auto-download
