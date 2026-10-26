# Telegram Gateway Setup

## Steps

1. Get a bot token from @BotFather on Telegram.
2. Configure through the CLI:

```bash
hermes config set gateway.platforms.telegram.enabled true
hermes config set gateway.platforms.telegram.token "YOUR_BOT_TOKEN"
```

3. Restart the gateway **from an external terminal, not from inside the gateway
   session**:

```bash
hermes gateway restart
```

4. The user sends a first message to the bot; the bot replies with a pairing code.
5. Approve the pairing from Termux:

```bash
hermes pairing approve telegram PAIRING_CODE
```

6. The user sends another message; the bot now responds normally.

## Restrict to specific users (optional)

```bash
hermes config set gateway.platforms.telegram.allowed_users '["username"]'
```

## Pitfalls

- **Never restart the gateway from inside a gateway session.** The SIGTERM kills the
  session that issued it. Use a separate shell, or tmux.
- **`~/.hermes/config.yaml` must not be edited directly by the agent** — security
  policy. Use `hermes config set`.
- **Pairing approval expires** a few minutes after the first message. Approve promptly.
- On Termux, prefer `hermes gateway run` in a tmux session over `gateway restart` for
  long-lived operation; see [termux-environment.md](termux-environment.md).
