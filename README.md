# Hermes Termux Skills

> Termux/Android 环境下的 Hermes Agent Skills 集合

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Hermes](https://img.shields.io/badge/Hermes-v0.20.5-purple)](https://github.com/NousResearch/hermes-agent)

---

## Skills

### termux — Termux/Android 环境指南

完整的 Termux 环境配置指南，覆盖 Python、Hermes 操作、Android 开发。

**安装：**
```bash
cp -r skills/termux ~/.hermes/skills/
```

**包含文件：**

| 文件 | 内容 |
|------|------|
| `SKILL.md` | 快速参考 + 已知问题速查 |
| `references/pitfalls.md` | 完整陷阱指南（13 个类别） |
| `references/android-sdk-setup.md` | SDK 安装 + ARM64 二进制替换 |
| `references/ndk-setup.md` | NDK 安装 + CMake/Ninja 修复 |
| `references/agp-compatibility.md` | AGP/Kotlin/KSP 兼容性矩阵 |
| `references/hermes-termux.md` | Hermes 在 Termux 上的特殊配置 |
| `scripts/verify-arm64-sdk.sh` | 验证 SDK 原生二进制架构 |

---

## 已知问题速查

| 问题 | 状态 | 解决方案 |
|------|------|----------|
| Python 3.14 破坏 Hermes | — | `apt-mark hold python` |
| psutil 编译失败 | — | `--system-site-packages` |
| python -m venv 失败 | — | `uv venv` |
| TUI 文字消失 (Xiaomi Android 16) | CLOSED (未修复) | 切换 CLI 模式 |
| apt/pkg 在 Android 16 上损坏 | CLOSED (未修复) | Bionic stdio errno bug |
| pip 在 Python 3.13.12-2 上损坏 | CLOSED (无修复) | `uv pip` |
| nettle 破坏 apt | CLOSED | 避免更新 nettle |

---

## License

MIT