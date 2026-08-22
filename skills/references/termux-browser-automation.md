# Termux Browser Automation Options

Hermes browser tools (browser_navigate, browser_type, screenshot, etc.) need a backend. On Termux, you have several options — this doc compares them.

## Comparison Table

| Solution | Free | CDP | Works with Hermes browser tools | Difficulty | Notes |
|----------|------|-----|-------------------------------|------------|-------|
| **termux-agent-browser** | ✅ | ✅ | ✅ Native | Easy | **Recommended** |
| **Termux Browser Pilot** | ✅ | ✅ | ⚠️ Via terminal only | Medium | CLI tool |
| **Browser Use cloud** | Paid | ✅ | ✅ | Easy | 195+ country proxies |
| **WebDroid** | ✅ | ❌ | ❌ | Hard | APK + ADB required |
| **Local Chromium + CDP** | ✅ | ✅ | ✅ | Hard | Needs proot-distro |

## termux-agent-browser (Recommended)

🔗 https://github.com/pjy010218/termux-agent-browser

**What it does**: Patches agent-browser (Vercel Labs) to support Termux ARM64. Also provides a CDP-only quick-start path that works immediately with Hermes.

**Architecture**:
```
Hermes Agent (browser tools)
    ↓
CDP WebSocket (:9222)
    ↓
Chromium (headless)
```

**Setup**:

```bash
# 1. Install dependencies
pkg install x11-repo chromium

# 2. Start Chromium (headless + remote debugging)
chromium --headless --no-sandbox --remote-debugging-port=9222

# 3. Configure Hermes (~/.hermes/config.yaml)
browser:
  cdp_url: "ws://127.0.0.1:9222"

# 4. In Hermes CLI, connect
/browser connect
```

**Troubleshooting**:
- `WebSocket connection failed` → Verify Chromium is running: `curl -s http://127.0.0.1:9222/json/version`
- `which: command not found` → `pkg install which`
- Permission errors → `termux-setup-storage` and use `$PREFIX/var/tmp/` for user data

**Reference**: https://github.com/pjy010218/termux-agent-browser

## Termux Browser Pilot

🔗 https://github.com/salviz/termux-browser-pilot

**What it does**: Standalone browser automation CLI for Termux. Controls Firefox (default) or Chromium via Xvfb + xdotool/CDP.

**Architecture**:
```
CLI (tbp) ──Unix socket──→ Daemon (daemon.py)
                                ├── BrowserPilot (Xvfb + openbox + browser lifecycle)
                                ├── NativeFirefoxSession (xdotool + clipboard JS)
                                ├── CDPSession (CDP for Chromium)
                                └── Commands (navigate, click, type, screenshot, cookie, etc.)
```

**Features**:
- Persistent daemon (sub-second commands)
- Cloudflare bypass (Firefox: native TLS; Chromium: Turnstile handler)
- Real device fingerprint (auto-detect screen, GPU, CPU, arch, model)
- MCP server for Claude Code integration

**Setup**:
```bash
# Install dependencies
pkg install firefox xorg-server-xvfb xdotool xclip openbox python3

# Install tool
pip install termux-browser-pilot

# Start daemon
tbp start

# Use
tbp goto https://example.com
tbp screenshot /sdcard/page.png
tbp text
tbp eval "document.title"
```

**Limitations**:
- NOT directly integrated with Hermes browser tools
- Must be called via `terminal` tool in Hermes
- No real-time DOM inspection

## WebDroid

🔗 https://github.com/takafu/webdroid

**What it does**: Android WebView app controllable from Termux via HTTP API. Displays as a floating bubble overlay.

**Architecture**:
```
Termux (curl/browser.sh)
    ↓ HTTP (localhost:8765)
WebDroid App (Android floating WebView)
```

**Features**:
- Floating bubble UI with resize
- Desktop mode (for Slack, etc.)
- JavaScript execution
- Screenshot capture
- Password manager support (Bitwarden)

**Setup**:
```bash
git clone https://github.com/takafu/webdroid.git
cd webdroid
gradle assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n io.github.takafu.webdroid/.BrowserActivity

# Control from Termux
source ~/webdroid/client/browser.sh
browser_goto "https://example.com"
browser_screenshot screenshot.png
```

**Limitations**:
- Requires ADB connection
- Needs APK compilation (Android SDK + Gradle)
- Floating bubble requires "display over other apps" permission
- WebView has limitations vs full Chromium

## Decision Guide

**Need to use Hermes browser tools directly?**
→ Use **termux-agent-browser** (easiest, native CDP)

**Just need screenshots and basic automation?**
→ Use **Termux Browser Pilot** (more features, but separate CLI)

**Need real Android WebView?**
→ Use **WebDroid** (if you can compile APK + use ADB)

**Need anti-detect + residential proxies?**
→ Pay for **Browser Use** cloud (no free option)
