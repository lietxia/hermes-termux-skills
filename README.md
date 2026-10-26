# Hermes Termux Skills

Hermes Agent skills for Termux / Android on ARM64.

## Skills

### termux

Termux/Android pitfalls, SDK, and Hermes setup on ARM64. Covers the APT install,
Python platform gating, the Android SDK/NDK toolchain, Gradle/AGP, and the vTerm/Haven
build.

## Install

```bash
git clone https://github.com/lietxia/hermes-termux-skills.git
cp -r hermes-termux-skills/skills/termux ~/.hermes/skills/
```

## Layout

```
skills/termux/
├── SKILL.md                 # always-on rules + quick reference
├── references/              # topic depth, linked from SKILL.md
└── scripts/
    └── verify-arm64-sdk.sh  # audit SDK binary architectures
```

## References

| File | Topic |
|------|-------|
| `hermes-termux.md` | APT install, file layout, updates, limits |
| `termux-pitfalls.md` | Known-issue status table |
| `termux-environment.md` | apt/pkg, env vars, search tools, tmux |
| `android-sdk-setup.md` | ARM64 build-tools, aapt2, adb, cmake |
| `ndk-setup.md` | termux-ndk, version symlink, CMake/Ninja |
| `android-build.md` | JDK, gradle.properties, AGP/Kotlin/KSP matrix |
| `termux-android-build-resources.md` | External repo table |
| `native-build-tasks.md` | Disabling Rust/Go/C build tasks |
| `termux-browser-automation.md` | Browser backends compared |
| `termux-software-update.md` | Updating portable `.deb` tools |
| `skillhub-and-news-skills.md` | SkillHub CLI, free news skills |
| `telegram-gateway-setup.md` | Telegram gateway + pairing |
| `hermes-doctor-output.md` | Reading `hermes doctor` |
| `remote-machine-management.md` | SSH over one tmux session per host |
| `gil-stall-fix.md` | GIL lag: current status |
| `haven-vterm-migration.md` | Haven → vTerm case study |
| `haven-build.md` | Haven build configuration |
| `haven-native-modules.md` | Native module strategies |

## Known issues

| Issue | Status | Notes |
|-------|--------|-------|
| Hermes Termux APT package broken upstream | In progress | Official docs carry a banner; a fix is pending |
| `stable` APT channel not published | Open | Only `canary` resolves; use `hermes-canary` |
| `apt`/`pkg` broken on Android 16 | Closed, not planned | Bionic stdio errno bug (termux/termux-app#5077); `LD_PRELOAD` errno shim |
| nettle breaks `apt` | Closed | termux/termux-packages#28411 |
| TUI text disappears (Xiaomi Android 16) | Closed | NousResearch/hermes-agent#18390; use tmux or `display.interface: cli` |
| GIL event-loop stall | Closed | NousResearch/hermes-agent#58576 |
| SQLite locked under GIL | Closed | NousResearch/hermes-agent#57921 |
| linux/arm64 Docker ships x86_64 wheels | Open | NousResearch/hermes-agent#74554 |

## License

MIT
