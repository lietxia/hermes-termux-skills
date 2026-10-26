# Managing Remote Machines from Termux

Controlling remote Linux hosts (Debian, Ubuntu, 飞牛OS, and similar) over SSH.

## Golden rules

1. **Never install software on a remote machine without explicit permission.**
2. If the user says "已经装了" or "don't install" — stop immediately.
3. Never run `sudo` on a remote machine without explicit approval.
4. **Use key-based auth, not passwords on the command line.** A password in a shell
   command lands in the process list, the shell history, and any transcript. Set up a
   key once instead.
5. **One tmux session per host.** Do not re-establish the connection per command.

## Set up key auth once

```bash
ssh-keygen -t ed25519 -C "termux" -f ~/.ssh/id_ed25519 -N ""
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@HOST
ssh user@HOST "uname -a && cat /etc/os-release"
```

`ssh-copy-id` is available after `pkg install openssh`. If it is not, append the
public key to `~/.ssh/authorized_keys` on the host manually.

Check sudo access without running anything:

```bash
ssh user@HOST "sudo -n true 2>&1 && echo 'sudo ok' || echo 'no passwordless sudo'"
```

## One tmux session per host

```bash
# Start the session (detached)
tmux new -d -s remote -x 240 -y 60 "ssh -o ServerAliveInterval=60 user@HOST"

# Send a command
tmux send-keys -t remote "your-command" Enter
sleep 3

# Read the output
tmux capture-pane -t remote -p | tail -20

# Interact
tmux attach -t remote

# Tear down
tmux kill-session -t remote
```

Keep one session per host for the whole task. Sending the next command to the existing
session is both faster and safer than reconnecting — no repeated authentication, and
no credentials repeated on the command line.

## Tmux socket path

Termux: `/data/data/com.termux/files/usr/var/run/tmux-*/default`.

If tmux hangs or reports `no server running`, the `TMUX` variable may be set wrongly.
Unset it for that invocation:

```bash
TMUX="" tmux capture-pane -t remote -p
```

## Common remote machines

| Machine | OS | Typical use |
|---------|-----|-------------|
| 飞牛OS (FnOS) | Debian 12 aarch64 | NAS with an app center |
| Debian / Ubuntu | x86_64 or aarch64 | Servers, workstations |

## 飞牛OS specifics

- App center provides one-click installs, including Hermes.
- The default user is the one created during setup.
- SSH must be enabled in the control panel.
- A Hermes install from the app center lives under `/vol1/@appcenter/trim.hermes/`
  and may need a PATH entry to work as a bare `hermes` command.

```bash
ssh user@HOST "command -v hermes || echo 'hermes not on PATH'"
```

If it is not on PATH, ask before creating a symlink — that is a remote-machine change.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| SSH connection refused | Enable SSH in the machine's control panel |
| Password auth denied | Key-based auth is required; set up a key |
| `command not found` | The tool is not on PATH; use the full path |
| tmux commands hang | `TMUX` is set; use `TMUX="" tmux ...` |
| Session dies after each command | You are reconnecting; use one tmux session per host |
