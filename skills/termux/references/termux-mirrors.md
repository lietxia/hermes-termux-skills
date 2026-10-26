# Termux Mirror / Source Switching

Termux's default apt mirrors sit overseas, so large downloads time out —
`chromium` is 215 MB and will not finish on the default mirror. Switch to a
Chinese mirror first, then install.

## chsrc (recommended)

`chsrc` benchmarks every mirror and switches to the fastest. It is
cross-platform (apt / pip / npm / …) and needs no root.

```bash
# Termux has no wget — use curl. ARM64 Android build:
curl -L https://gitee.com/RubyMetric/chsrc/releases/download/pre/chsrc-arm64-android -o ~/chsrc
chmod +x ~/chsrc
~/chsrc --version

# Switch Termux's apt source (auto-benchmarks, picks fastest)
~/chsrc set termux
```

`chsrc set termux` also runs `apt-get update` and `apt-get upgrade`. The
upgrade is interactive and prompts `Do you want to continue? [Y/n]`. If chsrc
aborts there, finish it by hand:

```bash
apt-get upgrade -y
```

Re-run any install that timed out afterwards — the speed difference is large
(chromium went from timing out repeatedly to completing in minutes).

## Manual mirror edit (no chsrc)

```bash
# Tsinghua mirror
sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main stable main@' \
  $PREFIX/etc/apt/sources.list
apt update && apt upgrade
```

Apply the same substitution to `$PREFIX/etc/apt/sources.list.d/*.list`
(x11-repo, root-repo, …) — those are separate files and are not covered by the
edit above.

## Notes

- `pkg` is a wrapper over apt; switching the apt source fixes both.
- chsrc binaries are per-platform: `chsrc-arm64-android` for Termux,
  `chsrc-x64-linux` / `.deb` for glibc Linux, `chsrc-arm64-macos` for macOS.
- If a mirror goes bad mid-download, re-run `~/chsrc set termux` to re-pick.
