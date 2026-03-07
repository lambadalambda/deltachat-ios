#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Configure this repo to run as a local fork (no Xcode clicking).

This script patches:
- DEVELOPMENT_TEAM
- PRODUCT_BUNDLE_IDENTIFIER (app + extensions)
- App Group identifiers in entitlements + Info.plist

Usage:
  scripts/local-fork-setup.sh --team-id ABCDE12345 --bundle-id com.example.deltachat [--app-group-id group.com.example.deltachat] [--display-name "DeltaChat Dev"]

Notes:
- You need a paid Apple Developer Program team for App Groups.
- After this, you can build/install via scripts/run-on-device.sh.
EOF
}

TEAM_ID=""
BUNDLE_ID=""
APP_GROUP_ID=""
DISPLAY_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --team-id)
      TEAM_ID="${2:-}"; shift 2 ;;
    --bundle-id)
      BUNDLE_ID="${2:-}"; shift 2 ;;
    --app-group-id)
      APP_GROUP_ID="${2:-}"; shift 2 ;;
    --display-name)
      DISPLAY_NAME="${2:-}"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$TEAM_ID" || -z "$BUNDLE_ID" ]]; then
  usage
  exit 2
fi

if [[ ! "$TEAM_ID" =~ ^[A-Z0-9]{10}$ ]]; then
  echo "Invalid --team-id '$TEAM_ID' (expected 10 chars A-Z0-9)" >&2
  exit 2
fi

if [[ -z "$APP_GROUP_ID" ]]; then
  APP_GROUP_ID="group.${BUNDLE_ID}"
fi

if [[ ! "$APP_GROUP_ID" =~ ^group\..+ ]]; then
  echo "Invalid --app-group-id '$APP_GROUP_ID' (expected to start with 'group.')" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

IOS_PBXPROJ="$ROOT_DIR/deltachat-ios.xcodeproj/project.pbxproj"
DCCORE_PBXPROJ="$ROOT_DIR/DcCore/DcCore.xcodeproj/project.pbxproj"

ENTITLEMENTS_MAIN="$ROOT_DIR/deltachat-ios/deltachat-ios.entitlements"
ENTITLEMENTS_SHARE="$ROOT_DIR/DcShare/DcShare.entitlements"
ENTITLEMENTS_NSE="$ROOT_DIR/DcNotificationService/DcNotificationService.entitlements"

PLIST_APP="$ROOT_DIR/deltachat-ios/Info.plist"
PLIST_SHARE="$ROOT_DIR/DcShare/Info.plist"
PLIST_NSE="$ROOT_DIR/DcNotificationService/Info.plist"
PLIST_WIDGET="$ROOT_DIR/DcWidget/Info.plist"

python3 - "$TEAM_ID" "$BUNDLE_ID" "$APP_GROUP_ID" \
  "$DISPLAY_NAME" \
  "$IOS_PBXPROJ" "$DCCORE_PBXPROJ" \
  "$PLIST_APP" \
  "$ENTITLEMENTS_MAIN" "$ENTITLEMENTS_SHARE" "$ENTITLEMENTS_NSE" \
  "$PLIST_SHARE" "$PLIST_NSE" "$PLIST_WIDGET" <<'PY'
import re
import sys
from pathlib import Path
from xml.sax.saxutils import escape

team_id = sys.argv[1]
bundle_id = sys.argv[2]
app_group_id = sys.argv[3]
display_name = sys.argv[4]

ios_pbxproj = Path(sys.argv[5])
dccore_pbxproj = Path(sys.argv[6])
plist_app = Path(sys.argv[7])

files_to_patch = [Path(p) for p in sys.argv[8:]]

def patch_file(path: Path, transform):
    original = path.read_text(encoding="utf-8")
    updated = transform(original)
    if updated != original:
        path.write_text(updated, encoding="utf-8")
        print(f"patched {path}")
    else:
        print(f"no changes {path}")

def patch_development_team(text: str) -> str:
    return re.sub(r"\bDEVELOPMENT_TEAM = [A-Z0-9]{10};", f"DEVELOPMENT_TEAM = {team_id};", text)

def patch_ios_bundle_ids(text: str) -> str:
    def repl(m: re.Match) -> str:
        current = m.group(1)
        suffixes = [
            ".DcShare",
            ".DcNotificationService",
            ".DcWidget",
            ".DcTests",
        ]
        for suffix in suffixes:
            if current.endswith(suffix):
                return f"PRODUCT_BUNDLE_IDENTIFIER = {bundle_id}{suffix};"
        return f"PRODUCT_BUNDLE_IDENTIFIER = {bundle_id};"

    return re.sub(r"PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);", repl, text)

def patch_dccore_bundle_id(text: str) -> str:
    return re.sub(r"PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);", f"PRODUCT_BUNDLE_IDENTIFIER = {bundle_id}.DcCore;", text)

def patch_app_group_id(text: str) -> str:
    return text.replace("group.chat.delta.ios", app_group_id)

def patch_bundle_display_name(text: str) -> str:
    if display_name == "":
        return text
    replacement = escape(display_name)
    return re.sub(
        r"(<key>CFBundleDisplayName</key>\s*<string>)(.*?)(</string>)",
        rf"\g<1>{replacement}\3",
        text,
        count=1,
        flags=re.DOTALL,
    )

patch_file(ios_pbxproj, lambda t: patch_ios_bundle_ids(patch_development_team(t)))
patch_file(dccore_pbxproj, lambda t: patch_dccore_bundle_id(patch_development_team(t)))

patch_file(plist_app, lambda t: patch_bundle_display_name(patch_app_group_id(t)))

for file in files_to_patch:
    patch_file(file, patch_app_group_id)
PY

echo
echo "Done. Next: run 'scripts/run-on-device.sh' (after pod install / submodules)."
