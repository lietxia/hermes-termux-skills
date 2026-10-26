# SkillHub CLI and News Skills on Termux

## SkillHub CLI

SkillHub is a China-friendly skill store for Hermes agents. `hermes skills install`
may block it — the supply-chain scan flags the curl-to-COS pattern.

### Manual install (CLI only)

```bash
# Download into $HOME, not /tmp — /tmp is not writable on Termux
curl -fsSL https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/install/install.sh -o ~/skillhub-install.sh
bash ~/skillhub-install.sh --cli-only

export PATH="$HOME/.local/bin:$PATH"
skillhub --version
skillhub search test
```

### Usage

```bash
skillhub search <keyword>
skillhub install <name> --dir ~/.hermes/skills
skillhub update --dir ~/.hermes/skills
```

## GitHub token for Skills Hub

After `gh auth login`, sync the token so Skills Hub is not rate-limited
(60 requests/hour unauthenticated versus 5000):

```bash
echo "GITHUB_TOKEN=$(gh auth token)" >> ~/.hermes/.env
```

## News skills that need no API key

### hackernews
Browse and search Hacker News via its API. Needs `jq`.

```bash
pkg install jq
bash ~/.hermes/skills/hackernews/scripts/hn.sh top --limit 10
```

### news-aggregator-skill
Eight sources: Hacker News, GitHub Trending, Product Hunt, 36Kr, Tencent News,
WallStreetCN, V2EX, Weibo.

```bash
uv pip install requests beautifulsoup4
python3 scripts/fetch_news.py --source github --limit 10
```

Known quirk: the Hacker News source can return an empty array; the GitHub source
works reliably.

### web-search-free
Free AI search through the Exa MCP server. Needs `mcporter`.

```bash
npm install -g mcporter
mcporter config add exa "https://mcp.exa.ai/mcp?tools=web_search_exa,..."
mcporter call 'exa.web_search_exa(query: "test", numResults: 3)'
```

### weather
Free weather queries, no key. Just ask, for example "北京天气".

## Termux skills worth having

- `termux-env-guide` — this skill
- `android-native-dev` — Material Design 3, Kotlin/Compose
- `android` — build system and deployment patterns
- `github-trending` — GitHub trending repositories
- `trend-watcher` — tech community monitoring

## Removed

- `termux-persistent-gateway` — installed, then removed at the user's request
  ("完全没用"). Termux already handles this adequately; see
  [termux-environment.md](termux-environment.md) for the tmux pattern.
