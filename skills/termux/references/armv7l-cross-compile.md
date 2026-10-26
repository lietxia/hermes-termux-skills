# Cross-Compiling armv7l Static Binaries on Termux

For embedded devices (routers, ONTs, IoT) running armv7l Linux when the
target itself has no compiler and you need to build exploit/tool binaries locally.

## When to Use

- Target device is armv7l (check with `uname -m` on the device)
- Device has no `gcc`/`cc` (common in BusyBox-based firmware)
- You need to transfer a compiled binary to the device

## Toolchain

Use the NDK clang (NOT Termux's clang, which only ships aarch64 runtime):

```bash
# Path to NDK clang (adjust version as needed)
NDK=~/android-sdk/ndk/<version>/toolchains/llvm/prebuilt/linux-x86_64/bin

# Compile static armv7l binary
$NDK/clang --target=armv7a-linux-androideabi21 -static -O2 \
    -o output_binary source.c
```

## Key Details

| Parameter | Value | Why |
|-----------|-------|-----|
| `--target` | `armv7a-linux-androideabi21` | API 21 covers all armv7l devices |
| `-static` | required | Device likely has no compatible libc |
| `-O2` | recommended | Smaller binary, faster execution |

## VFP/NEON "Illegal instruction" — the critical pitfall

Many embedded ARM devices (routers, ONTs, IoT) have CPUs **without VFP/NEON**.
Check the target:
```bash
# On the target device:
cat /proc/cpuinfo | grep Features
# If 'vfp' and 'neon' are MISSING from Features → no hardware float
```

Android NDK bionic libc's init code uses VFP instructions even when the program
itself does no floating-point math. A `-static` binary linked against bionic
will crash with **"Illegal instruction"** on a no-VFP CPU.

### Fix: compile with -nostdlib and raw syscalls

Write the program using only inline-assembly syscall wrappers — no libc at all.
This produces a tiny (~2KB) binary with zero VFP instructions.

```c
// ARM EABI syscall wrapper template (no libc dependency)
static long syscall3(long nr, long a1, long a2, long a3) {
    register long r7 __asm__("r7") = nr;
    register long r0 __asm__("r0") = a1;
    register long r1 __asm__("r1") = a2;
    register long r2 __asm__("r2") = a3;
    __asm__ volatile("svc 0" : "=r"(r0)
        : "r"(r7), "r"(r0), "r"(r1), "r"(r2) : "memory");
    return r0;
}
// 6-arg variant (for splice, etc.): add r4, r5 registers
static long syscall6(long nr, long a1, long a2, long a3,
                     long a4, long a5, long a6) {
    register long r7 __asm__("r7") = nr;
    register long r0 __asm__("r0") = a1;
    register long r1 __asm__("r1") = a2;
    register long r2 __asm__("r2") = a3;
    register long r3 __asm__("r3") = a4;
    register long r4 __asm__("r4") = a5;
    register long r5 __asm__("r5") = a6;
    __asm__ volatile("svc 0" : "=r"(r0)
        : "r"(r7), "r"(r0), "r"(r1), "r"(r2),
          "r"(r3), "r"(r4), "r"(r5) : "memory");
    return r0;
}
void _start(void) { /* entry point, no libc init */ }
```

Compile:
```bash
$NDK/clang --sysroot=$NDK/sysroot \
    --target=armv5te-none-linux-androideabi21 \
    -nostdlib -static -O2 -mfloat-abi=soft -fno-builtin \
    -o output source.c
```

Key flags: `-nostdlib` (no bionic init), `-mfloat-abi=soft` (no VFP codegen),
`-target armv5te-...` (lowest common denominator ARM), `_start` as entry point.

### Common ARM syscall numbers (Linux EABI)

| Name | Number |
|------|--------|
| read | 3 |
| write | 4 |
| open | 5 |
| close | 6 |
| pipe | 42 |
| fcntl | 55 |
| splice | 340 |
| exit | 1 |

Note: `F_GETPIPE_SZ = 1031` (F_LINUX_SPECIFIC_BASE + 7 = 1024 + 7), NOT 1036.

## File Transfer to BusyBox Devices

When the target device is on a different subnet and **cannot reach Termux**
(ping Termux fails), but Termux CAN reach the target, use BusyBox `httpd` + CGI
as a file receiver on the target.

See [File Transfer to BusyBox Devices](references/file-transfer-to-busybox-devices.md).

## Other Pitfalls

- Termux's own `clang` will fail with linker errors about missing
  `libclang_rt.builtins.a` for armv7a — always use NDK's clang with `--sysroot`
- Termux's `nc` may not exist at `/bin/nc` — use `command -v nc` first
- NDK sysroot at `~/android-sdk/ndk/<ver>/toolchains/llvm/prebuilt/linux-x86_64/sysroot`
  contains headers and static libs for armv7l targets
- BusyBox `nc -l` is unreliable for file transfer — use `httpd`+CGI instead
- BusyBox `tftp`/`ftpd` need `udpsvd`/`tcpsvd` wrappers (usually absent) —
  do not start `tftpd` or `ftpd` directly, they exit immediately
- `transfer.sh` and `0x0.st` may reject or disable uploads — `tmpfiles.org`
  works but rejects extensionless files (rename to `.bin` first)
