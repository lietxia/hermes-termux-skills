# Telegram Gateway Setup on Hermes

## Setup Steps

1. Get a bot token from @BotFather on Telegram
2. Configure via CLI:
```bash
hermes config set gateway.platforms.telegram.enabled true
hermes config set gateway.platforms.telegram.token "YOUR_BOT_TOKEN"
```

3. Restart gateway (from external terminal, NOT from inside gateway):
```bash
hermes gateway restart
```

4. User sends first message to the bot → bot replies with pairing code
5. Approve pairing from Termux:
```bash
hermes pairing approve telegram PAIRING_CODE
```

6. User sends another message → bot responds normally

## Restrict to specific users (optional)
```bash
hermes config set gateway.platforms.telegram.allowed_users '["username"]'
```

## Key Pitfalls
- Cannot restart gateway from within gateway session (SIGTERM kills self)
- Config file `~/.hermes/config.yaml` cannot be edited directly by agent (security policy) — must use `hermes config set`
- Pairing approval must happen within a few minutes of the first message
