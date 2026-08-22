# NDK on Termux — ARM64 Build Solutions

## Problem
Google's Android NDK only provides x86_64 Linux host binaries. The clang compiler, linker, and other tools cannot run on Termux (ARM64 + Bionic libc).

## Solutions Tested

### ✅ lzhiyong/termux-ndk (RECOMMENDED)
- **Repo**: https://github.com/lzhiyong/termux-ndk (802 stars)
- **Method**: Rebuilds only the LLVM toolchain from AOSP source, links with musl libc (static)
- **Version**: r29 (Jan 2026)
- **Format**: 7z archive (~333MB compressed, ~1.8GB extracted)
- **Target**: `aarch64-unknown-linux-musl`

```bash
# Install p7zip
yes | pkg install p7zip

# Download (use --http1.1 to avoid HTTP/2 errors)
curl --http1.1 -L -o ~/termux-ndk-r29.7z \
  "https://github.com/lzhiyong/termux-ndk/releases/download/android-ndk/android-ndk-r29-aarch64.7z"

# Verify integrity
7z t ~/termux-ndk-r29.7z

# Extract
mkdir -p ~/termux-ndk && 7z x ~/termux-ndk-r29.7z -y -o~/termux-ndk

# Install to SDK
mv ~/termux-ndk/android-ndk-r29 ~/android-sdk/ndk/29.0.14206865

# Verify
~/android-sdk/ndk/29.0.14206865/toolchains/llvm/prebuilt/linux-x86_64/bin/clang --version
# Output: Target: aarch64-unknown-linux-musl
```

### ❌ SnowNF/ndk-aarch64-linux
- ARM64 ELF but depends on glibc loader (`/lib/ld-linux-aarch64.so.1`)
- Termux uses Bionic libc, so `required file not found` error
- Cannot be fixed with symlink to glibc loader (libc.so is a linker script, not ELF)

### ❌ Commit451/android-arm-build-tools
- Only provides aapt2/aidl/zipalign (not full NDK)
- Compiled with glibc, same issue as SnowNF

### ❌ Google official NDK (any version)
- All versions provide x86_64 only
- No ARM64 Linux host support planned (as of Jun 2026)

## NDK Symlink Trick
AGP auto-downloads NDK 27 (x86_64) regardless of settings. Create symlink:
```bash
cd ~/android-sdk/ndk
rm -rf 27.0.12077973
ln -sf 29.0.14206865 27.0.12077973
```
AGP will think it's using NDK 27 but actually use termux-ndk's ARM64 clang.

## CMake/Ninja
SDK's cmake/ninja are x86_64. Use Termux native:
```bash
yes | pkg install cmake ninja
# Symlink for Gradle
ln -sf /data/data/com.termux/files/usr/bin/cmake ~/android-sdk/cmake/3.22.1/bin/cmake
ln -sf /data/data/com.termux/files/usr/bin/ninja ~/android-sdk/cmake/3.22.1/bin/ninja
```

## Download Tips
- Use `curl --http1.1` for GitHub large files (HTTP/2 protocol errors on Termux)
- 7z files: p7zip 17.05 works if download is complete; verify with `7z t`
- `/tmp` is not writable on Termux; download to `$HOME`
