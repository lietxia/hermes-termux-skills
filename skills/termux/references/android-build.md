# Android Build on Termux — JDK, Gradle, AGP matrix

## JDK

```bash
pkg install openjdk-17 openjdk-21
export JAVA_HOME=/data/data/com.termux/files/usr/lib/jvm/java-21-openjdk
```

| Scenario | JDK |
|----------|-----|
| AGP 8.x + Kotlin 2.3.x | 17 or 21 |
| AGP 9.x, or any module needing JDK 21 | 21 |

## gradle.properties

```properties
# 11GB+ RAM device; the JVM otherwise takes ~4GB
org.gradle.jvmargs=-Xmx8192m -XX:MaxMetaspaceSize=512m

# Dependency verification fails on Termux over network/signature issues
org.gradle.dependency.verification=off

# Point at the ARM64 aapt2 (see android-sdk-setup.md)
android.aapt2FromMavenOverride=/absolute/path/to/android-sdk/build-tools/35.0.1/aapt2

# Avoid the daemon on memory-constrained devices
org.gradle.daemon=false
```

Delete any checked-in verification metadata after turning verification off:

```bash
find . -name "verification-metadata.xml" -path "*/gradle/*" -exec rm -f {} \;
```

Clear the Gradle caches when you change NDK or AGP versions:

```bash
rm -rf ~/.gradle/caches/*/transforms/
```

## AGP / Kotlin / KSP matrix

Tested combinations on Termux aarch64:

| AGP | Kotlin | KSP | Hilt | JDK | Notes |
|-----|--------|-----|------|-----|-------|
| 8.9.1 | 2.3.10 | 2.3.6 | 2.58 | 17 or 21 | Default for Haven/vTerm |
| 8.9.1 | 2.3.21 | 2.3.9 | 2.58 | 17 or 21 | Newer stable Kotlin, still on AGP 8.x |
| 9.2.0 | 2.3.21 | 2.3.9 | incompatible | 21 | AGP 9 breaks Hilt |

Current upstream versions (checked 2026-10-26): AGP stable 9.4.1 (9.5.0-rc01,
9.6.0-alpha01 also published); Kotlin stable 2.4.21; KSP **2.3.12**.

## Rules

1. **KSP tracks the Kotlin minor version** (Kotlin 2.3.x → KSP 2.3.x).
2. **KSP lags Kotlin.** Kotlin 2.4.21 is current but there is no KSP 2.4.x — the
   latest is 2.3.12. Pin Kotlin 2.3.x whenever you use KSP or Hilt.
3. **AGP 8.x and 9.x cannot coexist** in one build, including `includeBuild` modules.
   Unify every `gradle/libs.versions.toml` or Gradle fails with
   `Using multiple versions of the Android Gradle plugin`.
4. **AGP 9.0+ requires JDK 21.**
5. **AGP 9.0+ builds Kotlin in** — remove the `kotlin.android` plugin from every
   `build.gradle.kts`, or Gradle errors with
   `The 'org.jetbrains.kotlin.android' plugin is no longer required since AGP 9.0`.
6. **Hilt ≤ 2.58 is incompatible with AGP 9.x** — it uses the removed `BaseExtension`
   and fails with `Could not find the Android Gradle Plugin (AGP) base extension`.
   Stay on AGP 8.x when using Hilt.
7. **`kotlinOptions {}` is an error on Kotlin 2.3.x** — use the `compilerOptions` DSL.
8. **maven.publish 0.36.0 requires AGP 8.13+.** On AGP 8.9.1 use 0.30.0, or strip the
   publish/metalava/dokka plugins entirely — they are not needed to compile.

## includeBuild version unification

Every `includeBuild` project must match the root AGP and Kotlin versions:

```bash
grep -r "androidGradlePlugin\|kotlin =" gradle/libs.versions.toml */gradle/libs.versions.toml
```

## Memory and daemon

```bash
./gradlew assembleDebug --no-daemon
```

`--no-daemon` avoids OOM on 11GB devices. If the configuration cache breaks a plugin
that references script objects, set `org.gradle.configuration-cache=false`.

## Verification checklist

```bash
java -version
"$ANDROID_HOME/build-tools/35.0.1/aapt2" version
"$ANDROID_HOME/platform-tools/adb" version
cmake --version
cd /path/to/project && ./gradlew assembleDebug --dry-run
```

## Related

- [android-sdk-setup.md](android-sdk-setup.md) — ARM64 tool replacement
- [ndk-setup.md](ndk-setup.md) — NDK and CMake/Ninja
- [native-build-tasks.md](native-build-tasks.md) — disabling native modules
- [haven-build.md](haven-build.md) — the Haven/vTerm build configuration
