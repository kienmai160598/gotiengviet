#!/usr/bin/env bash
# Builds VietKey (Release) and installs it as a user input method.
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="Release"
[[ "${1:-}" == "--debug" ]] && CONFIG="Debug"   # Debug builds include the keystroke trace

xcodegen generate --quiet
xcodebuild -project VietKey.xcodeproj -scheme VietKeyMac -configuration "$CONFIG" \
  -derivedDataPath .build/xcode -quiet build

DEST="$HOME/Library/Input Methods"
mkdir -p "$DEST"
pkill -x VietKey || true            # the running server must restart to load the new build
rm -rf "$DEST/VietKey.app"
cp -R ".build/xcode/Build/Products/$CONFIG/VietKey.app" "$DEST/"
echo "Installed $CONFIG build to $DEST/VietKey.app"
echo "First time: System Settings > Keyboard > Input Sources > Edit > + > Vietnamese > VietKey"
