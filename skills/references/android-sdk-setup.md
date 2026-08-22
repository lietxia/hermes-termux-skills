# Android SDK Setup on Termux

## JDK Installation

```bash
# AGP 8.x
pkg install -y openjdk-17

# AGP 9.x
pkg install -y openjdk-21

# Set JAVA_HOME (add to ~/.bashrc)
export JAVA_HOME=/data/data/com.termux/files/usr/lib/jvm/java-21-openjdk
export PATH="$JAVA_HOME/bin:$PATH"
```

## SDK Command-Line Tools

```bash
ANDROID_HOME="$HOME/android-sdk"
mkdir -p "$ANDROID_HOME/cmdline-tools"
curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" -o ~/cmdline-tools.zip
unzip -o ~/cmdline-tools.zip -d "$ANDROID_HOME/cmdline-tools/"
mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"

# Accept licenses
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses

# Install components
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platforms;android-35" "build-tools;35.0.1"
```

## ARM64 Binary Replacement (CRITICAL)

Google's SDK only ships x86_64 binaries. Replace with lzhiyong's ARM64 builds:

```bash
curl -fsSL "https://github.com/lzhiyong/android-sdk-tools/releases/download/35.0.2/android-sdk-tools-static-aarch64.zip" -o ~/lzhiyong-aarch64.zip
unzip -o ~/lzhiyong-aarch64.zip -d ~/lzhiyong-tools

for ver in $ANDROID_HOME/build-tools/*/; do
  cp ~/lzhiyong-tools/build-tools/{aapt2,aidl,zipalign} "$ver/"
  chmod +x "$ver"/{aapt2,aidl,zipalign}
done
cp ~/lzhiyong-tools/platform-tools/adb "$ANDROID_HOME/platform-tools/adb"
```

## AAPT2 Override

AGP downloads its own x86_64 aapt2 from Maven. Override in `gradle.properties`:

```properties
android.aapt2FromMavenOverride=/data/data/com.termux/files/home/android-sdk/build-tools/35.0.1/aapt2
```

## local.properties

```bash
echo "sdk.dir=$ANDROID_HOME" > android/local.properties
```