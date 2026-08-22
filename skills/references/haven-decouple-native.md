# Haven 项目解耦 Native 模块（Termux 编译）

当 Haven 的 core:ssh 等模块深度耦合了 mosh/rdp/rclone/mail 等需要 native 编译的模块时，
需要修改 Kotlin 源码来解耦，不只是注释 gradle 依赖。

## 需要修改的文件

### 1. core/ssh/src/.../SessionManagerRegistry.kt
移除 MoshSessionManager、RdpSessionManager、MailSessionManager 的：
- import 语句
- 构造函数参数
- disconnectProfile() 中的方法调用
- hasActiveSessions() 中的引用
- allSessions 中的 map 调用
- 底部的 toSession() 扩展函数

### 2. core/ssh/src/.../ForegroundSessionParticipantModule.kt
移除 mosh()、rdp() 等 @Provides 函数，以及对应的 import。

### 3. 其他可能需要修改的文件
搜索所有引用：
```bash
grep -rn "MoshSessionManager\|RdpSessionManager\|MailSessionManager\|RcloneClient\|RcloneSessionManager" --include="*.kt" core/ feature/ app/
```

## 禁用 Native 构建任务

在 build.gradle.kts 中，找到所有 Exec 类型的 native 构建任务并禁用：

```kotlin
val buildXxx by tasks.registering(Exec::class) {
    enabled = false // Disabled for Termux build
    // ... 原有代码
}
```

已知需要禁用的任务：
- `core:local:buildProot` — proot 编译
- `core:local:buildWayvncShim` — wayvnc shim 编译
- `core:local:buildHavenUsb` — USB 转发编译
- `rdp-kotlin:buildRdpNative` — Rust cargo-ndk
- `spice-kotlin:buildSpiceNative` — Rust cargo-ndk
- `rclone-android:buildRcloneNative` — Go gomobile

## settings.gradle.kts 处理

注释掉整个 includeBuild 块（包括 dependencySubstitution）：
```kotlin
// includeBuild("mosh-kotlin") { ... }
// includeBuild("rdp-kotlin") { ... }
// includeBuild("spice-kotlin") { ... }
// includeBuild("rclone-android") { ... }
```

## build.gradle.kts 依赖处理

批量注释所有对被移除模块的依赖：
```bash
find . -name "build.gradle.kts" -exec grep -l "core:mosh\|core:rdp\|core:spice\|core:rclone\|core:mail\|feature:mail\|feature:rdp" {} \; | while read f; do
    sed -i 's|implementation(project(":core:mosh"))|// & // TODO|' "$f"
    # ... 同理处理其他
done
```
