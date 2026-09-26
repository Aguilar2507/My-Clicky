#!/bin/bash
# Builds MyClicky.app and installs it to ~/Applications.
# Optional: SIGN_IDENTITY="MyClicky Dev" ./build.sh  (a self-signed certificate keeps
# macOS permissions across rebuilds; the default ad-hoc signature asks again after each rebuild).
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP="build/MyClicky.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/MyClicky "$APP/Contents/MacOS/MyClicky"
cp .build/release/MyClickyComputer "$APP/Contents/MacOS/MyClickyComputer" # agents bridge (spec 009)
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/CHANGELOG.md "$APP/Contents/Resources/"
cp Resources/integrations.json "$APP/Contents/Resources/" # connector catalog (spec 010)
codesign --force --sign "${SIGN_IDENTITY:--}" "$APP"

if [[ "${1:-}" != "--no-install" ]]; then
    mkdir -p "$HOME/Applications"
    pkill -x MyClicky 2>/dev/null || true
    rm -rf "$HOME/Applications/MyClicky.app"
    cp -R "$APP" "$HOME/Applications/"
    echo "Installed to ~/Applications/MyClicky.app"
fi
