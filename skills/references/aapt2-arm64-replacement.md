# AAPT2 ARM64 替换 — 故障排查记录

## 问题现象
Gradle 编译 Android 项目时报：
```
AAPT2 aapt2-8.7.3-12006047-linux Daemon #0: Daemon startup failed
```
或：
```
Exec format error
```

## 根因
1. Google SDK build-tools 的 `aapt2`, `aidl`, `zipalign` 等是 x86_64 ELF
2. AGP 8.x 从 Maven 拉取的 aapt2 也是 x86_64（如 `aapt2-8.7.3-12006047-linux`）
3. Termux 是 ARM64 (aarch64)，无法执行 x86_64 二进制

## 验证方法
```bash
readelf -h $ANDROID_HOME/build-tools/35.0.0/aapt2 | grep Machine
# 如果显示 "Advanced Micro Devices X86-64" 则需要替换
```

## 尝试过的方案

### ❌ Commit451/android-arm-build-tools (glibc 版)
- 下载成功，架构正确 (AArch64)
- 但依赖 `libc.so.6` (glibc)，Termux 用 Bionic libc
- 用 glibc 的 `ld-linux-aarch64.so.1` 加载也失败（libc.so 是链接脚本不是 ELF）
- **结论：纯 Termux 环境不可用**

### ✅ lzhiyong/android-sdk-tools (Bionic 版)
- 专为 Android/Termux 编译，使用 Bionic libc
- aapt2 version 直接能跑
- 需要同时替换 SDK 目录和 Gradle Maven 缓存中的版本

## 完整修复步骤

### 1. 下载 ARM64 版本
```bash
curl -fsSL "https://github.com/lzhiyong/android-sdk-tools/releases/download/35.0.2/android-sdk-tools-static-aarch64.zip" -o ~/lzhiyong-aarch64.zip
unzip ~/lzhiyong-aarch64.zip -d ~/lzhiyong-tools
```

### 2. 替换 SDK build-tools
```bash
for ver in $ANDROID_HOME/build-tools/*/; do
    for tool in aapt2 aidl zipalign split-select dexdump; do
        [ -f "$ver/$tool" ] && cp ~/lzhiyong-tools/build-tools/$tool "$ver/$tool" && chmod +x "$ver/$tool"
    done
done
```

### 3. 替换 platform-tools (adb)
```bash
cp ~/lzhiyong-tools/platform-tools/adb "$ANDROID_HOME/platform-tools/adb"
chmod +x "$ANDROID_HOME/platform-tools/adb"
```

### 4. 设置 gradle.properties 覆盖 Maven AAPT2
```properties
# 项目级 gradle.properties
android.aapt2FromMavenOverride=<ANDROID_HOME>/build-tools/<VERSION>/aapt2
```

### 5. 清理 Gradle 缓存
```bash
rm -rf ~/.gradle/caches/*/transforms/
rm -rf <project>/.gradle <project>/build
```

### 6. 验证
```bash
$ANDROID_HOME/build-tools/<VERSION>/aapt2 version
# 应输出: Android Asset Packaging Tool (aapt) 2.XX-...
```

## 参考链接
- lzhiyong: https://github.com/lzhiyong/android-sdk-tools
- Commit451 (glibc, 不适用于 Termux): https://github.com/Commit451/android-arm-build-tools
- Google Issue Tracker: https://issuetracker.google.com/issues/227219818
