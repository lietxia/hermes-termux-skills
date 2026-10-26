# Haven / vTerm Build Configuration

Building [GlassHaven/Haven](https://github.com/GlassHaven/Haven) (or a vTerm fork of
it) on Termux.

## Version matrix (tested working)

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

Keep AGP on 8.x while Hilt is in use — see
[android-build.md](android-build.md) for why AGP 9.x breaks Hilt.

## Project structure

```
Haven/
├── app/                       # Main Android app (single module, no android/ subdir)
├── core/                      # 25 core modules
├── feature/                   # 12 feature modules
├── termlib/                   # Terminal library (includeBuild, own AGP version)
├── mosh-kotlin/               # Mosh protocol (submodule)
├── et-kotlin/                 # Eternal Terminal (submodule)
├── rclone-android/            # rclone integration
├── rdp-kotlin/                # RDP client
├── wayland-android/           # Wayland compositor
├── build.gradle.kts
├── settings.gradle.kts
└── gradle/libs.versions.toml
```

Differences from a typical vTerm layout: `app/` sits at the project root rather than
under `android/`; `termlib` is an `includeBuild`, not a module dependency; and there
are eight git submodules.

## Submodule URLs (GlassOnTin org)

- termlib: https://github.com/GlassOnTin/termlib.git
- mosh-kotlin (ssp-transport): https://github.com/GlassOnTin/ssp-transport.git
- et-kotlin: https://github.com/GlassOnTin/et-kotlin.git
- wayland-android: https://github.com/GlassOnTin/wayland-android.git
- reticulum-kt: https://github.com/GlassOnTin/reticulum-kt.git
- rnsh-kt: https://github.com/GlassOnTin/rnsh-kt.git
- spice-kotlin: https://github.com/GlassOnTin/spice-kotlin.git
- proot-termux: https://github.com/GlassOnTin/proot.git (branch `haven-299-fd-fix`)

## Migration steps (Haven → vTerm)

1. Back up the original: `cp -r vTerm vTerm-backup-$(date +%Y%m%d)`
2. Clone Haven: `gh repo clone GlassHaven/Haven ~/Haven -- --depth 1`
3. Clear the vTerm repo, keeping `.git`: `git rm -rf . && rm -rf android core docs`
4. Copy Haven across, excluding `.git`
5. Clone each submodule — `git submodule update` fails with a shallow parent:

```bash
for sub in termlib mosh-kotlin et-kotlin wayland-android reticulum-kt rnsh-kt spice-kotlin; do
    url=$(git config --file .gitmodules --get "submodule.$sub.url")
    git clone --depth 1 "$url" "$sub"
done
```

6. Create `local.properties`: `echo "sdk.dir=$HOME/android-sdk" > local.properties`
7. Add the aapt2 override to `gradle.properties`
8. Delete every `verification-metadata.xml`

## Termux build configuration

Files that normally need edits:

- `gradle/libs.versions.toml` — versions work as-is
- `termlib/lib/build.gradle.kts` — strip publish/metalava/dokka, restore `kotlin.android`
- `termlib/build.gradle.kts` — strip to the minimal plugin block with `apply false`
- `termlib/gradle/libs.versions.toml` — keep AGP at 8.9.1 to match root
- `gradle.properties` — add `aapt2FromMavenOverride` and `ndkVersion`
- `settings.gradle.kts` — drop the native `includeBuild` blocks
- module `build.gradle.kts` files — comment out the native-module dependencies

For which modules to keep versus drop, see
[haven-native-modules.md](haven-native-modules.md).

## Key pitfalls

- **termlib fork.** Haven points at the GlassOnTin fork, not connectbot upstream. The
  wrong fork means missing API classes such as `TerminalGestureCallback`.
- **AGP must match everywhere.** `includeBuild` modules must use the same AGP as the
  root, or the build fails with `Using multiple versions of the Android Gradle plugin`.
- **JVM target.** Java 17 `compileOptions` and the Kotlin `compilerOptions` must agree.
- **`kotlinOptions` is deprecated.** On Kotlin 2.3.x it is an error — use the
  `compilerOptions` DSL.
- **Configuration cache.** It can break plugins that reference script objects. Set
  `org.gradle.configuration-cache=false` if needed.
- **Submodules need shallow clones.** A shallow parent breaks `git submodule update`.
