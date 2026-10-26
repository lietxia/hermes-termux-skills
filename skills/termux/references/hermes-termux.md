
# Hermes on Termux

## Runtime: Python 3.14, PM-managed

Hermes runs **only on Python 3.14**. `pyproject.toml` declares
`requires-python = ">=3.11,<3.15"`, but every runtime dependency carries a
`python_version >= '3.14'` marker. On 3.11–3.13 an install therefore resolves
to **zero dependencies** and the package does not import. The wide range exists
for exactly one reason: a venv created before the PM migration must be able to
check out the new code and run `hermes update` once.

PM (the package manager) owns both the interpreter and the venv:

- interpreter: `~/.hermes/tools/python-<ver>-linux-arm64-bionic/` — on Termux
  this is the official repo's `.deb`, unpacked (`python_3.14.6-1_aarch64.deb`),
  not a python-build-standalone glibc build
- venv: `~/.hermes/installs/<install-id>/environments/<env-id>/venv`
- active environment: `~/.hermes/installs/<install-id>/facts.json` →
  `packages.venv.environment`
- `$PREFIX/bin/hermes` is a launcher whose shebang points at that venv

Do not hand-build a venv and do not install `psutil` from PyPI — PM resolves
both from `pm/lock.json`.

## Install

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

The Termux APT channel documented at
`hermes-agent.nousresearch.com/docs/getting-started/termux` currently 404s on
both `key.asc` and `Packages` (the docs themselves say "Termux is currently
broken"). Source checkout + PM is the working path.

## Update (source install)

`hermes update` refuses on a Termux source checkout:

> ✗ This Hermes is a source checkout running under Termux.
> Source installs are not supported on Termux — `hermes update` would
> build Python packages on the device.

Two independent platform gaps have to be bridged before it will run here, and
one wrapper fixes both: `~/.local/bin/hermes-update-termux` (template:
`templates/hermes-update-termux.sh`). It edits no Hermes source file, so
`git pull` can never conflict with it.

### Gap 1 — the admission guard

`hermes_cli/update_contract.py::evaluate_update_admission()` asks
`hermes_platform.host.runtime.is_termux()`, which reads exactly two environment
variables:

```python
prefix = os.getenv("PREFIX", "")
return bool(os.getenv("TERMUX_VERSION") or "com.termux/files/usr" in prefix)
```

Hiding both is sufficient. `PREFIX` is read in that one place across the whole
tree, so git / PM / node / npm / uv are unaffected.

### Gap 2 — `os.link` does not exist

Termux's CPython is built without `HAVE_LINK`, so the attribute is simply
absent. `hermes_cli/update_lock.py::_publish_exclusive()` already falls back to
an exclusive `O_CREAT|O_EXCL` create when a hard link is unavailable — but that
fallback is reached only on `OSError`, while a missing attribute raises
`AttributeError`. Defining `os.link` to raise `OSError` routes the lock through
its own supported fallback.

### Why the shim must be installed in several places

This is the part that costs the afternoon. `hermes_bootstrap` re-execs into
PM's interpreter with `os.execv` (environment inherited), and immediately
before that PM's `activate_dependencies()` **overwrites**
`os.environ["PYTHONPATH"]` with `"<project_root>:<venv site-packages>"`. A shim
delivered only through `PYTHONPATH` is dropped exactly when the re-exec'd child
needs it. `PYTHONPATH` also sits on Hermes' own `_ENV_VAR_NAME_DENYLIST`, so
env-sanitising subprocess code strips it as well.

Install the shim where `site` still finds it after all that:

| Path | Covers |
|------|--------|
| `~/hermes-agent/sitecustomize.py` | children PM puts `project_root` on PYTHONPATH for. Untracked, so `git pull` leaves it alone |
| `<env>/venv/lib/python3.14/site-packages/sitecustomize.py` | the venv's own python even under a fully sanitized env — a real site dir is always processed |
| `~/.local/lib/python3.14/site-packages/usercustomize.py` | PM's tools python, which runs with user-site enabled (the venv python runs with it disabled) |

Then run the update with the markers hidden:

```bash
exec env -u TERMUX_VERSION PREFIX=/usr \
  PYTHONPATH="$SHIM_DIR${PYTHONPATH:+:$PYTHONPATH}" \
  hermes update "$@"
```

Use `--check` or `--plan` first (both read-only), then
`--yes --no-gateway-restart` so the update does not kill the session that
launched it; restart the gateway yourself afterwards.

The post-swap `completion` follow-up runs in a fresh, env-sanitized process. If
that is the only step still reporting `module 'os' has no attribute 'link'`,
the venv-site-packages copy of the shim is the one missing.

### Fallback: drive PM by hand

If the wrapper is unavailable, the same result comes from PM directly:

```bash
cd ~/hermes-agent
git pull --ff-only origin main

# PM refuses to sync until its managed tools are on PATH
PMPATH=$(./hermes pm env | python3 -c "import json,sys; print(json.load(sys.stdin)['PATH'])")
PATH="$PMPATH:$PATH" ./hermes pm install --tools-only

# then the venv sync
PATH="$PMPATH:$PATH" UV_HTTP_TIMEOUT=600 UV_CONCURRENT_DOWNLOADS=4 \
  ./hermes pm install --extra all
```

`pm install --tools-only` also repairs a broken tool (a stale ffmpeg that fails
with `library "libavdevice.so.62" not found` is fixed by this step alone).

After the sync, read the new environment id from `facts.json` and repoint the
launchers — `hermes`, `hermes-acp`, and `hermes-agent` all need it:

```bash
# each launcher: shebang → <env>/venv/bin/python, then sys.path.insert of the checkout
#!<env>/venv/bin/python
import sys
sys.path.insert(0, "/data/data/com.termux/files/home/hermes-agent")
from hermes_cli.main import main          # hermes-acp: acp_adapter.entry; hermes-agent: run_agent
if __name__ == '__main__':
    sys.argv[0] = sys.argv[0].removesuffix('.exe')
    sys.exit(main())
```

### Post-upgrade cleanup

A successful upgrade can leave stale state that breaks later launches. Clear it
with one command and one deletion.

```bash
# Remove store entries nothing references — old node/python/uv builds and
# dead PM runtime generations
hermes pm gc
```

After a restart PM may stage a *new* environment while the old one is still on
disk. Leftover `~/.hermes/installs/<hash>/` directories that contain only
`pm-runtime/` are dead — `facts.json` names the live one. Delete them:

```bash
ls -1 ~/.hermes/installs/          # the live id is in facts.json
rm -rf ~/.hermes/installs/<dead-hash>
```

**Pitfall — dead install dirs make every launch fail.** PM repairs *every*
install dir, including dead ones. A dead dir triggers `hermes pm repair`, which
fails under Bionic with:

> ImportError: dlopen failed: cannot locate symbol "PyModule_Type" …
> cryptography/hazmat/bindings/_rust.abi3.so

The live environment's cryptography imports fine — only the dead dirs are the
problem. Deleting them stops the failure. Do not read this as "Hermes is
broken"; it is stale install state.

After restarting the gateway, confirm which environment it actually picked up:

```bash
ps aux | grep "hermes gateway run"   # the venv path in the cmdline is the one in use
```

If it still points at the old environment, `$PREFIX/bin/hermes` was not
repointed — the gateway inherits its shebang, not the active environment (see
the launcher block above).

### Network notes

- PyPI direct is slow here. Raise `UV_HTTP_TIMEOUT` (600) and lower
  `UV_CONCURRENT_DOWNLOADS` (4), or the sync dies on
  `operation timed out` fetching a single wheel.
- PM strips index redirects during the frozen sync (the lockfile is
  authoritative), so a mirror configured in `pip.conf` does **not** apply to
  the venv sync. Transport knobs like `UV_HTTP_TIMEOUT` do survive.
- The Android `psutil` dependency is a git source pin, so the sync clones from
  GitHub. That clone can fail with
  `SSL routines::unexpected eof while reading`. Retry, or bridge a mirror with
  `git config --global url."<mirror>/https://github.com/".insteadOf "https://github.com/"`
  — and unset it afterwards, because a dead mirror then breaks every git
  command (including `git pull`).

## Gateway

`hermes gateway restart` cannot run from inside the gateway process (a Feishu
DM, Telegram message, etc.). Run it from a separate shell or tmux.

A restart may spawn a *new* PM environment; re-read `facts.json` and repoint
the launchers if `hermes --version` reports `vunknown` or an unexpected
`Install directory`.

## Escape hatch (unsupported)

`HERMES_DISABLE_LAZY_INSTALLS=1` makes `prepare_launch()` return early and skips
PM's automatic source-update completion on every launch. It is an **internal
bridge var** — the docs say not to set it manually in `.env`. Use it only to
get a shell back when PM's completion step is failing, not as a permanent fix.

## Known Issues

| Issue | Fix |
|-------|-----|
| `hermes update` refused | Run `hermes-update-termux` (see above) |
| TUI text disappears (Xiaomi Android 16, #18390) | Switch to CLI: `display.interface: cli` |
| `psutil` on Android | pyproject pins a git commit (upstream #2891); PM installs it |
| `uvloop`, `nemo-relay` | Excluded on `sys_platform == 'android'` by pyproject markers |
| Stale / out-of-sync tool after upgrade (`ffmpeg libavdevice.so.62`, `node: not installed or outdated`) | `hermes pm install --tools-only` |
