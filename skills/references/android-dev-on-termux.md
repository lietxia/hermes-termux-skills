# Android 开发环境搭建 (Termux ARM64)

## 核心问题：x86_64 二进制不兼容

Google 官方 Android SDK/NDK 工具链只提供 `linux-x86_64` 主机版本。在 Termux (ARM64) 上运行会报 `Exec format error`。

## SDK Build Tools (aapt2/aidl/zipalign)

### 解决方案：lzhiyong/android-sdk-tools

```bash
# 下载 ARM64 版本
curl -fsSL "https://github.com/lzhiyong/android-sdk-tools/releases/download/35.0.2/android-sdk-tools-static-aarch64.zip" -o ~/lzhiyong-aarch64.zip
unzip -o ~/lzhiyong-aarch64.zip -d ~/lzhiyong-tools

# 替换到 SDK 目录
BUILD_TOOLS="$HOME/android-sdk/build-tools/35.0.0"  # 或 35.0.1, 36.0.0
cp ~/lzhiyong-tools/build-tools/aapt2 "$BUILD_TOOLS/aapt2"
cp ~/lzhiyong-tools/build-tools/aidl "$BUILD_TOOLS/aidl"
cp ~/lzhiyong-tools/build-tools/zipalign "$BUILD_TOOLS/zipalign"
cp ~/lzhiyong-tools/build-tools/split-select "$BUILD_TOOLS/split-select"
cp ~/lzhiyong-tools/build-tools/dexdump "$BUILD_TOOLS/dexdump"
chmod +x "$BUILD_TOOLS"/{aapt2,aidl,zipalign,split-select,dexdump}

# 同样替换 platform-tools 的 adb
cp ~/lzhiyong-tools/platform-tools/adb "$HOME/android-sdk/platform-tools/adb"
chmod +x "$HOME/android-sdk/platform-tools/adb"
```

### AGP 8.x: 需要设置 aapt2FromMavenOverride

AGP 8.x 会从 Maven 下载自己的 x86_64 aapt2。必须覆盖：

```properties
# gradle.properties
android.aapt2FromMavenOverride=/path/to/android-sdk/build-tools/36.0.0/aapt2
```

### AGP 9.x: 同样需要

```properties
android.aapt2FromMavenOverride=/path/to/android-sdk/build-tools/36.0.0/aapt2
```

## NDK (C/C++ 编译)

### 问题
NDK 内置的 clang 是 x86_64 二进制，无法在 ARM64 上执行。Google 不提供 ARM64 主机版 NDK。

### 解决方案：SnowNF/ndk-aarch64-linux

```bash
# 下载 ARM64 版 NDK r29
curl -fsSL "https://github.com/SnowNF/ndk-aarch64-linux/releases/download/0.0.2/android-ndk-r29-linux-aarch64.tar.gz" -o ~/ndk-r29-aarch64.tar.gz
tar xzf ~/ndk-r29-aarch64.tar.gz -C ~/android-sdk/ndk/
```

注意：这是社区编译版本，可能存在兼容性问题。

## CMake

SDK 自带的 cmake 也是 x86_64。用 Termux 原生 cmake 替代：

```bash
pkg install cmake ninja
# 创建符号链接让 Gradle 找到
ln -sf /data/data/com.termux/files/usr/bin/cmake ~/android-sdk/cmake/3.22.1/bin/cmake
ln -sf /data/data/com.termux/files/usr/bin/ninja ~/android-sdk/cmake/3.22.1/bin/ninja
```

## Gradle 版本兼容性矩阵

### AGP 9.0+ 的 Breaking Changes

| 变化 | 影响 |
|------|------|
| 内置 Kotlin 支持 | 必须移除 `kotlin.android` 插件（从所有 build.gradle.kts） |
| `compilerOptions` DSL | 在 `includeBuild` 上下文可能不解析 |
| `kotlinOptions` deprecated | 改用 `kotlin { jvmToolchain(N) }` |

### AGP 8.x + Hilt 兼容性

| Hilt 版本 | AGP 8.x | AGP 9.x |
|-----------|---------|---------|
| 2.58 | ✅ | ❌ 找不到 AGP base extension |
| 2.56+ | ✅ | 需要测试 |

### maven.publish 插件

| 版本 | AGP 要求 |
|------|---------|
| 0.36.0 | AGP 8.13.0+ |
| 0.30.0 | AGP 8.x |

### KSP 版本

KSP 版本格式：与 Kotlin minor version 绑定。
- Kotlin 2.3.10 → KSP 可能还没有对应版本
- 检查方法：`curl -sI "https://repo1.maven.org/maven2/com/google/devtools/ksp/symbol-processing-gradle-plugin/<version>/..."`

### includeBuild 的版本冲突

当主项目用 AGP 8.9.1，而 `includeBuild` 的子项目用 AGP 9.2.0 时：
```
Using multiple versions of the Android Gradle plugin(9.2.0, 8.9.1) in the same build is not allowed.
```

**必须统一 AGP 版本。** 包括 `includeBuild` 子项目的 `gradle/libs.versions.toml`。

## 依赖验证 (Dependency Verification)

Gradle 的依赖验证在 Termux 上经常因为网络/签名问题失败：

```properties
# gradle.properties — 禁用验证
org.gradle.dependency.verification=off
```

同时删除所有 `verification-metadata.xml`：
```bash
find . -name "verification-metadata.xml" -path "*/gradle/*" -exec rm -f {} \;
```

## 推荐 JDK 版本

| 场景 | JDK |
|------|-----|
| AGP 8.x + Kotlin 2.3.x | JDK 17 或 21 |
| AGP 9.x + 需要 JDK 21 的模块 | JDK 21 |

```bash
pkg install openjdk-17 openjdk-21
export JAVA_HOME=/data/data/com.termux/files/usr/lib/jvm/java-21-openjdk
```

## 快速验证清单

```bash
# 1. Java
java -version

# 2. aapt2 (ARM64)
~/android-sdk/build-tools/36.0.0/aapt2 version

# 3. adb (ARM64)
~/android-sdk/platform-tools/adb version

# 4. cmake (ARM64)
cmake --version

# 5. Gradle
cd ~/project && ./gradlew assembleDebug --dry-run
```
