#!/bin/bash
set -e

APP_NAME="Color Picker"
BUNDLE_ID="com.alec.colorpicker"
EXECUTABLE="color_picker"
BIN_DIR="bin"
APP_DIR="${BIN_DIR}/${APP_NAME}.app"
DMG_NAME="${BIN_DIR}/ColorPicker.dmg"

ODIN="${ODIN:-$HOME/odin/odin}"

echo "Building..."
mkdir -p bin
"${ODIN}" build . -out:bin/${EXECUTABLE}

echo "Creating app bundle..."
mkdir -p "${BIN_DIR}"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp "${BIN_DIR}/${EXECUTABLE}" "${APP_DIR}/Contents/MacOS/"
cp AppIcon.icns "${APP_DIR}/Contents/Resources/"

cat > "${APP_DIR}/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${EXECUTABLE}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSScreenCaptureUsageDescription</key>
    <string>Color Picker needs screen capture access for the eyedropper tool.</string>
</dict>
</plist>
PLIST

echo "App bundle created: ${APP_DIR}"

echo "Creating DMG..."
rm -f "${DMG_NAME}"

mkdir -p dmg_staging
rm -rf dmg_staging/*
cp -R "${APP_DIR}" dmg_staging/
ln -sf /Applications dmg_staging/Applications

hdiutil create -volname "${APP_NAME}" \
    -srcfolder dmg_staging \
    -ov -format UDZO \
    "${DMG_NAME}"

rm -rf dmg_staging

echo ""
echo "Done!"
echo "  App bundle: ${APP_DIR}"
echo "  DMG:        ${DMG_NAME}"
echo ""
echo "To install:"
echo "  1. Open ${DMG_NAME}"
echo "  2. Drag '${APP_NAME}' to Applications"
echo "  3. Launch from Spotlight (Cmd+Space, type 'Color Picker')"
echo ""
echo "Or install directly:"
echo "  cp -R '${APP_DIR}' /Applications/"
