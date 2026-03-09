#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

VERSION="1.0.0"
SKIP_BUILD=false

APP_NAME="Color Picker"
BUNDLE_ID="com.alec.colorpicker"
BINARY_NAME="color_picker"
MIN_MACOS="12.0"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Create a distributable package for Color Picker.

On macOS: creates a .app bundle and .dmg disk image.
On Linux: creates a .deb package.

Options:
  --version VERSION   Set the package version (default: 1.0.0)
  --skip-build        Skip the build step (use existing binary in bin/)
  --help              Show this help message

Examples:
  ./scripts/bundle.sh
  ./scripts/bundle.sh --version 2.1.0
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)    VERSION="$2"; shift 2 ;;
        --skip-build) SKIP_BUILD=true; shift ;;
        --help)       usage ;;
        *)            echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

OS="$(uname -s)"
if [[ "$OS" != "Darwin" && "$OS" != "Linux" ]]; then
    echo "Error: bundle.sh supports macOS and Linux only." >&2
    exit 1
fi

if [[ "$SKIP_BUILD" == false ]]; then
    echo "Building release binary..."
    "$SCRIPT_DIR/build.sh" --release --version "$VERSION"
fi

if [[ ! -f "$PROJECT_ROOT/bin/$BINARY_NAME" ]]; then
    echo "Error: bin/$BINARY_NAME not found. Run build.sh first." >&2
    exit 1
fi

# ── macOS: .app bundle + .dmg ──
if [[ "$OS" == "Darwin" ]]; then
    APP_DIR="$PROJECT_ROOT/bin/$APP_NAME.app"
    CONTENTS="$APP_DIR/Contents"

    rm -rf "$APP_DIR"
    mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"

    cp "$PROJECT_ROOT/bin/$BINARY_NAME" "$CONTENTS/MacOS/$BINARY_NAME"

    if [[ -f "$PROJECT_ROOT/AppIcon.icns" ]]; then
        cp "$PROJECT_ROOT/AppIcon.icns" "$CONTENTS/Resources/AppIcon.icns"
    else
        echo "Warning: AppIcon.icns not found, bundle will have no icon."
    fi

    cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${BINARY_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>LSMinimumSystemVersion</key>
    <string>${MIN_MACOS}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSScreenCaptureUsageDescription</key>
    <string>Color Picker needs screen capture access for the eyedropper tool.</string>
</dict>
</plist>
PLIST

    echo "Created: bin/$APP_NAME.app (v$VERSION)"

    DMG_PATH="$PROJECT_ROOT/bin/ColorPicker.dmg"
    rm -f "$DMG_PATH"

    if command -v hdiutil &>/dev/null; then
        echo "Creating DMG..."
        hdiutil create -volname "Color Picker" \
            -srcfolder "$APP_DIR" \
            -ov -format UDZO \
            "$DMG_PATH" \
            > /dev/null
        echo "Created: bin/ColorPicker.dmg"
    else
        echo "Warning: hdiutil not found, skipping DMG creation."
    fi
fi

# ── Linux: .deb package ──
if [[ "$OS" == "Linux" ]]; then
    DEB_DIR="$PROJECT_ROOT/bin/deb_staging"
    DEB_PATH="$PROJECT_ROOT/bin/color-picker_${VERSION}_amd64.deb"

    rm -rf "$DEB_DIR"
    mkdir -p "$DEB_DIR/DEBIAN"
    mkdir -p "$DEB_DIR/usr/local/bin"
    mkdir -p "$DEB_DIR/usr/share/applications"

    cp "$PROJECT_ROOT/bin/$BINARY_NAME" "$DEB_DIR/usr/local/bin/$BINARY_NAME"

    cat > "$DEB_DIR/DEBIAN/control" <<CTRL
Package: color-picker
Version: ${VERSION}
Section: graphics
Priority: optional
Architecture: amd64
Depends: libgl1, libx11-6, libxrandr2, libxinerama1, libxcursor1, libxi6
Maintainer: Alec Hodgkinson
Description: Native desktop color picker
 HSV color picker with harmony generation, WCAG contrast checking,
 color vision deficiency simulation, palette management, and export.
CTRL

    cat > "$DEB_DIR/usr/share/applications/color-picker.desktop" <<DESKTOP
[Desktop Entry]
Name=Color Picker
Exec=/usr/local/bin/color_picker
Type=Application
Categories=Graphics;Utility;
Comment=Native desktop color picker with harmony and contrast tools
DESKTOP

    dpkg-deb --build "$DEB_DIR" "$DEB_PATH"
    rm -rf "$DEB_DIR"
    echo "Created: bin/color-picker_${VERSION}_amd64.deb"
fi
