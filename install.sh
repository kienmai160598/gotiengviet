#!/usr/bin/env bash
# Installs or updates the VietKey input method for this user from the latest GitHub Release.
#   curl -fsSL https://raw.githubusercontent.com/kienmai160598/gotiengviet/main/install.sh | bash
# Uninstall: bash install.sh --uninstall (or the same curl line piped to `bash -s -- --uninstall`).
# VIETKEY_ZIP_URL overrides the download, e.g. file:///tmp/VietKey.zip for testing.
set -euo pipefail

# Everything runs from main, so a download cut off halfway runs nothing.
main() {
  local zip_url="${VIETKEY_ZIP_URL:-https://github.com/kienmai160598/gotiengviet/releases/latest/download/VietKey.zip}"
  local dest="$HOME/Library/Input Methods"
  local app="$dest/VietKey.app"

  if [[ "${1:-}" == "--uninstall" ]]; then
    pkill -x VietKey || true
    rm -rf "$app"
    echo "Removed $app. Also remove VietKey in System Settings > Keyboard > Input Sources."
    return
  fi

  check_mac

  WORK="$(mktemp -d)"                 # global: the EXIT trap runs after main has returned
  trap 'rm -rf "$WORK"' EXIT

  echo "Downloading $zip_url"
  curl -fL --progress-bar "$zip_url" -o "$WORK/VietKey.zip"
  ditto -x -k "$WORK/VietKey.zip" "$WORK/unzipped"
  if ! codesign --verify --deep --strict "$WORK/unzipped/VietKey.app"; then
    echo "The downloaded VietKey.app failed its signature check; nothing was installed." >&2
    exit 1
  fi

  mkdir -p "$dest"
  pkill -x VietKey || true            # the running input method must restart to load the new build
  rm -rf "$app"
  ditto "$WORK/unzipped/VietKey.app" "$app"
  xattr -dr com.apple.quarantine "$app" 2>/dev/null || true

  echo "Installed VietKey $(defaults read "$app/Contents/Info.plist" CFBundleShortVersionString) to $app"
  echo "First install only: System Settings > Keyboard > Input Sources > Edit > + > Vietnamese > VietKey"
  echo "(log out and back in if VietKey is not in the list yet)."
}

check_mac() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "VietKey for Mac installs on macOS only." >&2
    exit 1
  fi
  if [[ "$(uname -m)" != "arm64" ]]; then
    echo "VietKey needs an Apple Silicon Mac (this one is $(uname -m))." >&2
    exit 1
  fi
  local major
  major="$(sw_vers -productVersion | cut -d. -f1)"
  if (( major < 26 )); then
    echo "VietKey needs macOS 26 or later (this Mac has $(sw_vers -productVersion))." >&2
    exit 1
  fi
}

main "$@"
