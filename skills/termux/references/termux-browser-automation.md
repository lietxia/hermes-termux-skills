# Termux Browser Automation

Hermes browser tools (`browser_exec`, `browser_navigate`, etc.) need a
backend. On Termux, local Chromium via CDP is the primary path — it's free,
native (no proot), and passes Cloudflare with the right flags.

## Comparison Table

| Solution | Free | CDP | Hermes browser tools | Difficulty | Notes |
|----------|------|-----|----------------------|------------|-------|
| **Local Chromium + CDP** | ✅ | ✅ | ✅ Native | Easy | **Recommended** — `pkg install chromium`, no proot |
| **termux-agent-browser** | ✅ | ✅ | ✅ Native | Easy | Patches agent-browser for Termux ARM64; adds CDP quick-start |
| **Termux Browser Pilot** | ✅ | ✅ | ⚠️ Via terminal only | Medium | CLI tool, separate daemon |
| **Browser Use cloud** | Paid | ✅ | ✅ | Easy | Anti-detect + residential proxies |
| **WebDroid** | ✅ | ❌ | ❌ | Hard | APK + ADB required |

## Local Chromium + CDP (Recommended)

Termux's `chromium` package provides a native ARM64 Chromium binary. No
proot-distro needed.

### Install

```bash
pkg install -y x11-repo chromium which
```

The executable is `chromium-browser` (a symlink to
`$PREFIX/lib/chromium/chromium-launcher.sh`). The actual binary is
`$PREFIX/lib/chromium/chrome`.

### Start Chromium headless with CDP

```bash
chromium-browser \
  --headless=new \
  --no-sandbox \
  --disable-gpu \
  --remote-debugging-port=9222 \
  --remote-debugging-address=127.0.0.1 \
  --user-data-dir=$HOME/.chromium-cdp-profile \
  --disable-blink-features=AutomationControlled \
  --user-agent="Mozilla/5.0 (Linux; Android 16; Xiaomi Build/UQ1A.240205.004) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.8059.79 Mobile Safari/537.36"
```

Key flags:
- `--headless=new` — the NEW headless mode. The old `--headless` flag
  triggers Cloudflare bot detection and Turnstile challenges hang forever.
- `--disable-blink-features=AutomationControlled` — hides the
  `navigator.webdriver` automation flag that Cloudflare checks.
- `--user-agent=...` — a real Android UA prevents Cloudflare from flagging the
  request as a headless desktop browser.
- `--no-sandbox` — required on Termux (no suid sandbox available).
- `--user-data-dir` — use a dedicated dir so the profile persists cookies
  across restarts (Cloudflare clearance cookies survive).

### Configure Hermes

`~/.hermes/config.yaml` is security-protected — do NOT edit it with `patch`
or `write_file`. Use `hermes config set`:

```bash
hermes config set browser.cloud_provider local
hermes config set browser.cdp_url http://127.0.0.1:9222
hermes config set browser.use_gateway false
```

The `cdp_url` uses `http://` (not `ws://`). Hermes resolves the WebSocket
endpoint from the HTTP version endpoint automatically.

### Verify CDP is running

```bash
curl -s http://127.0.0.1:9222/json/version
```

A successful response returns JSON with `Browser`, `Protocol-Version`, and
`webSocketDebuggerUrl`.

### Restart the gateway after config changes

```bash
hermes gateway restart
```

**Pitfall**: `hermes gateway restart` kills ALL background processes spawned
by the gateway, including Chromium. After a restart, re-launch Chromium
before using browser tools, or `browser_exec` will fail with
`Connection refused`.

## Cloudflare Turnstile Bypass

With the flags above (`--headless=new` + `--disable-blink-features=AutomationControlled`
+ real Android UA), Cloudflare Turnstile **managed** challenges pass
automatically — no manual checkbox click needed. The Turnstile JS runs in
the background and issues a `cf_clearance` cookie.

Without these flags (e.g. plain `--headless`), Turnstile hangs at
"Just a moment..." indefinitely — the `cf-turnstile-response` hidden input
stays empty and the page never redirects.

### Verifying Turnstile passed

```python
# After navigating, check if we got past Cloudflare:
title = js("document.title")
# "Just a moment..." = still on challenge page
# Real site title = passed
```

### JSON API endpoints also get challenged

Discourse sites like linux.do serve topic data at `/latest.json`. Cloudflare
challenges these too — the first request to any path under the protected
domain may hit Turnstile. After the cookie is set, subsequent requests pass.

## Heavy SPA Loading (Discourse, Ember.js)

Sites built on Discourse/Ember.js are heavy SPAs. On Termux's network:

- `document.readyState` may stay at `"loading"` for 30+ seconds while CSS
  and JS bundles download from CDNs.
- The page HTML loads immediately (correct `<title>`, `<meta>` tags) but
  `#data-preloaded` and the Ember bootstrap don't appear until all
  stylesheets finish.
- Use `typeof require !== 'undefined'` and presence of `#data-preloaded`
  as readiness checks — not `document.readyState`.

```python
# Wait for Discourse SPA to fully bootstrap
import time
for _ in range(12):  # up to 60s
    time.sleep(5)
    if js("typeof require !== 'undefined'") == "yes" and \
       js("document.querySelector('#data-preloaded') ? 'yes' : 'no'") == "yes":
        break
```

## termux-agent-browser

🔗 https://github.com/pjy010218/termux-agent-browser

Patches agent-browser (Vercel Labs) for Termux ARM64. Also provides a
CDP-only quick-start path — same CDP approach as above, but with a setup
script that handles the Chromium service lifecycle.

## Termux Browser Pilot

🔗 https://github.com/salviz/termux-browser-pilot

Standalone CLI for Termux. Controls Firefox (default) or Chromium via
Xvfb + xdotool/CDP. NOT directly integrated with Hermes browser tools —
must be called via the `terminal` tool.

**Feature**: Cloudflare bypass via Firefox native TLS or Chromium Turnstile
handler.

## WebDroid

🔗 https://github.com/takafu/webdroid

Android WebView app controllable from Termux via HTTP API. Requires APK
compilation (Android SDK + Gradle) and ADB. WebView has limitations vs
full Chromium.

## SearXNG as the default browser search engine

The instance's search URL is `https://<instance>/search?q=%s` (`%s` = the
query). Add it as a custom engine per browser:

- **Chromium (Chrome / Edge)**: visit the instance root **once first** —
  Chromium only offers autodiscovered engines for sites it has navigated to at
  the root path. Then `chrome://settings/searchEngines` → add
  `https://<instance>/search?q=%s` → set default. Edge: Settings → Privacy →
  Address bar and search → Manage search engines.
- **Lightweight Android browsers (Via / Vie class)**: Settings → search engine
  → custom → paste the URL.

A duplicate engine name fails to add — delete the existing entry first.

## Decision Guide

- **Use Hermes browser tools directly** → Local Chromium + CDP (easiest)
- **Need anti-detect + residential proxies** → Browser Use cloud (paid)
- **Need Firefox for Cloudflare bypass** → Termux Browser Pilot (separate CLI)
- **Need real Android WebView** → WebDroid (if you can compile APK + use ADB)
