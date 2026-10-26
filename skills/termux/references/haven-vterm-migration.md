# Haven → vTerm Migration: Case Study

A worked example of moving GlassHaven/Haven into an existing vTerm repository and
building it on Termux. Source: GlassHaven/Haven v5.62.0 (AGPL-3.0).

## Starting point

- 25 core modules, 12 feature modules, 8 git submodules
- Single `app` module — phone only, no TV or Wear targets
- Haven's `app/` is at the project root, not under `android/`
- `termlib` is an `includeBuild`, not a module dependency

## Failures encountered and their fixes

### Submodules not initialized
`Project with path ':lib' not found in build ':termlib'`
→ `git submodule update --init --recursive`, or clone each submodule URL by hand.
A shallow parent breaks `git submodule update`.

### Dependency verification blocking the build
`Dependency verification failed for configuration`
→ Remove the metadata:
`find . -name "verification-metadata.xml" -path "*/gradle/*" -exec rm -f {} \;`

### AGP version mismatch in includeBuild
`Using multiple versions of the Android Gradle plugin(9.2.0, 8.9.1) in the same build is not allowed`
→ Unify AGP across every `gradle/libs.versions.toml`, including `includeBuild` projects.

### maven.publish API mismatch
`No parameter with name 'validateDeployment' found` when downgrading the publish plugin
→ Drop the publish/metalava/dokka plugins from library builds entirely; they are not
needed to compile.

### Kotlin version mismatch across projects
`Unresolved reference 'compilerOptions'` inside an `includeBuild` context
→ termlib had Kotlin 2.3.20 while the root had 2.3.10. Unify:
`sed -i 's/kotlin = "2.3.20"/kotlin = "2.3.10"/' termlib/gradle/libs.versions.toml`

### kotlin.android under AGP 9.x
`The 'org.jetbrains.kotlin.android' plugin is no longer required since AGP 9.0`
→ Remove the plugin from every `build.gradle.kts`. Keep it if you stay on AGP 8.x.

### Hilt under AGP 9.x
`Could not find the Android Gradle Plugin (AGP) base extension`
→ Stay on AGP 8.x with Hilt 2.58, or upgrade Hilt.

## Final working configuration

- AGP 8.9.1, unified across all projects
- Kotlin 2.3.10, KSP 2.3.6, Hilt 2.58
- JDK 21 (needed by the rnsh-kt dependency)
- `aapt2FromMavenOverride` pointing at the ARM64 aapt2
- Dependency verification disabled
- NDK 29.0.14206865 from termux-ndk

## Device support

| Target | Status |
|--------|--------|
| Phone | Supported (Haven's only target) |
| Tablet | Works — `WindowSizeClass` adaptive layout |
| Android TV | Not implemented; needs a new `app-tv` module |
| Wear OS | Not implemented; needs a new `app-wear` module |
| HarmonyOS / iOS / Desktop | Separate repositories |

## Not in Haven (must be added for vTerm)

- Android TV module
- Wear OS module
- SSH key cloud sync (Google Drive / WebDAV)
