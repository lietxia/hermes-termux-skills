# Haven 项目：恢复 Native 模块依赖（替代解耦方案）

当 vTerm/Haven 项目编译报 `sh.haven:*-transport:0.1.0` 找不到时，有两种方案：
1. **解耦方案**（haven-decouple-native.md）— 移除所有引用，改动量大且易出错
2. **恢复方案**（本文档）— 补全 includeBuild + 子模块，保留所有代码

**推荐用恢复方案**，因为解耦需要修改几十个文件，很容易遗漏。

## 恢复步骤

### 1. 确认子模块目录存在

Haven 的子模块（mosh-kotlin、rdp-kotlin、spice-kotlin、rclone-android）通常已在项目根目录，
只是 `settings.gradle.kts` 中没有注册。检查：

```bash
ls -d mosh-kotlin/ rdp-kotlin/ spice-kotlin/ rclone-android/
ls mosh-kotlin/build.gradle.kts rdp-kotlin/build.gradle.kts
```

如果目录为空，手动 clone：
```bash
git config --file .gitmodules --get-regexp "submodule\..*\.url" | while read key url; do
    path=$(echo "$key" | sed 's/submodule\.\(.*\)\.url/\1/')
    git clone --depth 1 "$url" "$path"
done
```

### 2. 在 settings.gradle.kts 中添加 includeBuild

参照 Haven 原始 settings.gradle.kts（GitHub: GlassHaven/Haven），添加：

```kotlin
// Mosh/SSP transport library (submodule).
includeBuild("mosh-kotlin") {
    dependencySubstitution {
        substitute(module("sh.haven:ssp-transport")).using(project(":"))
    }
}

// IronRDP + UniFFI Kotlin bindings (submodule).
includeBuild("rdp-kotlin") {
    dependencySubstitution {
        substitute(module("sh.haven:rdp-transport")).using(project(":"))
    }
}

// Pure-Rust SPICE client + UniFFI Kotlin bindings (submodule).
includeBuild("spice-kotlin") {
    dependencySubstitution {
        substitute(module("sh.haven:spice-transport")).using(project(":"))
    }
}

// Go bridge compiled via gomobile (submodule).
includeBuild("rclone-android") {
    dependencySubstitution {
        substitute(module("sh.haven:rclone-transport")).using(project(":"))
    }
}
```

### 3. 注册缺失的模块

```kotlin
// 在 settings.gradle.kts 的 include 块中添加
include(":core:mosh")
include(":core:rdp")
include(":core:rclone")
include(":core:mail")
include(":feature:rdp")
include(":feature:mail")
```

### 4. 恢复被注释的 build.gradle.kts 依赖

批量取消注释（注意有些文件有双重注释 `// //`）：
```bash
find feature/ core/ app/ -name "build.gradle.kts" -exec sed -i \
  -e 's|// implementation(project(":core:mosh")) // TODO:.*|implementation(project(":core:mosh"))|g' \
  -e 's|// implementation(project(":core:rclone")) // TODO:.*|implementation(project(":core:rclone"))|g' \
  -e 's|// implementation(project(":core:rdp")) // TODO:.*|implementation(project(":core:rdp"))|g' \
  -e 's|// implementation(project(":core:mail")) // TODO:.*|implementation(project(":core:mail"))|g' \
  -e 's|// // implementation(project(":core:mosh")) // TODO:.*|implementation(project(":core:mosh"))|g' \
  -e 's|// // implementation(project(":core:rdp")) // TODO:.*|implementation(project(":core:rdp"))|g' \
  -e 's|// // implementation(project(":core:rclone")) // TODO:.*|implementation(project(":core:rclone"))|g' \
  -e 's|// // implementation(project(":core:spice")) // TODO:.*|implementation(project(":core:spice"))|g' \
  -e 's|// // implementation(project(":feature:rdp")) // TODO:.*|implementation(project(":feature:rdp"))|g' \
  -e 's|// implementation(project(":feature:mail")) // TODO:.*|implementation(project(":feature:mail"))|g' \
  -e 's|// implementation("sh.haven:rclone-transport:0.1.0") // TODO|implementation("sh.haven:rclone-transport:0.1.0")|g' \
  {} \;
```

**⚠️ `app/build.gradle.kts` 也有被注释的依赖**，别忘了处理。验证：
```bash
grep -rn '// implementation.*TODO\|// api.*TODO\|// // impl' --include="build.gradle.kts" feature/ core/ app/
```

### 5. 修复 protoc（mosh-kotlin 需要 protobuf）

mosh-kotlin 使用 `com.google.protobuf:protoc` 下载的 x86_64 二进制在 Termux 上无法运行。

**解决方案**：安装 Termux 原生 protoc，修改 mosh-kotlin 的 build.gradle.kts：

```bash
pkg install protobuf
```

修改 `mosh-kotlin/build.gradle.kts`：
```kotlin
protobuf {
    protoc {
        // 改 artifact 为 path
        path = "/data/data/com.termux/files/usr/bin/protoc"
    }
}
```

**⚠️ 版本对齐关键（踩过的坑）**：系统 protoc 版本必须与 protobuf-java 版本匹配！
系统 protoc v33.1 生成的代码包含 `@com.google.protobuf.Generated` 注解，该注解只存在于 protobuf-java 4.33.x。
如果 protobuf-javalite/protobuf-java 版本低于 protoc 对应版本，编译报错：
```
error: cannot find symbol @com.google.protobuf.Generated
```

**版本对应关系**：protoc 33.x → protobuf-java 4.33.x, protoc 29.x → protobuf-java 4.29.x

**修复**：同时升级 `protobuf-javalite` 和添加 `compileOnly("protobuf-java")`：
```kotlin
dependencies {
    implementation("com.google.protobuf:protobuf-javalite:4.33.1")  // 与 protoc 版本匹配
    compileOnly("com.google.protobuf:protobuf-java:4.33.1")  // 提供 @Generated 注解
}
```

查看系统 protoc 版本：`protoc --version`（输出 `libprotoc XX.Y`，对应 protobuf-java `4.XX.Y`）

### 5.1 检查被 stub 替换的源文件

用户在之前的尝试中可能将无法编译的文件替换为空壳（stub）。这会导致下游模块报类型不匹配错误：
```
Argument type mismatch: actual type is 'RcloneFileBackend', but 'FileBackend' was expected.
Too many arguments for 'constructor(): RcloneFileBackend'.
```

**检查方法**：
```bash
# 查找包含 "Stub" 或 "Deleted" 注释的源文件
grep -rn "Stub\|Deleted.*removed\|module removed" --include="*.kt" feature/ core/ app/
```

**修复**：用 git checkout 恢复原始文件：
```bash
git checkout HEAD -- path/to/StubbedFile.kt
```

### 6. 禁用需要 gomobile/Rust 的 native 构建任务

rclone-android 的 `buildRcloneNative`（Go gomobile）和 rdp-kotlin/spice-kotlin 的 Rust 构建任务
在 Termux 上无法运行。需要在对应的 build.gradle.kts 中禁用：

```kotlin
val buildRcloneNative by tasks.registering(Exec::class) {
    enabled = false // Disabled for Termux build
}
```

如果这些 native 任务不产生编译错误（被 Gradle 跳过），则不需要处理。

## 对比解耦方案

| | 恢复方案 | 解耦方案 |
|--|---------|---------|
| 改动量 | ~5 个配置文件 | 20+ 个 Kotlin 源文件 |
| 风险 | 低（配置级改动） | 高（遗漏引用导致 KSP 报错） |
| 保留功能 | 完整 | 移除 mosh/rdp/rclone/mail |
| 适用场景 | 子模块源码可用 | 子模块源码缺失 |

## 常见错误

| 错误 | 原因 | 修复 |
|------|------|------|
| `Could not find sh.haven:xxx-transport:0.1.0` | includeBuild 缺失 | 添加 includeBuild + dependencySubstitution |
| `Project with path ':core:xxx' could not be found` | settings.gradle.kts 缺少 include | 添加 include(":core:xxx") |
| `KSP PROCESSING_ERROR: could not be resolved` | build.gradle.kts 依赖被注释 | 取消注释 implementation(project(":core:xxx")) |
| `protoc: stdout: . stderr:` | protoc x86_64 二进制无法执行 | `pkg install protobuf` + build.gradle.kts 用 `path` 替代 `artifact` |
| `cannot find symbol @Generated` | 系统 protoc 版本与 protobuf-java 不匹配 | 升级 protobuf-javalite 到与 protoc 对应的版本（如 protoc 33.x → 4.33.x）|
| `Too many arguments for constructor` | 源文件被替换为 stub | `git checkout HEAD -- path/to/file.kt` 恢复原始文件 |
