# GIL-related lag — current status

Historical note. The workarounds below were written against Hermes v0.20.x and are
**no longer needed on a current install**. Kept for context when reading old session
notes.

## What was reported

- Event-loop stalls under the GIL — NousResearch/hermes-agent#58576, **closed**.
- SQLite "database is locked" under the GIL — NousResearch/hermes-agent#57921,
  **closed**.
- The proposed PR #74275 was **closed without merging**; PR #75086 likewise.

## Current guidance

1. **Upgrade rather than patch.** Both reported issues are closed upstream. Running a
   current release is the fix; do not backport the old patches.
2. **`dashboard.turn_isolation` is a real, supported setting** — it is read in
   `tui_gateway/server.py` and used for compute-host dispatch. Earlier notes calling it
   invalid are stale. Enable it only for the compute-host flow it was designed for;
   it is not a general lag switch.
3. **Still open:** NousResearch/hermes-agent#74554 — linux/arm64 Docker images ship
   x86_64 wheels. If a build fails with `Exec format error` inside an ARM64 container,
   that is this issue, not a Termux problem. Prefer the Termux APT package, which
   ships aarch64 wheels.

## If lag appears on a current install

Do not reach for the old workarounds. Capture evidence and report:

```bash
hermes --version
hermes doctor
```

Then file an issue against `NousResearch/hermes-agent` with the version, the device,
and a reproduction. The old incident numbers above are closed and will not be
re-opened for a new report.
