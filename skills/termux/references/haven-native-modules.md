# Haven / vTerm: Handling Native Modules on Termux

Haven's `core:ssh` and friends pull in modules that need `cargo-ndk`, `gomobile`, or
`protoc` — none of which run on Termux. When the build fails on
`sh.haven:*-transport:0.1.0`, there are two ways out.

## Option A — decouple (remove the modules)

Modify Kotlin source to drop the dependencies. Larger diff, easier to get wrong.

Files involved:

- `core/ssh/.../SessionManagerRegistry.kt` — remove the `MoshSessionManager`,
  `RdpSessionManager`, and `MailSessionManager` imports, constructor parameters,
  `disconnectProfile()` calls, `hasActiveSessions()` references, `allSessions` map
  entries, and the `toSession()` extension at the bottom.
- `core/ssh/.../ForegroundSessionParticipantModule.kt` — remove the `mosh()`, `rdp()`,
  and similar `@Provides` functions plus their imports.
- Anything else referencing those types:

```bash
grep -rn "MoshSessionManager\|RdpSessionManager\|MailSessionManager\|RcloneClient\|RcloneSessionManager" \
  --include="*.kt" core/ feature/ app/
```

Then comment out the `includeBuild` blocks in `settings.gradle.kts` and the
`implementation(project(":core:..."))` lines in every module. See
[native-build-tasks.md](native-build-tasks.md) for the task-level list.

## Option B — restore (re-register the submodules) — recommended

Keep all the code and re-add the Gradle wiring. Configuration-level only, far less
chance of a missed reference.

### 1. Confirm the submodule directories exist

```bash
ls -d mosh-kotlin/ rdp-kotlin/ spice-kotlin/ rclone-android/
ls mosh-kotlin/build.gradle.kts rdp-kotlin/build.gradle.kts
```

If empty, clone them from the URLs in `.gitmodules`:

```bash
git config --file .gitmodules --get-regexp "submodule\..*\.url" | while read key url; do
    path=$(echo "$key" | sed 's/submodule\.\(.*\)\.url/\1/')
    git clone --depth 1 "$url" "$path"
done
```

### 2. Re-add the `includeBuild` blocks

Copy them from Haven's own `settings.gradle.kts`:

```kotlin
includeBuild("mosh-kotlin") {
    dependencySubstitution {
        substitute(module("sh.haven:ssp-transport")).using(project(":"))
    }
}
includeBuild("rdp-kotlin") {
    dependencySubstitution {
        substitute(module("sh.haven:rdp-transport")).using(project(":"))
    }
}
includeBuild("spice-kotlin") {
    dependencySubstitution {
        substitute(module("sh.haven:spice-transport")).using(project(":"))
    }
}
includeBuild("rclone-android") {
    dependencySubstitution {
        substitute(module("sh.haven:rclone-transport")).using(project(":"))
    }
}
```

### 3. Re-register the modules

```kotlin
include(":core:mosh")
include(":core:rdp")
include(":core:rclone")
include(":core:mail")
include(":feature:rdp")
include(":feature:mail")
```

### 4. Restore the commented dependencies

Watch for double-commenting (`// //`) and for `app/build.gradle.kts`, which is easy to
miss:

```bash
find feature/ core/ app/ -name "build.gradle.kts" -exec sed -i \
  -e 's|// implementation(project(":core:mosh")) // TODO:.*|implementation(project(":core:mosh"))|g' \
  -e 's|// // implementation(project(":core:mosh")) // TODO:.*|implementation(project(":core:mosh"))|g' \
  {} \;
```

Verify nothing is left:

```bash
grep -rn '// implementation.*TODO\|// api.*TODO\|// // impl' --include="build.gradle.kts" feature/ core/ app/
```

### 5. Fix protoc for mosh-kotlin

`com.google.protobuf:protoc` downloads an x86_64 binary that cannot run on Termux.
Install the Termux-native one and point Gradle at it:

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

**Version pairing matters.** `protoc` 33.x emits `@com.google.protobuf.Generated`,
which only exists in protobuf-java 4.33.x. A lower protobuf-javalite fails with
`cannot find symbol @com.google.protobuf.Generated`.

```kotlin
dependencies {
    implementation("com.google.protobuf:protobuf-javalite:4.33.1")
    compileOnly("com.google.protobuf:protobuf-java:4.33.1")
}
```

Check the pairing with `protoc --version` — `libprotoc 33.1` maps to `4.33.1`.

### 6. Check for stubbed source files

If a previous attempt replaced uncompilable files with empty stubs, downstream modules
fail with type mismatches such as:

```
Argument type mismatch: actual type is 'RcloneFileBackend', but 'FileBackend' was expected.
Too many arguments for 'constructor(): RcloneFileBackend'.
```

```bash
grep -rn "Stub\|Deleted.*removed\|module removed" --include="*.kt" feature/ core/ app/
git checkout HEAD -- path/to/StubbedFile.kt
```

### 7. Disable the Rust and Go tasks

`buildRcloneNative` (gomobile) and the `buildRdpNative` / `buildSpiceNative`
(cargo-ndk) tasks cannot run on Termux:

```kotlin
val buildRcloneNative by tasks.registering(Exec::class) {
    enabled = false // Disabled for Termux build
}
```

## Choosing

| | Restore (B) | Decouple (A) |
|--|-------------|--------------|
| Diff size | ~5 config files | 20+ Kotlin source files |
| Risk | Low | High — a missed reference surfaces as a KSP error |
| Features kept | All | Drops mosh/rdp/rclone/mail |
| Use when | Submodule sources are available | Submodule sources are missing |

## Common errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Could not find sh.haven:xxx-transport:0.1.0` | `includeBuild` missing | Add `includeBuild` + `dependencySubstitution` |
| `Project with path ':core:xxx' could not be found` | Module not in `settings.gradle.kts` | Add `include(":core:xxx")` |
| `KSP PROCESSING_ERROR: could not be resolved` | Dependency commented out | Uncomment `implementation(project(":core:xxx"))` |
| `protoc: stdout: . stderr:` | x86_64 protoc binary | `pkg install protobuf`, use `path` instead of `artifact` |
| `cannot find symbol @Generated` | protoc/protobuf-java mismatch | Align versions (protoc 33.x → 4.33.x) |
| `Too many arguments for constructor` | Source replaced with a stub | `git checkout HEAD -- path/to/file.kt` |
