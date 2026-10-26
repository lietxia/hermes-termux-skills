# File Transfer to BusyBox Devices

When you need to get a binary onto an embedded device (router, ONT, IoT) that
runs BusyBox and has no SSH/SCP, and the device cannot reach Termux (different
subnet, no return route), but Termux CAN reach the device.

## Diagnose the Direction

```bash
# From Termux: ping the target
ping -c 2 <target_ip>   # works → Termux → target is open

# On the target (via telnet/tmux): ping Termux
ping -c 2 <termux_ip>   # fails → target → Termux is blocked
```

If target → Termux fails, ALL pull-based transfers (wget, curl, tftp from
target to Termux) will fail. You must push from Termux to the target.

## Method: BusyBox httpd + CGI (RECOMMENDED)

Works on any BusyBox device that has `httpd` (most do). No inetd or tcpsvd
needed — httpd runs as a standalone daemon.

### 1. On the target device (via tmux telnet session)

```sh
# Create a CGI script that receives POST body into a file
mkdir -p /tmp/cgi-bin
cat > /tmp/cgi-bin/up <<'EOF'
#!/bin/sh
cat > /tmp/received_file
echo "Content-Type: text/plain"
echo ""
echo "OK"
EOF
chmod +x /tmp/cgi-bin/up

# Start httpd serving /tmp on a high port
httpd -h /tmp -p 8888
```

### 2. From Termux (push the file)

```bash
curl -X POST http://<target_ip>:8888/cgi-bin/up --data-binary @local_file
# Response: OK → file is now at /tmp/received_file on the target
```

### 3. On the target: chmod and execute

```sh
chmod +x /tmp/received_file
/tmp/received_file
```

## Why other methods fail

| Method | Why it fails |
|--------|-------------|
| wget/curl from target | Target can't reach Termux IP (no route) |
| nc (netcat) | BusyBox `nc -l` is unreliable — exits immediately or drops connection mid-transfer |
| tftp (target pulls) | Same direction issue; also BusyBox `tftpd` needs `udpsvd` wrapper (usually absent) |
| tftp (Termux pushes) | Termux lacks tftp server; `tftpy` Python lib times out (network/route issue) |
| scp | Target has no ssh client or sshd |
| tmpfiles.org / 0x0.st | Target may have no internet access; 0x0.st disabled uploads; tmpfiles rejects extensionless files |
| transfer.sh | Times out on large files or is down |

## Key Insight

The CGI approach works because it uses the **Termux → target direction** (which is
open) and relies only on BusyBox's built-in `httpd` (no extra packages needed).
The CGI script is a 4-line shell script — no compilation, no dependencies.
