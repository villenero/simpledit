#!/usr/bin/env bash
set -euo pipefail

#
# Creates a styled DMG installer for MDView.
# Expects the .app bundle to already exist at dist/MDView.app (run `make app` first).
#

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DIST="$PROJECT_DIR/dist"
APP="$DIST/MDView.app"
VERSION="1.0.0"
DMG_NAME="MDView-${VERSION}.dmg"
DMG_TEMP="$DIST/MDView-temp.dmg"
DMG_FINAL="$DIST/$DMG_NAME"
VOL_NAME="MDView"
BG_IMAGE="$DIST/dmg-bg.png"

WIN_W=540
WIN_H=400

# --- Verify .app exists ---
if [[ ! -d "$APP" ]]; then
    echo "error: $APP not found. Run 'make app' first." >&2
    exit 1
fi

# --- Detach any leftover mounts from previous runs ---
hdiutil detach "/Volumes/$VOL_NAME" 2>/dev/null || true

# --- 1. Generate background image ---
echo "==> Generating DMG background..."
swift "$SCRIPT_DIR/generate-dmg-bg.swift" "$BG_IMAGE" "$WIN_W" "$WIN_H"

# --- 2. Create writable DMG ---
echo "==> Creating DMG..."
rm -f "$DMG_TEMP" "$DMG_FINAL"
hdiutil create -size 100m -fs HFS+ -volname "$VOL_NAME" "$DMG_TEMP" -quiet

# Parse mount point — handle volume names with spaces
MOUNT_DIR=$(hdiutil attach -readwrite -noverify "$DMG_TEMP" | sed -n 's|.*\(/Volumes/.*\)|\1|p' | head -1)
echo "    Mounted at $MOUNT_DIR"

# --- 3. Copy contents ---
cp -R "$APP" "$MOUNT_DIR/"
ln -s /Applications "$MOUNT_DIR/Applications"
mkdir -p "$MOUNT_DIR/.background"
cp "$BG_IMAGE" "$MOUNT_DIR/.background/bg.png"

# --- 4. Configure Finder window via AppleScript ---
echo "==> Configuring DMG layout..."
LEFT=200
TOP=120
RIGHT=$((LEFT + WIN_W))
BOTTOM=$((TOP + WIN_H))

osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "${VOL_NAME}"
        open
        delay 1

        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {${LEFT}, ${TOP}, ${RIGHT}, ${BOTTOM}}

        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 128

        delay 1
        set background picture of theViewOptions to file ".background:bg.png"

        -- Position icons: app on left, Applications on right
        set position of item "MDView.app" of container window to {135, 185}
        set position of item "Applications" of container window to {405, 185}

        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

# --- 5. Finalize DMG ---
echo "==> Finalizing..."
chmod -Rf go-w "$MOUNT_DIR" 2>/dev/null || true
sync
hdiutil detach "$MOUNT_DIR" -quiet
hdiutil convert "$DMG_TEMP" -format UDZO -o "$DMG_FINAL" -quiet
rm -f "$DMG_TEMP" "$BG_IMAGE"

SIZE=$(du -h "$DMG_FINAL" | awk '{print $1}')
echo "==> Done: $DMG_FINAL ($SIZE)"
