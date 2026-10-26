# Disabling Native Build Tasks on Termux

When a module has native build tasks (Rust, Go, C cross-compilation) that cannot run
on Termux, disable the task rather than the whole module where possible.

## Pattern

```kotlin
// build.gradle.kts
val buildXxxNative by tasks.registering(Exec::class) {
    enabled = false // Disabled for Termux build (no cargo-ndk / gomobile / protoc)
    // ... rest of the task definition stays ...
}
```

## Also disable the dependencies

1. Comment out `includeBuild("xxx")` blocks in `settings.gradle.kts`.
2. Comment out `implementation(project(":core:xxx"))` in every `build.gradle.kts`.
3. Comment out `implementation("sh.haven:xxx-transport:...")` references.

## Tasks known to need disabling

### Rust (needs cargo-ndk)
- `rdp-kotlin` → `buildRdpNative`
- `spice-kotlin` → `buildSpiceNative`

### Go (needs gomobile)
- `rclone-android` → `buildRcloneNative`

### C cross-compilation (needs gcc-aarch64-linux-gnu)
- `core:local` → `buildProot`, `buildWayvncShim`, `buildHavenUsb`

### Protobuf (needs protoc)
- `mosh-kotlin` → `generateProto`

For a project-specific walkthrough, see
[haven-native-modules.md](haven-native-modules.md).

## Verification

Confirm no live dependency on the disabled modules remains:

```bash
grep -rn "core:mosh\|core:rdp\|core:spice\|core:rclone" --include="*.gradle.kts" . \
  | grep -v "//" | grep "implementation"
```

Should print nothing.

## protoc alternative

If `mosh-kotlin` must be built, install Termux-native protoc and point Gradle at it
instead of the Maven x86_64 binary:

```bash
pkg install protobuf
```

```kotlin
protobuf {
    protoc {
        path = "/data/data/com.termux/files/usr/bin/protoc"
    }
}
```

The system protoc version must match the protobuf-java version, or compilation fails
with `cannot find symbol @com.google.protobuf.Generated`. See
[haven-native-modules.md](haven-native-modules.md) for the version pairing.
