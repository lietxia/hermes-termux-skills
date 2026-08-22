# Hermes Termux Skills

> 完整的 Termux/Android 环境避坑指南，基于 Hermes Agent 实战经验。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Hermes](https://img.shields.io/badge/Hermes-v0.20.5-purple)](https://github.com/NousResearch/hermes-agent)
[![Platform](https://img.shields.io/badge/platform-Android%20%2F%20Termux-green)](https://termux.dev/)

本仓库包含 Hermes Agent 在 Android/Termux 环境下运行时的所有已知问题、解决方案和最佳实践。

---

## Why This Exists

在 Termux 上运行 Hermes Agent 是一项艰巨的任务。Android 的 Bionic libc、ARM64 架构限制、系统级 seccomp 过滤器和各种不兼容的二进制文件构成了一个雷区。本仓库记录了我们在 2025-2026 年间踩过的每一个坑，以及经过验证的解决方案。

**不要重复踩坑。这个指南就是你的探雷器。**

---

## Features

- **完整覆盖** — Python 环境、Hermes 操作、Android 开发、安全研究
- **实战验证** — 所有解决方案都在 Xiaomi Android 16 (11GB RAM) 上测试通过
- **详细参考** — 31 个 reference 文档，覆盖所有细分场景
- **实用脚本** — 包含验证 SDK 原生二进制架构的脚本
- **持续更新** — 随 Hermes 和 Termux 版本更新

---

## Quick Start

### 5 分钟从零开始

```bash
# 1. 锁定 Python 版本（Hermes 需要 <3.14）
apt-mark hold python && apt-mark hold python-ensurepip-wheels

# 2. 安装 uv（比 pip 快 10-100 倍）
pkg install uv

# 3. 创建 venv（继承系统 psutil/cryptography）
uv venv venv --python /data/data/com.termux/files/usr/bin/python3.13 --system-site-packages --seed

# 4. 激活 venv
source venv/bin/activate

# 5. 安装 Hermes
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# 6. 启动 Gateway
hermes gateway run
```

### 验证安装

```bash
hermes doctor
# 应该显示: ✅ Python 3.13.13, ✅ Hermes v0.20.5, ✅ 18 tools available
```

---

## Documentation

### 核心文档

| 文件 | 内容 |
|------|------|
| [SKILL.md](skills/SKILL.md) | 快速参考 + 已知问题速查表 |
| [references/pitfalls.md](skills/references/pitfalls.md) | 完整陷阱指南（13 个类别） |
| [references/hermes-termux.md](skills/references/hermes-termux.md) | Hermes 在 Termux 上的特殊配置 |

### Android 开发

| 文件 | 内容 |
|------|------|
| [references/android-sdk-setup.md](skills/references/android-sdk-setup.md) | SDK 安装 + ARM64 二进制替换 |
| [references/ndk-setup.md](skills/references/ndk-setup.md) | NDK 安装 + CMake/Ninja 修复 |
| [references/agp-compatibility.md](skills/references/agp-compatibility.md) | AGP/Kotlin/KSP 兼容性矩阵 |
| [references/haven-termux-build.md](skills/references/haven-termux-build.md) | vTerm 项目构建指南 |

### 脚本

| 文件 | 功能 |
|------|------|
| [scripts/verify-arm64-sdk.sh](skills/scripts/verify-arm64-sdk.sh) | 验证 SDK 原生二进制是否为 ARM64 |

---

## Known Issues

### 🔴 未修复（等待上游）

| 问题 | GitHub Issue | 影响 |
|------|-------------|------|
| apt/pkg 在 Android 16 上损坏 | [termux/termux-app#5077](https://github.com/termux/termux-app/issues/5077) | 无法安装新包 |
| TUI 文字消失 (Xiaomi) | [NousResearch/hermes-agent#18390](https://github.com/NousResearch/hermes-agent/issues/18390) | TUI 模式不可用 |
| pip 在 Python 3.13.12-2 上损坏 | [termux/termux-packages#28824](https://github.com/termux/termux-packages/issues/28824) | pip 无法使用 |

### 🟢 已解决（本仓库覆盖）

| 问题 | 解决方案 |
|------|----------|
| Python 3.14 破坏 Hermes | `apt-mark hold python` + `uv venv --python python3.13` |
| psutil 编译失败 | `--system-site-packages` |
| python -m venv 失败 | `uv venv` |
| cryptography 导入错误 | `--system-site-packages` |
| Hermes 无法自重启 | 从外部 shell 执行 `hermes gateway restart` |

---

## Critical Differences (Termux vs Standard Linux)

| 标准 Linux | Termux/Android | 影响 |
|------------|----------------|------|
| `apt install` | `pkg install` | 命令不同 |
| `/tmp` 可写 | `/tmp` 不可写 | 必须使用 `$HOME` |
| `systemd` | 无 init 系统 | 使用 `tmux` |
| `python3 -m venv` | 可能失败 | 使用 `uv venv` |
| `which` | 可能不存在 | 使用 `command -v` |
| x86_64 二进制 | 仅 ARM64 | 必须替换原生二进制 |
| glibc | Bionic libc | 许多 glibc 二进制无法运行 |
| 无 seccomp | seccomp 过滤器 | 某些 syscall 被阻止 |

---

## Related Projects

- [Hermes Agent](https://github.com/NousResearch/hermes-agent) — 官方仓库
- [termux-app](https://github.com/termux/termux-app) — Termux 应用
- [termux-packages](https://github.com/termux/termux-packages) — Termux 包仓库
- [android-sdk-tools](https://github.com/lzhiyong/android-sdk-tools) — lzhiyong 的 ARM64 构建
- [termux-ndk](https://github.com/lzhiyong/termux-ndk) — lzhiyong 的 ARM64 NDK

---

## Contributing

欢迎贡献！请遵循以下步骤：

1. Fork 本仓库
2. 创建分支 (`git checkout -b fix/new-pitfall`)
3. 提交更改 (`git commit -m "Add fix for X"`)
4. 推送到分支 (`git push origin fix/new-pitfall`)
5. 打开 Pull Request

### 贡献指南

- 所有修复必须经过实际测试
- 请在 commit 消息中包含复现步骤
- 如果是已知 issue，请引用 GitHub issue 编号
- 保持 Markdown 格式一致

---

## License

MIT License — 详见 [LICENSE](LICENSE) 文件。

---

## Acknowledgments

- [Nous Research](https://nousresearch.com/) — 创建 Hermes Agent
- [Termux 社区](https://termux.dev/) — 维护 Android 上的 Linux 环境
- [lzhiyong](https://github.com/lzhiyong) — 提供 ARM64 构建工具

---

## Disclaimer

本仓库与 Nous Research 或 Termux 官方无关。所有信息基于个人实战经验，仅供参考。请在生产环境使用前自行验证。