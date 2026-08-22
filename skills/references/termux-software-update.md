# Updating Termux-Portable Software from GitHub

Many Termux users star GitHub repositories that provide ARM64 builds of CLI tools (e.g., `Hope2333/opencode-termux`, `Hope2333/bun-termux`). This guide covers updating them.

## Finding Starred Termux Projects

```bash
# List all starred repos matching a keyword
gh api user/starred --paginate --jq '.[].full_name' | grep -i "termux\|opencode\|mimo"

# Check latest release version
gh api repos/OWNER/REPO/releases/latest --jq '.tag_name,.published_at'

# List release assets
gh api repos/OWNER/REPO/releases/latest --jq '.assets[] | "\(.name) - \(.download_count) downloads"'
```

## Installing/Updating .deb Packages on Termux

Termux `.deb` packages contain files under `./data/data/com.termux/files/usr/`. Extract and install manually:

```bash
# Download the release asset
gh release download TAG --repo OWNER/REPO --pattern "pkg_*.deb" --dir ~/

# Extract the .deb
cd ~/
ar x pkg_*.deb
tar xf data.tar.xz

# Install (copy files to Termux prefix)
cp -r ./data/data/com.termux/files/usr/bin/* /data/data/com.termux/files/usr/bin/
cp -r ./data/data/com.termux/files/usr/lib/* /data/data/com.termux/files/usr/lib/

# Cleanup
rm -rf ~/data ~/control.tar.xz ~/data.tar.xz ~/pkg_*.deb
```

### For opencode specifically

OpenCode on Termux has a launcher script + runtime binary:

```bash
# Replace launcher
cp ./data/data/com.termux/files/usr/bin/opencode /data/data/com.termux/files/usr/bin/opencode

# Replace runtime (the actual binary)
cp ./data/data/com.termux/files/usr/lib/opencode/runtime/opencode /data/data/com.termux/files/usr/lib/opencode/runtime/opencode

# Verify
opencode --version
```

## Known Termux-Portable Repos

| Repo | Package | Current Version | Notes |
|------|---------|----------------|-------|
| Hope2333/opencode-termux | opencode | 1.18.3 (Push260719) | ARM64 .deb |
| Hope2333/bun-termux | bun | 1.3.14 | ARM64 .deb |
| Hope2333/MiMoCode-Termux | mimocode (mimo) | 0.1.6 (Push260611) | ARM64 .deb |
| lzhiyong/termux-ndk | NDK r29 | - | ARM64 NDK for native builds |

## SkillHub CLI

The SkillHub CLI provides accelerated skill search/install for Chinese users:

```bash
# Install (CLI only)
curl -fsSL https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/install/install.sh | bash -s -- --cli-only

# Add to PATH
export PATH="$HOME/.local/bin:$PATH"

# Use
skillhub search calendar
skillhub install abc --dir ~/.hermes/skills
skillhub update --dir ~/.hermes/skills
```

Installed version: skillhub 2026.7.29

### Installing Search Skills via SkillHub

```bash
# Search for available search skills
skillhub search baidu
skillhub search mcp

# Install Baidu AI Search
skillhub install baidu-search --namespace ide-rea --dir ~/.hermes/skills/

# Configure API Key
echo "BAIDU_API_KEY=YOUR_BAIIDU_API_KEY" >> ~/.hermes/.env
```

API Key 申请: https://console.bce.baidu.com/ai-search/qianfan/ais/console/apiKey

## MCP Tavily Search

Tavily search is available as an MCP server via HTTP:

```bash
# Install mcp package
cd ~/hermes-agent && source venv/bin/activate && pip install mcp

# Add mcp_servers to ~/.hermes/config.yaml
mcp_servers:
  tavily:
    enabled: true
    headers:
      Authorization: Bearer YOUR_TAVILY_API_KEY
    url: https://tavily.ivanli.cc/mcp
```

Restart Hermes → auto-registers as `mcp_tavily_tavily_search` tool.

## GitHub Push Protection Blocks Commits with Secrets

GitHub's push protection will block commits containing API keys (even in README files). Use placeholder values like `YOUR_API_KEY` in public repos. If blocked:

1. Replace secrets with placeholders in the file
2. `git add` and `git commit --amend` or make a new commit
3. Or follow the unblock URL GitHub provides in the error message

## Hermes Update Workaround

`hermes update` may fail on Termux due to managed `uv` install issues. Use manual update:

```bash
cd ~/hermes-agent
git pull
source venv/bin/activate
uv pip install -e ".[termux-all]"
```

### MiMoCode-Termux Update

MiMoCode-Termux wraps the upstream MiMo-Code model (v0.1.9) via bun-termux-loader.

```bash
# Download and install
gh release download Push260611 --repo Hope2333/MiMoCode-Termux --pattern "mimocode_0.1.6_aarch64.deb" --dir ~/
cd ~/
ar x mimocode_0.1.6_aarch64.deb
tar xf data.tar.xz
cp ./data/data/com.termux/files/usr/bin/mimo /data/data/com.termux/files/usr/bin/mimo
cp -r ./data/data/com.termux/files/usr/lib/mimocode /data/data/com.termux/files/usr/lib/mimocode
rm -rf ~/data ~/mimocode_0.1.6_aarch64.deb ~/control.tar.xz ~/data.tar.xz
mimo --version  # Shows 0.1.0 (hardcoded string, actual version is 0.1.6)
```

**PITFALL**: `mimo --version` shows `0.1.0` (hardcoded in the binary) regardless of actual package version. Check the binary file date to verify:
```bash
ls -la /data/data/com.termux/files/usr/lib/mimocode/runtime/mimocode
# Jun 16 = v0.1.6, Jun 15 = v0.1.5, etc.
```

**PITFALL**: MiMoCode-Termux requires `glibc` + `openssl-glibc` at runtime:
```bash
apt install -y glibc-repo && apt update && apt install -y glibc openssl-glibc
```
