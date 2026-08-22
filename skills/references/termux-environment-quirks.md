# Termux Environment Quirks for Hermes Agent

This document captures environment-level behaviors that affect ALL skills on Termux.

## Python Version — Independent venv (Not apt-mark hold)

The durable solution is a **fully independent Python venv** (not just `apt-mark hold`). Symlinks to system Python break on every `pkg upgrade`.

```bash
cd ~/hermes-agent/venv/bin
rm python python3 python3.13
cp /data/data/com.termux/files/usr/bin/python3.13 ~/hermes-agent/venv/bin/python3.13
ln -sf python3.13 ~/hermes-agent/venv/bin/python3
ln -sf python3 ~/hermes-agent/venv/bin/python
mkdir -p ~/hermes-agent/venv/lib
cp /data/data/com.termux/files/usr/lib/libpython3.13.so ~/hermes-agent/venv/lib/
cat > ~/hermes-agent/venv/pyvenv.cfg << 'EOF'
home = /data/data/com.termux/files/usr/bin
implementation = CPython
version_info = 3.13.12
include-system-site-packages = false
EOF
```

### Fallback: Quick Lock (Temporary Only)

If you can't rebuild venv right now:
```bash
apt-get install --allow-downgrades -y python=3.13.12-3
apt-mark hold python
apt-mark hold python-ensurepip-wheels
```

## Gateway Restart

`hermes gateway restart` CANNOT run from inside the gateway process (Feishu DM, Telegram, etc.). Must run from a separate Termux shell.

## /tmp Not Writable

Termux restricts `/tmp` permissions. Use `$HOME` for all temp files, downloads, and build outputs.

## venv Creation

`python3 -m venv` fails with ensurepip errors on Termux. Always use:
```bash
uv venv venv --python python3
```

## Search Skills State

| Tool | Backend | Status |
|------|---------|--------|
| `web_search` | firecrawl | ✅ Available |
| `hackernews` | hn.sh script | ✅ Available |
| `github-trending` | news-aggregator | ✅ Available |
| `ddgs` | DuckDuckGo | ❌ Install hangs (lxml compilation) |
| `arxiv` | hub skill | ❌ Missing scripts |
| `polymarket` | hub skill | ❌ Missing scripts |
| `blogwatcher` | hub skill | ❌ Missing scripts |

**Alternative**: Use built-in `web_search` (firecrawl backend) instead of ddgs.

## New AI Tools (2026-08)

### Tavily MCP Search
Free MCP-based search. Add to `~/.hermes/config.yaml`:
```yaml
mcp_servers:
  tavily:
    enabled: true
    headers:
      Authorization: Bearer YOUR_TAVILY_API_KEY
    url: https://tavily.ivanli.cc/mcp
```

### Baidu AI Search
```bash
skillhub install baidu-search --namespace ide-rea --dir ~/.hermes/skills/
echo "BAIDU_API_KEY=YOUR_BAIDU_API_KEY" >> ~/.hermes/.env
```
API Key: https://console.bce.baidu.com/ai-search/qianfan/ais/console/apiKey

### SkillHub CLI
```bash
curl -fsSL https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/install/install.sh | bash -s -- --cli-only
export PATH="$HOME/.local/bin:$PATH"
```

### OpenCode-Termux & MiMoCode-Termux
```bash
# Download and extract deb to /usr/
curl -sL -o ~/pkg.deb "https://github.com/Hope2333/SOME/releases/latest/download/X.Y.Z_aarch64.deb"
cd ~ && ar x pkg.deb && tar xf data.tar.xz
cp ./data/data/com.termux/files/usr/bin/X /data/data/com.termux/files/usr/bin/
cp -r ./data/data/com.termux/files/usr/lib/X /data/data/com.termux/files/usr/lib/
```

### ddgs (DuckDuckGo) — Cannot Install on Termux
`ddgs` depends on `primp`, a Rust Python extension. It cannot install on Termux ARM64:
- `cargo build` for primp hangs or fails with `Text file busy (os error 26)`
- Even manual wheel extraction fails with `ImportError: dlopen failed: library "libgcc_s.so.1" not found` (glibc vs bionic libc)

**Do not attempt to install ddgs.** Use alternatives: `web_search` (firecrawl), Tavily MCP, Baidu AI Search.

## GitHub Push Protection Blocks Commits with Secrets

GitHub's push protection will block commits containing API keys (even in README). Use placeholder values like `YOUR_API_KEY` in public repos. If a commit is blocked:
- Replace secrets with placeholders and amend the commit
- Or use the unblock URL GitHub provides in the error message

## Feishu Markdown Limitations

Feishu renders Markdown tables as plain text. Use **bold + lists** instead of tables in Feishu messages.

## Exploit/Security Research Limitation

Android seccomp blocks syscalls (`futex_wait_requeue_pi`, `pselect`, `pipe2`). Static-linked ELFs crash with SIGSYS (signal 31) inside Termux. Must use ADB shell or root + seccomp disable.
