#!/usr/bin/env bash
set -e

# Change to project root directory
cd "$(dirname "$0")/.."

CONFIGURATION="${1:-debug}"
echo "==> Building Aura ($CONFIGURATION)..."
swift build -c "$CONFIGURATION"

BIN_PATH="$(swift build -c "$CONFIGURATION" --show-bin-path)/Aura"
APP_BUNDLE="build/Aura.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

echo "==> Creating macOS Application Bundle at $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp "$BIN_PATH" "$MACOS_DIR/Aura"
chmod +x "$MACOS_DIR/Aura"

# Copy Info.plist
cp "Resources/Info.plist" "$CONTENTS/Info.plist"

# Copy AppIcon assets
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi
if [ -f "Resources/AppIcon.png" ]; then
    cp "Resources/AppIcon.png" "$RESOURCES_DIR/AppIcon.png"
fi
if [ -d "Resources/AppIcon.icon" ]; then
    cp -R "Resources/AppIcon.icon" "$RESOURCES_DIR/AppIcon.icon"
fi

# Create PkgInfo
echo -n "APPL????" > "$CONTENTS/PkgInfo"

# Ad-hoc sign bundle if codesign is available
if command -v codesign &> /dev/null; then
    echo "==> Signing application bundle..."
    codesign --force --deep --sign - --entitlements Resources/Aura.entitlements "$APP_BUNDLE"
fi

echo "==> Successfully bundled Aura.app at $(pwd)/$APP_BUNDLE"
