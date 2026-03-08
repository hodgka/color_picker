#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="${SCRIPT_DIR}/bin/Color Picker.app"
BIN_PATH="${SCRIPT_DIR}/bin/color_picker"
DMG_PATH="${SCRIPT_DIR}/bin/ColorPicker.dmg"
LINK_PATH="/usr/local/bin/color_picker"

if [ ! -f "${BIN_PATH}" ]; then
    echo "Binary not found. Run ./bundle.sh first."
    exit 1
fi

echo "=== Color Picker Installer ==="
echo ""

# 1. CLI symlink
echo "[1/3] Installing CLI command..."
sudo ln -sf "${BIN_PATH}" "${LINK_PATH}"
echo "  Created: ${LINK_PATH} -> ${BIN_PATH}"

# 2. App bundle to /Applications
echo ""
echo "[2/3] Installing app to /Applications..."
if [ -d "${APP_PATH}" ]; then
    rm -rf "/Applications/Color Picker.app"
    cp -R "${APP_PATH}" /Applications/
    echo "  Installed: /Applications/Color Picker.app"
else
    echo "  Skipped: .app bundle not found"
fi

# 3. DMG to ~/Desktop for easy access
echo ""
echo "[3/3] Copying DMG to Desktop..."
if [ -f "${DMG_PATH}" ]; then
    cp -f "${DMG_PATH}" ~/Desktop/ColorPicker.dmg
    echo "  Copied: ~/Desktop/ColorPicker.dmg"
else
    echo "  Skipped: DMG not found"
fi

echo ""
echo "=== Installation complete ==="
echo ""
echo "Usage:"
echo "  Terminal:  color_picker"
echo "  Spotlight: Cmd+Space -> 'Color Picker'"
echo "  Share:     ~/Desktop/ColorPicker.dmg"
