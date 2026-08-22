# Disabling Native Build Tasks on Termux

## Pattern
When a module has native build tasks (Rust/Go/C cross-compilation) that can't run on Termux:

```kotlin
// In build.gradle.kts
val buildXxxNative by tasks.registering(Exec::class) {
    enabled = false // Disabled for Termux build (no cargo-ndk/gomobile/etc)
    // ... rest of task definition stays ...
}
```

## Also Disable Dependencies
1. Comment out `includeBuild("xxx")` blocks in `settings.gradle.kts`
2. Comment out `implementation(project(":core:xxx"))` in all `build.gradle.kts` files
3. Comment out `implementation("sh.haven:xxx-transport:...")` references

## Common Modules to Disable

### Rust-based (need cargo-ndk)
- `rdp-kotlin` → `buildRdpNative`
- `spice-kotlin` → `buildSpiceNative`

### Go-based (need gomobile)
- `rclone-android` → `buildRcloneNative`

### C cross-compilation (need gcc-aarch64-linux-gnu)
- `core:local` → `buildProot`, `buildWayvncShim`, `buildHavenUsb`

### Protobuf (need protoc)
- `mosh-kotlin` → `generateProto` task

## Verification
After disabling, run:
```bash
grep -rn "core:mosh\|core:rdp\|core:spice\|core:rclone" --include="*.gradle.kts" . | grep -v "//" | grep "implementation"
```
Should return empty (all commented out).
