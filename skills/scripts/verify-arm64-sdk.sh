#!/bin/bash
# Verify all Android SDK native binaries are ARM64 (not x86_64)
# Usage: bash verify-arm64-sdk.sh [ANDROID_HOME]
# Returns exit 0 if all ARM64, exit 1 if any x86_64 found

ANDROID_HOME="${1:-$HOME/android-sdk}"
ERRORS=0

echo "=== Verifying ARM64 binaries in $ANDROID_HOME ==="

check_binary() {
    local path="$1"
    local name=$(basename "$path")
    
    if [ ! -f "$path" ]; then
        echo "  ⚠️  $name — not found"
        return
    fi
    
    # Check if it's an ELF binary
    if ! readelf -h "$path" >/dev/null 2>&1; then
        echo "  ℹ️  $name — not an ELF binary (ok)"
        return
    fi
    
    local machine=$(readelf -h "$path" 2>/dev/null | grep "Machine:" | awk '{print $2}')
    
    if [ "$machine" = "AArch64" ]; then
        echo "  ✅ $name — ARM64"
    elif [ "$machine" = "Advanced" ]; then
        echo "  ❌ $name — x86_64 (NEEDS REPLACEMENT)"
        ERRORS=$((ERRORS + 1))
    else
        echo "  ⚠️  $name — unknown arch: $machine"
    fi
}

# Check build-tools
for bt_dir in "$ANDROID_HOME"/build-tools/*/; do
    if [ -d "$bt_dir" ]; then
        version=$(basename "$bt_dir")
        echo ""
        echo "--- build-tools $version ---"
        for tool in aapt2 aidl zipalign split-select dexdump; do
            check_binary "$bt_dir/$tool"
        done
    fi
done

# Check platform-tools
echo ""
echo "--- platform-tools ---"
for tool in adb; do
    check_binary "$ANDROID_HOME/platform-tools/$tool"
done

echo ""
if [ $ERRORS -gt 0 ]; then
    echo "❌ Found $ERRORS x86_64 binary(ies). Replace with lzhiyong ARM64 tools."
    echo "   Download: https://github.com/lzhiyong/android-sdk-tools/releases"
    exit 1
else
    echo "✅ All native binaries are ARM64. Ready to build!"
    exit 0
fi
