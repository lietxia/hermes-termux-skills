# Haven Project Migration on Termux

Reference guide for building [GlassHaven/Haven](https://github.com/GlassHaven/Haven) on Termux.

## Project Structure

Haven uses `includeBuild` for many submodules, each potentially with different AGP/Kotlin versions:
- `termlib` — ConnectBot terminal library (GlassOnTin fork, NOT connectbot upstream)
- `mosh-kotlin` — Mosh protocol (requires protobuf)
- `rdp-kotlin` — RDP client (requires cargo-ndk/Rust)
- `spice-kotlin` — SPICE client (requires cargo-ndk/Rust)
- `rclone-android` — Cloud storage (requires gomobile/Go)
- `et-kotlin` — Eternal Terminal (pure Kotlin, works)
- `rnsh-kt` — rnsh client (requires JDK 21)
- `reticulum-kt` — Reticulum network (pure Kotlin, works)

## Version Matrix (tested working)

| Component | Version |
|-----------|---------|
| AGP | 8.9.1 |
| Kotlin | 2.3.10 |
| KSP | 2.3.6 |
| Hilt | 2.58 |
| Gradle | 9.4.1 |
| JDK | 21 |
| compileSdk | 36 |
| NDK | 29.0.14206865 (termux-ndk) |

## Modules to Disable on Termux

These modules require native cross-compilation tools not available on Termux:

1. **mosh-kotlin** — needs `protoc` for protobuf generation
2. **rdp-kotlin** — needs `cargo ndk` (Rust)
3. **spice-kotlin** — needs `cargo ndk` (Rust)
4. **rclone-android** — needs `gomobile` (Go)
5. **core:local** — needs `proot`, `wayvnc`, USB native builds
6. **core:mail** — needs native mail bridge (MailBridge JNI)

## Steps to Disable

### 1. settings.gradle.kts
Remove entire `includeBuild("xxx") { dependencySubstitution { ... } }` blocks for disabled modules.

### 2. All build.gradle.kts files
Comment out `implementation(project(":core:mosh"))`, `:core:rdp`, `:core:spice`, `:core:rclone`, `:core:mail`, `:feature:mail`, `:feature:rdp`.

### 3. Native Exec tasks
Add `enabled = false` to:
- `rdp-kotlin/build.gradle.kts` → `buildRdpNative`
- `spice-kotlin/build.gradle.kts` → `buildSpiceNative`
- `rclone-android/build.gradle.kts` → `buildRcloneNative`
- `core/local/build.gradle.kts` → `buildProot`, `buildWayvncShim`, `buildHavenUsb`

### 4. termlib cleanup
- Use GlassOnTin fork (not connectbot): `https://github.com/GlassOnTin/termlib.git` branch `feature/154-cf-access-diagnostics`
- Strip publish/dokka/metalava plugins from `termlib/lib/build.gradle.kts`
- Strip spotless/release from `termlib/build.gradle.kts`
- Exclude test-app from `termlib/settings.gradle.kts`
- Unify Kotlin version with root project

## Key Pitfalls

- **Submodule fork**: Haven's termlib points to GlassOnTin fork, not connectbot. Wrong fork = missing API classes (TerminalGestureCallback, etc.)
- **AGP version must match**: includeBuild modules must use same AGP as root project
- **JVM target**: Java 17 compileOptions + Kotlin compilerOptions must agree
- **kotlinOptions deprecated**: Kotlin 2.3.10 treats it as error, use compilerOptions DSL
- **Configuration cache**: May break plugins using script object references. Set `org.gradle.configuration-cache=false` if needed.
