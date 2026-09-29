#!/bin/bash
# Builds MyClicky.app and installs it to ~/Applications.
# Signing: uses the self-signed "MyClicky Dev" certificate from your keychain when it exists, so macOS keeps
# MyClicky's permissions across rebuilds. Without it, it falls back to an ad-hoc signature, and each rebuild silently
# revokes Device Control and Data Access and Input Monitoring. Override with SIGN_IDENTITY="…" ./build.sh.
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
cp Resources/AppIcon.icns "$APP/Contents/Resources/" # app icon (spec 013; ./scripts/make-icon.sh)
if [[ -z "${SIGN_IDENTITY:-}" ]] && security find-identity -v -p codesigning | grep -q '"MyClicky Dev"'; then
    SIGN_IDENTITY="MyClicky Dev"
fi
# Sign the helper first, then the app (the helper is launched by agents and asks for its own approvals).
codesign --force --sign "${SIGN_IDENTITY:--}" "$APP/Contents/MacOS/MyClickyComputer"
codesign --force --sign "${SIGN_IDENTITY:--}" "$APP"
echo "Signed with: ${SIGN_IDENTITY:-ad-hoc}"

if [[ "${1:-}" != "--no-install" ]]; then
    mkdir -p "$HOME/Applications"
    pkill -x MyClicky 2>/dev/null || true
    rm -rf "$HOME/Applications/MyClicky.app"
    cp -R "$APP" "$HOME/Applications/"
    echo "Installed to ~/Applications/MyClicky.app"
fi
