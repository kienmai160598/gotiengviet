#!/usr/bin/env bash
# Builds VietKey (Release) and packs it as .build/VietKey.zip, the asset install.sh downloads.
# Always builds Release here: Debug builds log keystrokes and must never be published.
# Publish: gh release create v<version> .build/VietKey.zip   (push main first, so the tag is on it)
set -euo pipefail
cd "$(dirname "$0")/.."

Tools/build-grammar.sh
xcodegen generate --quiet
xcodebuild -project VietKey.xcodeproj -scheme VietKeyMac -configuration Release \
  -derivedDataPath .build/xcode -quiet build

APP=".build/xcode/Build/Products/Release/VietKey.app"
ZIP=".build/VietKey.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"   # ditto keeps the signature and symlinks intact

# Check the zip as install.sh will see it.
CHECK="$(mktemp -d)"
trap 'rm -rf "$CHECK"' EXIT
ditto -x -k "$ZIP" "$CHECK"
codesign --verify --deep --strict "$CHECK/VietKey.app"

echo "Packed $ZIP ($(du -h "$ZIP" | cut -f1)), version $(defaults read "$PWD/$APP/Contents/Info.plist" CFBundleShortVersionString)"
