# Termux Browser Automation

Hermes browser tools need a backend. On Termux the options differ from desktop.

## Comparison

| Solution | Free | CDP | Works with Hermes browser tools | Difficulty |
|----------|------|-----|--------------------------------|------------|
| **termux-agent-browser** | Yes | Yes | Yes, native | Easy |
| **Termux Browser Pilot** | Yes | Yes | Via terminal only | Medium |
| **Browser Use cloud** | Paid | Yes | Yes | Easy |
| **WebDroid** | Yes | No | No | Hard |
| **Local Chromium + CDP** | Yes | Yes | Yes | Hard |

## termux-agent-browser (recommended)

https://github.com/pjy010218/termux-agent-browser

Patches agent-browser (Vercel Labs) for Termux aarch64, and offers a CDP-only
quick-start that works with Hermes immediately.

```
Hermes Agent (browser tools) → CDP WebSocket :9222 → Chromium (headless)
```

```bash
pkg install x11-repo chromium
chromium --headless --no-sandbox --remote-debugging-port=9222
```

Configure Hermes (`~/.hermes/config.yaml`):

```yaml
browser:
  cdp_url: "ws://127.0.0.1:9222"
```

Then `/browser connect` in the Hermes CLI.

Troubleshooting:

- `WebSocket connection failed` → confirm Chromium is up:
  `curl -s http://127.0.0.1:9222/json/version`
- `which: command not found` → `pkg install which`
- Permission errors → `termux-setup-storage`, and use `$PREFIX/var/tmp/` for user data

Note: the Hermes APT package does **not** bundle Chromium. `pkg install chromium`
works only where your repository provides it. Without a chromium on `PATH`, the
browser tool reports that browsing is unavailable.

## Termux Browser Pilot

https://github.com/salviz/termux-browser-pilot

Standalone browser-automation CLI for Termux. Drives Firefox (default) or Chromium via
Xvfb plus xdotool/CDP.

```
CLI (tbp) ──Unix socket──→ Daemon ─┬─ BrowserPilot (Xvfb + openbox + browser)
                                   ├─ NativeFirefoxSession (xdotool + clipboard JS)
                                   ├─ CDPSession (CDP for Chromium)
                                   └─ Commands (navigate, click, type, screenshot, cookie)
```

```bash
pkg install firefox xorg-server-xvfb xdotool xclip openbox python3
pip install termux-browser-pilot
tbp start
tbp goto https://example.com
tbp screenshot /sdcard/page.png
tbp text
```

Limitations: not integrated with the Hermes browser tools — call it through the
`terminal` tool. No real-time DOM inspection.

## WebDroid

https://github.com/takafu/webdroid

Android WebView app controlled from Termux over a localhost HTTP API, shown as a
floating bubble.

```bash
source ~/webdroid/client/browser.sh
browser_goto "https://example.com"
browser_screenshot screenshot.png
```

Limitations: needs an ADB connection, an APK build (SDK + Gradle), and the
"display over other apps" permission. WebView is more limited than Chromium.

## Decision guide

- **Use the Hermes browser tools directly** → termux-agent-browser
- **Screenshots and basic automation only** → Termux Browser Pilot
- **A real Android WebView** → WebDroid, if you can build the APK and use ADB
- **Anti-detect plus residential proxies** → Browser Use cloud (no free tier)
