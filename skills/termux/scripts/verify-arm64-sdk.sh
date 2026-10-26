#!/bin/bash
# Verify that the Android SDK native binaries are ARM64, not x86_64.
#
# Google ships x86_64 build-tools and platform-tools. On an aarch64 Termux host they
# fail with "Exec format error", so they must be replaced with Bionic-linked ARM64
# builds (see references/android-sdk-setup.md).
#
# Usage:   bash verify-arm64-sdk.sh [ANDROID_HOME]
# Exit:    0 = every ELF binary is AArch64
#          1 = at least one x86_64 binary found (needs replacement)
#          2 = usage error

set -u

ANDROID_HOME="${1:-${ANDROID_HOME:-$HOME/android-sdk}}"

if [ ! -d "$ANDROID_HOME" ]; then
    echo "SDK directory not found: $ANDROID_HOME" >&2
    echo "Pass a path: bash verify-arm64-sdk.sh /path/to/android-sdk" >&2
    exit 2
fi

ERRORS=0
CHECKED=0

echo "=== Verifying ARM64 binaries in $ANDROID_HOME ==="

check_binary() {
    local path="$1"
    local name
    name=$(basename "$path")

    if [ ! -f "$path" ]; then
        echo "  --  $name  (not present)"
        return
    fi

    if ! readelf -h "$path" >/dev/null 2>&1; then
        echo "  ok  $name  (not an ELF binary)"
        return
    fi

    CHECKED=$((CHECKED + 1))

    # "Machine:" is followed by the architecture name; x86_64 reads
    # "Advanced Micro Devices X86-64", aarch64 reads "AArch64".
    local machine
    machine=$(readelf -h "$path" 2>/dev/null | awk -F: '/Machine:/{print $2}' | awk '{print $1}')

    case "$machine" in
        AArch64) echo "  ok  $name  (ARM64)" ;;
        Advanced) echo "  XX  $name  (x86_64 - NEEDS REPLACEMENT)"
                  ERRORS=$((ERRORS + 1)) ;;
        *)       echo "  ??  $name  (unknown arch: $machine)" ;;
    esac
}

for bt_dir in "$ANDROID_HOME"/build-tools/*/; do
    [ -d "$bt_dir" ] || continue
    echo ""
    echo "--- build-tools $(basename "$bt_dir") ---"
    for tool in aapt2 aidl zipalign split-select dexdump; do
        check_binary "$bt_dir/$tool"
    done
done

echo ""
echo "--- platform-tools ---"
for tool in adb; do
    check_binary "$ANDROID_HOME/platform-tools/$tool"
done

echo ""
if [ "$ERRORS" -gt 0 ]; then
    echo "Found $ERRORS x86_64 binary(ies) across $CHECKED ELF binaries checked."
    echo "Replace them: https://github.com/lzhiyong/android-sdk-tools/releases"
    exit 1
fi

echo "All $CHECKED ELF binaries are ARM64. Ready to build."
exit 0
