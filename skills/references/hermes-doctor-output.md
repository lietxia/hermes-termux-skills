# hermes doctor 输出解读

运行 `hermes doctor` 后的常见警告及其含义：

## 必须修复的

| 警告 | 含义 | 修复 |
|------|------|------|
| `No API key found in ~/.hermes/.env` | 模型/语音等无法工作 | `hermes setup` 或手动写入 key |
| `terminal (system dependency not met)` | shell 命令执行通道异常 | `pkg install zsh util-linux procps` + `hermes setup terminal` |
| `Run 'hermes setup' to configure API keys` | 缺少关键凭证 | `hermes setup` |

## 可选修复

| 警告 | 含义 | 修复 |
|------|------|------|
| `discord.py (optional, not installed)` | Discord 集成缺少依赖 | 不用 Discord 可忽略 |
| `browser-cdp (system dependency not met)` | Chrome DevTools 不可用 | Android 上通常无法修复 |
| `computer_use (system dependency not met)` | 桌面控制不可用 | Android 上不适用 |
| `homeassistant (system dependency not met)` | 智能家居未配置 | 需要 HA 实例 |
| `x_search (missing XAI_API_KEY)` | X/Twitter 搜索不可用 | 需要 xAI key |
| `spotify (system dependency not met)` | Spotify 未配置 | 需要 Spotify OAuth |
| `discord (missing DISCORD_BOT_TOKEN)` | Discord bot 未配置 | 不用可忽略 |
| `OpenAI Codex auth (not logged in)` | Codex 未登录 | `hermes auth add openai-codex` |
| `No GITHUB_TOKEN` | Skills Hub 速率限制低 | 写入 `~/.hermes/.env` |

## 正常状态（不需要修复）

| 输出 | 含义 |
|------|------|
| `✓ Python 3.x.x` | Python 正常 |
| `✓ Virtual environment active` | venv 已激活 |
| `✓ Version files consistent` | 版本一致 |
| `✓ Nous Portal auth (logged in)` | Nous 已登录 |
| `Docker backend is not available inside Termux` | 预期内，Android 无 Docker |
| `agent-browser is not installed` | 可选，按需安装 |

## 一键修复流程

```bash
# 1. 诊断
hermes doctor

# 2. 修复包依赖
pkg install zsh util-linux procps openssh termux-api tmux

# 3. 修复 terminal 工具
hermes setup terminal

# 4. 配置 API keys
hermes setup

# 5. 同步 GitHub token
TOKEN=$(gh auth token)
echo "GITHUB_TOKEN=$TOKEN" >> ~/.hermes/.env

# 6. 再次诊断
hermes doctor
```
