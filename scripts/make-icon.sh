#!/bin/bash
# Renders the app logo (Sources/MyClicky/DesignSystem/Brand.swift → AppLogo) into Resources/AppIcon.icns (spec 013).
# Run after changing the logo: ./scripts/make-icon.sh
set -euo pipefail
cd "$(dirname "$0")/.."

swift build
WORK="$(mktemp -d)"
.build/debug/MyClicky --snapshot app-icon "$WORK/icon-1024.png"
SET="$WORK/AppIcon.iconset"
mkdir -p "$SET"
for size in 16 32 128 256 512; do
    sips -z $size $size "$WORK/icon-1024.png" --out "$SET/icon_${size}x${size}.png" >/dev/null
    sips -z $((size * 2)) $((size * 2)) "$WORK/icon-1024.png" --out "$SET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$SET" -o Resources/AppIcon.icns
rm -rf "$WORK"
echo "Wrote Resources/AppIcon.icns"
