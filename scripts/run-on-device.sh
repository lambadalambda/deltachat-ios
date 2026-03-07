#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Build, install, and launch deltachat-ios on a physical iPhone/iPad.

Usage:
  scripts/run-on-device.sh [--device <name|udid|identifier>] [--configuration Debug|Release]

Tips:
- If you omit --device and exactly one iOS device is paired, it will be used.
- Requires Xcode command line tools, CocoaPods (`pod install`), and the core submodule.
EOF
}

DEVICE=""
CONFIGURATION="Debug"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)
      DEVICE="${2:-}"; shift 2 ;;
    --configuration)
      CONFIGURATION="${2:-}"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -d "deltachat-ios.xcworkspace" ]]; then
  echo "Missing deltachat-ios.xcworkspace. Did you run 'pod install'?" >&2
  exit 1
fi

if [[ ! -f "Pods/Manifest.lock" ]]; then
  echo "Missing Pods/Manifest.lock. Run: pod install" >&2
  exit 1
fi

if [[ ! -f "deltachat-ios/libraries/deltachat-core-rust/deltachat-ffi/Cargo.toml" ]]; then
  echo "Missing core submodule. Run: git submodule update --init --recursive" >&2
  exit 1
fi

if [[ -z "$DEVICE" ]]; then
  tmp_json="$(mktemp)"
  xcrun devicectl list devices --json-output "$tmp_json" --quiet >/dev/null
  DEVICE="$(python3 - "$tmp_json" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
devices = data.get("result", {}).get("devices", [])

ios_devices = []
for d in devices:
    hp = d.get("hardwareProperties", {})
    dp = d.get("deviceProperties", {})
    platform = hp.get("platform")
    reality = hp.get("reality")
    if reality != "physical":
        continue
    if platform not in ("iOS", "iPadOS"):
        continue
    ios_devices.append({
        "name": dp.get("name") or "(unknown)",
        "udid": hp.get("udid"),
        "identifier": d.get("identifier"),
        "developerModeStatus": dp.get("developerModeStatus"),
    })

ios_devices = [d for d in ios_devices if d.get("udid") or d.get("identifier")]
if len(ios_devices) == 1:
    print(ios_devices[0].get("udid") or ios_devices[0].get("identifier"))
    raise SystemExit(0)

print("", end="")
PY
)"

  if [[ -z "$DEVICE" ]]; then
    echo "Could not auto-select a single iOS device. Available devices:" >&2
    xcrun devicectl list devices --columns "deviceProperties.name" --columns "hardwareProperties.platform" --columns "hardwareProperties.udid" --quiet || true
    echo >&2
    echo "Re-run with: scripts/run-on-device.sh --device '<udid-or-name>'" >&2
    exit 1
  fi
fi

echo "Building ($CONFIGURATION) ..."
xcodebuild \
  -workspace "deltachat-ios.xcworkspace" \
  -scheme "deltachat-ios" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=iOS" \
  -derivedDataPath "DerivedData" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  build

APP_DIR="DerivedData/Build/Products/${CONFIGURATION}-iphoneos"

shopt -s nullglob
apps=("$APP_DIR"/*.app)
shopt -u nullglob

if [[ ${#apps[@]} -ne 1 ]]; then
  echo "Expected exactly one .app in $APP_DIR but found ${#apps[@]}" >&2
  ls -la "$APP_DIR" >&2 || true
  exit 1
fi

APP_PATH="${apps[0]}"
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print:CFBundleIdentifier' "$APP_PATH/Info.plist")"

echo "Installing $BUNDLE_ID to device: $DEVICE"
xcrun devicectl device install app --device "$DEVICE" "$APP_PATH"

echo "Launching ..."
xcrun devicectl device process launch --device "$DEVICE" --terminate-existing "$BUNDLE_ID"

echo "Done."
