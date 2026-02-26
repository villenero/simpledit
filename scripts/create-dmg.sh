#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DIST="$PROJECT_DIR/dist"
APP="$DIST/MDView.app"
ICONS_SRC="$PROJECT_DIR/MDView/Resources/Assets.xcassets/AppIcon.appiconset"
VERSION="1.0.0"
DMG_NAME="MDView-${VERSION}.dmg"

# --- 1. Compile release build ---
echo "==> Building release..."
swift build -c release
RELEASE_BIN="$(swift build -c release --show-bin-path)"
BUNDLE_NAME="MDView_MDView.bundle"

# --- 2. Generate AppIcon.icns ---
echo "==> Generating AppIcon.icns..."
ICONSET=$(mktemp -d)/AppIcon.iconset
mkdir -p "$ICONSET"

cp "$ICONS_SRC/icon_16x16.png"     "$ICONSET/icon_16x16.png"
cp "$ICONS_SRC/icon_32x32.png"     "$ICONSET/icon_16x16@2x.png"
cp "$ICONS_SRC/icon_32x32.png"     "$ICONSET/icon_32x32.png"
cp "$ICONS_SRC/icon_64x64.png"     "$ICONSET/icon_32x32@2x.png"
cp "$ICONS_SRC/icon_128x128.png"   "$ICONSET/icon_128x128.png"
cp "$ICONS_SRC/icon_256x256.png"   "$ICONSET/icon_128x128@2x.png"
cp "$ICONS_SRC/icon_256x256.png"   "$ICONSET/icon_256x256.png"
cp "$ICONS_SRC/icon_512x512.png"   "$ICONSET/icon_256x256@2x.png"
cp "$ICONS_SRC/icon_512x512.png"   "$ICONSET/icon_512x512.png"
cp "$ICONS_SRC/icon_1024x1024.png" "$ICONSET/icon_512x512@2x.png"

ICNS="$DIST/AppIcon.icns"
iconutil -c icns -o "$ICNS" "$ICONSET"
rm -rf "$(dirname "$ICONSET")"

# --- 3. Build .app bundle ---
echo "==> Creating app bundle..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$RELEASE_BIN/MDView"              "$APP/Contents/MacOS/MDView"
cp "$PROJECT_DIR/MDView/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$ICNS"                                "$APP/Contents/Resources/AppIcon.icns"
cp -R "$RELEASE_BIN/$BUNDLE_NAME"         "$APP/Contents/Resources/$BUNDLE_NAME"

echo "APPL????" > "$APP/Contents/PkgInfo"

# --- 4. Create DMG ---
echo "==> Creating DMG..."
DMG_TEMP="$DIST/MDView-temp.dmg"
DMG_FINAL="$DIST/$DMG_NAME"
rm -f "$DMG_TEMP" "$DMG_FINAL"

hdiutil create -size 100m -fs HFS+ -volname "MDView" "$DMG_TEMP"
MOUNT_DIR=$(hdiutil attach -readwrite -noverify "$DMG_TEMP" | grep '/Volumes/' | awk '{print $NF}')

cp -R "$APP" "$MOUNT_DIR/"
ln -s /Applications "$MOUNT_DIR/Applications"

hdiutil detach "$MOUNT_DIR"
hdiutil convert "$DMG_TEMP" -format UDZO -o "$DMG_FINAL"
rm -f "$DMG_TEMP"

echo "==> Done: $DMG_FINAL"
