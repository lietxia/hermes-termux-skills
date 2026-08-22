# Hermes Agent on Termux/Android

> 完整的 Termux/Android 环境避坑指南，基于 Hermes Agent 实战经验。

本仓库包含 Hermes Agent 在 Android/Termux 环境下运行时的所有已知问题、解决方案和最佳实践。

## 快速开始

```bash
# 1. 锁定 Python 版本（Hermes 需要 <3.14）
apt-mark hold python && apt-mark hold python-ensurepip-wheels

# 2. 安装 uv
pkg install uv

# 3. 创建 venv
uv venv venv --python /data/data/com.termux/files/usr/bin/python3.13 --system-site-packages --seed

# 4. 安装 Hermes
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

## 仓库结构

```
├── SKILL.md              # 主文档：快速参考 + 已知问题
├── references/           # 详细参考文档
│   ├── android-sdk-setup.md      # Android SDK 配置
│   ├── ndk-setup.md              # NDK 配置
│   ├── agp-compatibility.md      # AGP 兼容性矩阵
│   ├── pitfalls.md               # 常见陷阱汇总
│   ├── hermes-termux.md          # Hermes 在 Termux 上的特殊配置
│   └── haven-termux-build.md     # vTerm 项目构建指南
└── scripts/              # 实用脚本
    └── verify-arm64-sdk.sh       # 验证 SDK 原生二进制架构
```

## 已知问题速查

| 问题 | 状态 | 解决方案 |
|------|------|----------|
| Python 3.14 破坏 Hermes | — | `apt-mark hold python` |
| psutil 编译失败 | — | `--system-site-packages` |
| python -m venv 失败 | — | 使用 `uv venv` |
| TUI 文字消失 (Xiaomi Android 16) | CLOSED (未修复) | 切换 CLI 模式 |
| apt/pkg 在 Android 16 上损坏 | CLOSED (未修复) | Bionic stdio errno bug |
| pip 在 Python 3.13.12-2 上损坏 | CLOSED (无修复) | 使用 `uv pip` |
| nettle 破坏 apt | CLOSED | 避免更新 nettle |

## 严重差异（vs 标准 Linux）

| 标准 Linux | Termux/Android |
|------------|-----------------|
| `apt install` | `pkg install` |
| `/tmp` 可写 | 使用 `$HOME` |
| `systemd` | 使用 `tmux` |
| `python3 -m venv` | `uv venv` |
| `which` | `command -v` |
| x86_64 二进制 | 仅 ARM64 |
| glibc | Bionic libc |

## 链接

- [官方 Hermes 文档](https://hermes-agent.nousresearch.com/docs)
- [Termux 官网](https://termux.dev/)
- [lzhiyong ARM64 tools](https://github.com/lzhiyong/android-sdk-tools)
- [Termux AI Guide (旧版)](https://github.com/lietxia/termux-tool-guide)

## License

MIT
