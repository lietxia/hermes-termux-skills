# Haven→vTerm Migration: Real-World Case Study

## Problem
Migrating GlassHaven/Haven (793★, Kotlin+Compose, SSH/SFTP terminal) into an existing vTerm repository, then building on Termux.

## What Went Wrong (and Fixes)

### 1. Git submodules not initialized
**Error:** `Project with path ':lib' not found in build ':termlib'`
**Fix:** `git submodule update --init --recursive` or manual clone of each submodule URL.

### 2. Dependency verification blocking builds
**Error:** `Dependency verification failed for configuration`
**Fix:** `find . -name "verification-metadata.xml" -path "*/gradle/*" -exec rm -f {} \;`

### 3. AGP version mismatch in includeBuild
**Error:** `Using multiple versions of the Android Gradle plugin(9.2.0, 8.9.1) in the same build is not allowed`
**Fix:** Unify AGP version in ALL `gradle/libs.versions.toml` files, including `includeBuild` projects.

### 4. maven.publish plugin API mismatch
**Error:** `No parameter with name 'validateDeployment' found` when downgrading publish plugin
**Fix:** Remove publish/metalava/dokka plugins entirely from lib builds (not needed for compilation).

### 5. Kotlin version mismatch across projects
**Error:** `Unresolved reference 'compilerOptions'` in includeBuild context
**Root cause:** termlib had Kotlin 2.3.20, main project had 2.3.10
**Fix:** Unify Kotlin version: `sed -i 's/kotlin = "2.3.20"/kotlin = "2.3.10"/' termlib/gradle/libs.versions.toml`

### 6. kotlin.android plugin in AGP 9.x
**Error:** `The 'org.jetbrains.kotlin.android' plugin is no longer required since AGP 9.0`
**Fix:** `find . -name "build.gradle.kts" -exec sed -i '/kotlin.android/d' {} \;`
**But:** If staying on AGP 8.x, keep the plugin.

### 7. Hilt incompatible with AGP 9.x
**Error:** `Could not find the Android Gradle Plugin (AGP) base extension`
**Fix:** Stay on AGP 8.x when using Hilt 2.58, or upgrade Hilt.

## Final Working Configuration
- AGP: 8.9.1 (unified across all projects)
- Kotlin: 2.3.10
- KSP: 2.3.6
- Hilt: 2.58
- JDK: 21 (for rnsh-kt dependency)
- aapt2FromMavenOverride: ARM64 version
- Dependency verification: disabled
