# Managing Remote Linux Machines from Termux

This guide covers connecting to and managing remote Linux machines (Debian, Ubuntu, 飞牛OS, etc.) from Termux via SSH.

## When to Use This

- The user has a remote machine (NAS, server, another computer) they want to manage
- SSH credentials (username + password) are provided
- The machine may run Debian, Ubuntu, 飞牛OS, or other Linux distributions

## Golden Rules

1. **NEVER install software on a remote machine without explicit permission.**
2. If the user says "已经装了" or "don't install" — STOP IMMEDIATELY.
3. Never run `sudo` commands on remote machines without explicit approval.
4. Never use `echo 'pass' | sudo -S` — this is a brute-force attack vector.
5. **ALWAYS use tmux for long-lived SSH sessions** instead of one-off commands.

## Setting Up a Tmux-Based SSH Session

```bash
# Start tmux session with SSH (keeps connection alive)
tmux new-session -d -d -s ssh_<name> -x 240 -y 60 "sshpass -p 'PASSWORD' ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 user@HOST"

# Send commands
tmux send-keys -t ssh_<name> "your-command" Enter
sleep 3

# Read output
tmux capture-pane -t ssh_<name> -p | tail -20

# Attach to interact
tmux attach -t ssh_<name>

# Kill session
tmux kill-session -t ssh_<name>
```

## Finding Tmux Sockets on Termux

Tmux socket path: `/data/data/com.termux/files/usr/var/run/tmux-*/default`

If `tmux` commands hang or fail with "no server running", the environment may have `TMUX` set incorrectly. Unset it:

```bash
TMUX="" tmux capture-pane -t ssh_<name> -p
```

## Connection Testing

Before doing anything else, verify connectivity:

```bash
# Test SSH with one-liner first
sshpass -p 'PASSWORD' ssh -o StrictHostKeyChecking=no user@HOST "uname -a && cat /etc/os-release && python3 --version"

# Check sudo access (without running anything)
sshpass -p 'PASSWORD' ssh -o StrictHostKeyChecking=no user@HOST "sudo -n true 2>&1 && echo 'sudo ok' || echo 'no sudo'"
```

## Common Remote Machines

| Machine | OS | Typical Use |
|---------|-----|------------|
| 飞牛OS (FnOS) | Debian 12 aarch64 | NAS with app center |
| Debian/Ubuntu | x86_64/aarch64 | Servers, workstations |

## 飞牛OS Specifics

飞牛OS is a Debian-based NAS OS with:
- App center for one-click installs (including Hermes)
- Default user is usually the one created during setup
- SSH needs to be enabled in control panel
- Hermes is installed at `/vol1/@appcenter/trim.hermes/`
- Hermes needs PATH configuration to work as `hermes` command

### Hermes on 飞牛OS

```bash
# Find Hermes binary
find / -name 'hermes' -type f 2>/dev/null | head -5

# Create symlink for PATH access
sudo ln -sf /vol1/@appcenter/trim.hermes/runtime/python/bin/hermes /usr/local/bin/hermes

# Verify
hermes --version
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| SSH connection refused | Enable SSH in machine's control panel |
| Password auth denied | Check if key-based auth is required |
| `command not found` | The tool isn't in PATH; use full path or create symlink |
| Tmux commands hang | TMUX env var is set; use `TMUX="" tmux ...` |
