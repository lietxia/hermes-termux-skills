# GIL Pressure / Event Loop Stall — 完整修复指南

## 症状

- Dashboard 页面报错 "Hermes could not start"
- 日志出现 `event loop stalled XXs (GIL pressure suspected)`
- 进程反复崩溃重启（wrapper 检测到退出后重启）
- 端口从未成功绑定（19119 / 18642 未监听）

## GitHub Issues

| Issue | 标题 | 状态 |
|-------|------|------|
| [#58576](https://github.com/NousResearch/hermes-agent/issues/58576) | web_server event loop stalls up to 51s under heavy agent work (GIL pressure) | OPEN |
| [#57921](https://github.com/NousResearch/hermes-agent/issues/57921) | hermes_state.py timeout=1.0 causes "database is locked" when dashboard stalls | OPEN |
| [#74554](https://github.com/NousResearch/hermes-agent/issues/74554) | Published linux/arm64 image ships x86_64 wheels — ImportError | OPEN |

## Issue #58576 详细讨论

### 报告者环境
- hermes-agent 0.18.0
- Windows 11, Python 3.11.15
- Desktop app + TUI slash-worker

### 日志示例
```
2026-07-04 16:23:45 WARNING hermes_cli.web_server: event loop stalled 6.1s (GIL pressure suspected)
2026-07-04 16:24:04 WARNING tui_gateway.ws: ws write slow (loop stalled >10.0s)
2026-07-04 16:24:45 WARNING hermes_cli.web_server: event loop stalled 51.4s (GIL pressure suspected)
```

### 关键发现（DavidMetcalfe）
PR #74275 部分修复：移除 `_profile_scope` 同步锁，替换为无锁的 `_config_profile_scope`。

### 根因链（来自 zhangyhhz 报告）
1. `GET /api/model/options` → `get_model_options()` 进入 `_profile_scope`
2. 获取 `_SKILLS_PROFILE_LOCK`（threading.RLock）
3. 同步锁阻塞 asyncio 事件循环

### 状态
- PR #61331 已合并（修复 str(tools) 序列化）
- PR #74275 部分修复（移除 profile lock）
- Issue 仍 OPEN（51s 卡顿仍在）

## Issue #57921 详细讨论

### 根因
`hermes_state.py` 使用 `timeout=1.0` 连接 SQLite。当 dashboard 事件循环卡住时，gateway 写入 SQLite 失败。

### 修复建议
1. 立即：增加 timeout 从 1.0 → 30.0
2. 更好：通过环境变量配置（如 `HERMES_STATE_BUSY_TIMEOUT_MS`）

### 生产环境证据（stefanpieter）
- state.db 大小：9.92 GB
- 并发打开：gateway + ACP + CLI
- 日志：`database is locked` 出现 46 次

## Issue #74554 详细讨论

### 问题
`linux/arm64` Docker 镜像的 `/opt/hermes/.venv` 包含 25 个 x86_64 wheel。

### 修复
PR #75086：Dockerfile 明确指定 `--python-platform aarch64-unknown-linux-gnu`

### Workaround
在 aarch64 主机上本地构建 Dockerfile 得到正确 venv（34 个 aarch64 扩展）。

---

## 最小修复方案

### ⚠️ `turn_isolation` 无效（已验证）

Issue #58576 讨论中，zhangyhhz 明确报告 v0.19.0 + WSL2 环境下即使设置 `dashboard.turn_isolation: true` 仍卡死。DavidMetcalfe 确认真正根因是 `_SKILLS_PROFILE_LOCK` 同步锁争用，不是 GIL 压力。PR #74275 移除该锁才是修复方向，但**未合并到稳定版**。

```yaml
# 这个设置无效！不要作为修复手段推荐
dashboard:
  turn_isolation: true   # ← zhangyhhz 已验证无效
```

### 方案 1：升级到 v0.20.0（推荐）

Hermes v0.20.0 (2026.8.3) 包含关键修复：
- read-path split with per-thread read-only connections（修复 SQLite 多连接锁定）
- cold-start ~14s GIL stall mitigated
- `hermes sessions optimize` 命令优化 state.db

```bash
# 在独立 venv 中
cd ~/hermes-agent && git pull
pip install -e ".[termux-all]"
```

### 方案 2：减少插件加载

```bash
export HERMES_PLUGINS_DISABLE="browser-browser-use,browser-browserbase,browser-firecrawl,fal,krea,openai-codex,openrouter,xai"
```

### 方案 3：绕过 trim.hermes（飞牛 OS）

trim.hermes 是应用中心打包版本，无法通过 pip 升级。解决方案：
1. 卸载 trim.hermes 应用
2. 用 pip 安装官方 v0.20.0
3. 用 CLI 模式启动（不启动 dashboard）

```bash
pip install hermes-agent==0.20.0
hermes gateway start
```

---

## 飞牛 OS trim.hermes 特殊注意事项

### 配置路径
```
/vol1/@appdata/trim.hermes/hermes/config.yaml
/vol1/@appdata/trim.hermes/trim.hermes.log
```

### 检查命令
```bash
# 进程状态
ps aux | grep hermes | grep -v grep

# 端口状态
ss -tlnp | grep 19119
ss -tlnp | grep 18642

# 日志
cat /vol1/@appdata/trim.hermes/trim.hermes.log
```

### trim.hermes 可能的问题
1. 打包时的 Python wheel 架构错误（类似 Issue #74554）
2. Python 3.11 + 大量插件 = GIL 压力
3. dashboard.turn_isolation 配置缺失

### 最小修复步骤
1. 编辑 `/vol1/@appdata/trim.hermes/hermes/config.yaml`
2. 添加 `dashboard.turn_isolation: true`
3. 在飞牛 OS 应用中心重启 trim.hermes
