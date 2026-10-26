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
5. **Always use a persistent tmux SSH session** — never repeat `sshpass` for each command. Open ONE tmux session, send commands via `send-keys`, read via `capture-pane`.

## Setting Up a Persistent Tmux SSH Session

One tmux session per remote host. Open it once, keep it for the entire session. Do NOT run `sshpass -p ... ssh ...` for every command — the user considers this an anti-pattern.

```bash
# Start tmux session with interactive SSH shell (long-lived)
tmux new -d -s remote "sshpass -p 'PASSWORD' ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -p PORT user@HOST 'bash -l'"

# Send commands (do NOT prefix with sshpass — use the tmux session)
tmux send-keys -t remote 'your-command-here' Enter
sleep 3

# Read output
tmux capture-pane -t remote -p | tail -20
```

For one-shot diagnostic commands where you need the raw output (not interactive), `sshpass` in a single `execute_code` call is acceptable — but switch to the tmux session immediately after.

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
| OpenWrt router (LibWrt) | ImmortalWrt 24.10 base, aarch64_cortex-a53 | Router / proxy gateway |

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

## OpenWrt / ImmortalWrt Routers

A router is not general-purpose Linux: the package manager is `opkg` (or `apk`
on 25.12+), configuration lives in UCI files under `/etc/config/`, and busybox
replaces many tools — `paste`, `which` and `grep -P` are usually absent, so
stick to `command -v`, plain `grep`, `awk`, and `od`.

Recon first:

```sh
cat /etc/openwrt_release      # DISTRIB_RELEASE, DISTRIB_TARGET, DISTRIB_ARCH
command -v opkg apk           # ...but THIS decides the package format
opkg list-installed | grep <name>
df -h /overlay
```

Never infer the package manager from `DISTRIB_RELEASE`: branded builds such as
LibWrt report `SNAPSHOT` while still using `opkg` and 24.10-era feeds.

Installing or updating a package from a third-party feed (proxy cores, LuCI
apps) — the `curl` + `opkg install` form:

1. Read the upstream `install.sh` before running it. It derives a feed branch
   from the release string and picks a package variant; both may be wrong here.
2. List `https://<feed>/<branch>/<arch>/<name>/` and pick a branch whose files
   end in `.ipk` for an `opkg` build (`.apk` for an `apk` build).
3. Read the control metadata before installing — `Conflicts` decides whether a
   package may coexist with what is already there, and a shared `Provides`
   means the installed variant already satisfies the dependency (upgrade *it*;
   installing the sibling swaps the core out from under a running config).
4. Download by direct URL and install, passing every file of one upgrade in a
   single call so the resolver sees them together:
   ```sh
   cd /tmp && mkdir -p pkg && cd pkg
   curl -fsSL -O "<feed-url>/<pkg>_<ver>_<arch>.ipk"
   opkg install ./<pkg>_<ver>_<arch>.ipk
   ```
5. Restart the service and confirm the version — a daemon already running
   keeps the old executable and keeps reporting the old version.

Traps that cost real time:

- **HTTP 200 proves nothing.** Static hosts (GitHub Pages, Cloudflare Pages)
  serve an HTML fallback for paths that do not exist. Check the magic bytes:
  `head -c 8 file.ipk | od -c` should show gzip magic (`\037 \213`), not
  `<!DOCTYPE html>`. HTML here means the URL was built against the wrong
  branch or the wrong naming scheme.
- **The feed may have no `Packages` index.** `opkg update` then reports success
  while having downloaded a 404 page, and `opkg list` keeps showing stale
  versions. Install by direct URL, and read versions from the feed's
  `index.json` when it has one — it is usually fresher than the opkg index.
- **opkg preserves your config.** When a package ships a `conffile` differing
  from the one on disk, opkg leaves yours and writes the new default beside it
  as `<path>-opkg`. Diff the two before concluding the update changed nothing.

The `openwrt` skill holds the full procedure plus a worked example
(`references/third-party-feeds.md`). It is marked `platforms: [linux]`, so it
may not load on Android — this section is the reachable summary.

## Telnet to Network Devices (ONT / Router)

Network devices (optical modems, routers) often expose telnet, not SSH.
The tmux long-connection pattern still applies — one session per device,
send-keys for commands, capture-pane for output.

### Connection and Privilege Escalation

```bash
tmux new -d -s onu                      # empty session
tmux send-keys -t onu "telnet 192.168.1.1" Enter
sleep 4                                  # wait for login prompt
tmux send-keys -t onu "user" Enter; sleep 2
tmux send-keys -t onu "PASSWORD" Enter; sleep 3
# Escalate to root on busybox ash:
tmux send-keys -t onu "login root" Enter; sleep 3
```

On busybox-based ONTs, `login root` can drop to a root shell (`/ #` prompt)
even when `/etc/passwd` is corrupted — the `login` binary falls back to
root regardless of passwd-file validity. The `user` shell is busybox `ash`,
not bash — `id` and `whoami` warn about bad passwd but still work.

### Extracting PPPoE Credentials

The running `pppd` process carries the broadband account and password in
its command line — readable as root:

```bash
ps | grep pppd
# Output: pppd ... user <account> password <password> ...
```

No need to decrypt config files or use `sendcmd` (which may not exist on
all ONT firmware). The password is in plaintext on the pppd cmdline.

### tmux capture-pane Returns Empty on Termux

`tmux capture-pane -t sess -p` may return an empty string to stdout even
when the pane has visible content. Redirect to a file instead:

```bash
tmux capture-pane -t onu -p -S -100 > $HOME/pane.txt
cat $HOME/pane.txt | tail -20
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| SSH connection refused | Enable SSH in machine's control panel |
| Password auth denied | Check if key-based auth is required |
| `command not found` | The tool isn't in PATH; use full path or create symlink |
| Tmux commands hang | TMUX env var is set; use `TMUX="" tmux ...` |
