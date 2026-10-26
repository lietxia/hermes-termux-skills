# NDK Setup on Termux (ARM64)

Google does not publish an ARM64-host NDK. The clang inside the official NDK archive
is an x86_64 ELF, so it cannot run on aarch64 Termux. Use a community NDK built for
Android/Bionic.

## Use lzhiyong/termux-ndk

[lzhiyong/termux-ndk](https://github.com/lzhiyong/termux-ndk) ships a musl-static
aarch64 clang that runs on Termux. This is the recommended source.

```bash
# Fetch the release for the NDK version your project pins, e.g. r29.
# Extract under $ANDROID_HOME/ndk/<version>/ so AGP finds it by name.
ls -d "$ANDROID_HOME"/ndk/*/
```

Do **not** use `SnowNF/ndk-aarch64-linux`: it is built against glibc (its release
notes say "aarch64 gnu/linux") and needs `/lib/ld-linux-aarch64.so.1`, which Bionic
does not provide. The same applies to `Commit451/android-arm-build-tools`.

## Redirect AGP's auto-download with a symlink

AGP asks for a specific NDK version. If the exact version is missing, symlink the one
you have to the name AGP expects:

```bash
cd "$ANDROID_HOME/ndk"
ln -sfn 29.0.14206865 27.0.12077973
```

Then confirm the toolchain resolves:

```bash
"$ANDROID_HOME/ndk/27.0.12077973/toolchains/llvm/prebuilt/linux-x86_64/bin/clang" --version
```

The `linux-x86_64` directory name is upstream's and is misleading — the binary inside
is aarch64. Check with `readelf -h` if unsure.

## CMake and Ninja

```bash
pkg install cmake ninja
ln -sf "$PREFIX/bin/cmake" "$ANDROID_HOME/cmake/3.22.1/bin/cmake"
ln -sf "$PREFIX/bin/ninja" "$ANDROID_HOME/cmake/3.22.1/bin/ninja"
```

## gradle.properties

```properties
android.ndkVersion=29.0.14206865
```

## Verify

```bash
readelf -h "$ANDROID_HOME/ndk/29.0.14206865/toolchains/llvm/prebuilt/linux-x86_64/bin/clang" | grep Machine
# AArch64 — good.
```

## When you do not need the NDK

If the project has no C/C++ or Rust code, leave the NDK alone. Several large Android
projects can be built with the native modules disabled — see
[native-build-tasks.md](native-build-tasks.md) and
[haven-native-modules.md](haven-native-modules.md).
