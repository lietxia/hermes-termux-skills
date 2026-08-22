# 绝对禁止：proot

用户明确且反复要求：**绝对不要提议使用 proot、proot-distro、或任何 chroot/容器方案。**

这是硬性要求，不是偏好。

## 遇到 x86-only 工具怎么办

当遇到需要 x86 环境才能运行的工具（如 NDK clang、CMake 等），必须：

1. 搜索该工具的 ARM64 原生替代版本
2. 检查 GitHub 社区是否有 ARM64 移植
3. 尝试用 Termux 原生工具替代
4. 如果确实无法解决，直接告诉用户"这个工具没有 ARM64 版本，无法在 Termux 上运行"

**已知 ARM64 替代方案：**
- NDK: [SnowNF/ndk-aarch64-linux](https://github.com/SnowNF/ndk-aarch64-linux) 提供 ARM64 预编译 NDK
- Build tools: [lzhiyong/android-sdk-tools](https://github.com/lzhiyong/android-sdk-tools) 提供 ARM64 aapt2/adb 等
- CMake/Ninja: `pkg install cmake ninja` 直接安装 ARM64 版本
