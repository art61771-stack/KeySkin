#!/bin/bash
# Requires macOS/Xcode and an already booted disposable simulator.
# CI provisions and cleans up its own simulator. Does not build the package.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${KS_SIMULATOR_UDID:?Set KS_SIMULATOR_UDID to a booted disposable iOS simulator UDID}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
APP="$WORK/KeySkinPrefsTest.app"
mkdir -p "$APP"
SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
ARCH="$(uname -m)"
cat > "$APP/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.keyskin.prefs-uikit-test</string>
<key>CFBundleExecutable</key><string>KeySkinPrefsTest</string>
<key>CFBundleName</key><string>KeySkinPrefsTest</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1</string>
<key>MinimumOSVersion</key><string>16.0</string>
<key>UIDeviceFamily</key><array><integer>1</integer><integer>2</integer></array>
<key>UILaunchScreen</key><dict/>
</dict></plist>
PLIST
xcrun --sdk iphonesimulator clang++ -x objective-c++ -std=c++17 -Wall -Wextra -Werror -fobjc-arc \
  -target "$ARCH-apple-ios16.0-simulator" -isysroot "$SDK" \
  -framework UIKit -framework Foundation -framework CoreFoundation \
  -framework CoreGraphics -framework ImageIO \
  "$ROOT/tests/prefs_uikit.mm" -o "$APP/KeySkinPrefsTest"
codesign --force --sign - "$APP"
xcrun simctl install "$KS_SIMULATOR_UDID" "$APP"
DATA="$(xcrun simctl get_app_container "$KS_SIMULATOR_UDID" com.keyskin.prefs-uikit-test data)"
rm -f "$DATA/Documents/result.txt"
xcrun simctl launch --terminate-running-process "$KS_SIMULATOR_UDID" com.keyskin.prefs-uikit-test
for ((attempt=0; attempt<90; attempt++)); do
  if [[ -f "$DATA/Documents/result.txt" ]]; then
    cat "$DATA/Documents/result.txt"
    grep -q '^PASS:' "$DATA/Documents/result.txt"
    exit $?
  fi
  sleep 1
done
echo 'FAIL: simulator harness timeout (no result file)' >&2
exit 1
