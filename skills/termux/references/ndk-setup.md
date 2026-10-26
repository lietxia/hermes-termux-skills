# NDK Setup on Termux

Google's official NDK only has x86_64 Linux binaries. On Termux (ARM64), use lzhiyong's termux-ndk.

## Installation

```bash
yes | pkg install p7zip
curl --http1.1 -L -o ~/termux-ndk-r29.7z "https://github.com/lzhiyong/termux-ndk/releases/download/android-ndk/android-ndk-r29-aarch64.7z"
7z x ~/termux-ndk-r29.7z -y -o~/termux-ndk
mv ~/termux-ndk/android-ndk-r29 ~/android-sdk/ndk/29.0.14206865
```

## Symlink Trick

If Gradle auto-downloads NDK 27 (x86_64), redirect it:

```bash
cd ~/android-sdk/ndk
rm -rf 27.0.12077973
ln -sf 29.0.14206865 27.0.12077973
```

## CMake/Ninja

SDK's cmake is x86_64. Use Termux native:

```bash
pkg install cmake ninja
rm -rf $ANDROID_HOME/cmake/3.22.1/bin/*
ln -sf /data/data/com.termux/files/usr/bin/cmake $ANDROID_HOME/cmake/3.22.1/bin/cmake
ln -sf /data/data/com.termux/files/usr/bin/ninja $ANDROID_HOME/cmake/3.22.1/bin/ninja
```

## Protobuf Fix

```bash
pkg install protobuf
# In build.gradle.kts:
# protobuf { protoc { path = "/data/data/com.termux/files/usr/bin/protoc" } }
```

**PITFALL**: Maven-downloaded protoc is x86_64 — won't run on Termux. Always use system protoc via `path`.

## Verification

```bash
# Check NDK
~/android-sdk/ndk/29.0.14206865/toolchains/llvm/prebuilt/linux-x86_64/bin/clang --version
# Should show: aarch64-unknown-linux-musl target
```

## Cross-Compiling for Non-Android Linux (armv7l)

When you need a static binary for a Linux ARM device (IoT, router, ONT), use the NDK's x86_64 clang with its sysroot. Termux's own clang lacks the armv7l runtime libraries.

```bash
# Cross-compile a static armv7l binary for Linux
NDK=~/android-sdk/ndk/29.0.14206865/toolchains/llvm/prebuilt/linux-x86_64
$NDK/bin/clang \
  --sysroot=$NDK/sysroot \
  --target=armv7a-linux-androideabi21 \
  -static -O2 \
  -o output_binary source.c
```

**PITFALL**: Termux clang (`/data/data/com.termux/files/usr/bin/clang`) does NOT work for cross-compiling — its bundled `libclang_rt.builtins.a` is aarch64-only. Always use the NDK's clang binary.

**PITFALL**: The Android bionic libc headers work for static Linux binaries because the ABI is compatible at the syscall level. No musl/glibc sysroot needed for simple exploits or tools.