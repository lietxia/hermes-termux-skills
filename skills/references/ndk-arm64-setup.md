# NDK ARM64 Setup for Termux

## lzhiyong/termux-ndk

Pre-built ARM64 NDK with musl-static clang (~333MB, 7z format).

```bash
pkg install p7zip
curl --http1.1 -fsSL "https://github.com/lzhiyong/termux-ndk/releases/download/android-ndk/android-ndk-r29-aarch64.7z" -o ~/termux-ndk-r29.7z
mkdir -p ~/termux-ndk && 7z x ~/termux-ndk-r29.7z -y -o~/termux-ndk
mv ~/termux-ndk/android-ndk-r29 $ANDROID_HOME/ndk/29.0.14206865
```

Verify: `$ANDROID_HOME/ndk/29.0.14206865/toolchains/llvm/prebuilt/linux-x86_64/bin/clang --version`
Should show: `Target: aarch64-unknown-linux-musl`

## Handling AGP NDK Auto-Download

AGP auto-downloads x86_64 NDK. Use symlinks:

```bash
rm -rf $ANDROID_HOME/ndk/27.0.12077973
ln -sf 29.0.14206865 $ANDROID_HOME/ndk/27.0.12077973
```

gradle.properties:
```properties
android.ndkVersion=29.0.14206865
```

## CMake/Ninja

Termux's cmake and ninja are ARM64 native: `pkg install cmake ninja`

## Rust/Go/Protobuf Modules

| Tool | Install | Modules |
|------|---------|---------|
| Rust + cargo-ndk | `pkg install rust` + `cargo install cargo-ndk` | rdp-kotlin, spice-kotlin |
| Go + gomobile | `pkg install golang` + `go install golang.org/x/mobile/cmd/gomobile@latest` | rclone-android |
| Protobuf | `pkg install protobuf` | mosh-kotlin |

If not needed: Comment out BOTH `includeBuild("module")` in settings.gradle.kts AND `implementation(project(":core:module"))` in app/build.gradle.kts.

## Pitfalls

| Error | Cause | Fix |
|-------|-------|-----|
| `CMAKE_C_COMPILER not found` | NDK clang is x86_64 | Use lzhiyong/termux-ndk |
| `no such command: ndk` | cargo-ndk missing | Install or disable module |
| `gomobile: command not found` | Go mobile tools missing | Install or disable module |
| `generateProto FAILED` | protoc missing | `pkg install protobuf` or disable |
| `ld-linux-aarch64.so.1: not found` | glibc loader missing | Use musl-based termux-ndk |
| `7z: Can't open as archive` | Incomplete download | Re-download with --http1.1 |
