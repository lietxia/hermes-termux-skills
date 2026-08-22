# Haven as Base Project for vTerm

## Why Haven
GlassHaven/Haven (⭐793, AGPL-3.0) is the best open-source match for building an SSH terminal app:
- Kotlin + Jetpack Compose + Material 3
- SSH/Mosh/SFTP/Port forwarding (complete)
- Terminal emulator with VT parsing
- SFTP dual-pane file manager
- SSH Key management with Keystore encryption
- FIDO2 security key support
- VNC/RDP/Wayland desktop support
- rclone cloud storage (60+ providers)
- Active development (v5.62.0, daily commits)
- 25 core modules + 12 feature modules

## Project Structure
```
Haven/
├── app/                    # Main Android app (single module, no android/ subdir)
├── core/                   # 25 core modules (ssh, terminal-haven, security, mosh, etc.)
├── feature/                # 12 feature modules (terminal, sftp, connections, keys, etc.)
├── termlib/                # Terminal library (includeBuild, has its own AGP version)
├── mosh-kotlin/            # Mosh protocol (submodule)
├── et-kotlin/              # Eternal Terminal (submodule)
├── rclone-android/         # rclone integration
├── rdp-kotlin/             # RDP client
├── wayland-android/        # Wayland compositor
├── build.gradle.kts        # Root build file
├── settings.gradle.kts     # Module includes
└── gradle/libs.versions.toml  # Version catalog
```

## Key Differences from vTerm's Original Structure
- Haven's `app/` is at project root, not under `android/`
- Uses `includeBuild` for termlib (not regular module dependency)
- 8 git submodules (termlib, mosh-kotlin, et-kotlin, etc.)
- Gradle 9.4.1 (vs vTerm's 8.14)

## Migration Steps
1. Backup original vTerm: `cp -r vTerm vTerm-backup-$(date +%Y%m%d)`
2. Clone Haven: `gh repo clone GlassHaven/Haven ~/Haven -- --depth 1`
3. Clear vTerm repo (keep .git): `git rm -rf . && rm -rf android core docs`
4. Copy Haven contents: `cp -r ~/Haven/* ~/vTerm/` (excluding .git)
5. Initialize submodules manually (shallow clone issue):
   ```bash
   cd ~/vTerm
   for sub in termlib mosh-kotlin et-kotlin wayland-android reticulum-kt rnsh-kt spice-kotlin; do
       url=$(git config --file .gitmodules --get "submodule.$sub.url")
       git clone --depth 1 "$url" "$sub"
   done
   ```
6. Create local.properties: `echo "sdk.dir=$HOME/android-sdk" > local.properties`
7. Add aapt2 override to gradle.properties
8. Delete all verification-metadata.xml files

## Version Requirements
- AGP: 8.9.1 (DO NOT upgrade to 9.x — Hilt incompatibility)
- Kotlin: 2.3.10
- KSP: 2.3.6
- Gradle: 9.4.1
- JDK: 21 (for rnsh-kt)
- compileSdk: 36

## Modules to Keep vs Remove for vTerm
**Keep (core SSH/Terminal/SFTP):**
- core: ssh, terminal-haven, security, data, ui, toolbar, tunnel, mosh, et, fido
- feature: terminal, sftp, connections, keys, settings, editor

**May Remove Later (not SSH-related):**
- core: vnc, rdp, spice, wayland, rclone, mail, smb, usb, local, scan, spa, knock, stepca, reticulum, rnsh, ffmpeg
- feature: vnc, rdp, mail, imagetools

**Not in Haven (need to add):**
- Android TV module (app-tv)
- Wear OS module (app-wear)
- SSH Key cloud sync (Google Drive / WebDAV)
