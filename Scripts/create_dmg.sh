#!/usr/bin/env bash
set -e

# Change to project root directory
cd "$(dirname "$0")/.."

CONFIGURATION="${1:-release}"
VERSION=$(cat VERSION 2>/dev/null || echo "1.0.0")
APP_BUNDLE="build/Aura.app"
STAGING_DIR="build/dmg_staging"
DMG_PATH="build/Aura.dmg"

echo "=========================================="
echo " Packaging Aura v$VERSION ($CONFIGURATION)"
echo "=========================================="

# 1. Build and bundle application
./Scripts/bundle_app.sh "$CONFIGURATION"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: Application bundle $APP_BUNDLE was not found!"
    exit 1
fi

# 2. Determine Code Signing Identity
SIGN_IDENTITY="${DEVELOPER_ID_APPLICATION:-}"
if [ -z "$SIGN_IDENTITY" ]; then
    SIGN_IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null | grep "Developer ID Application:" | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/' || true)
fi

if [ -n "$SIGN_IDENTITY" ]; then
    echo "==> Signing $APP_BUNDLE with Developer ID: $SIGN_IDENTITY"
    codesign --force --options runtime --deep --sign "$SIGN_IDENTITY" --entitlements Resources/Aura.entitlements "$APP_BUNDLE"
else
    echo "==> No Developer ID Application identity found. Retaining ad-hoc signature."
fi

# 3. Prepare DMG Staging Folder
echo "==> Preparing DMG staging environment..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

cp -R "$APP_BUNDLE" "$STAGING_DIR/Aura.app"
ln -s /Applications "$STAGING_DIR/Applications"

# Copy optional icon or background if present
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$STAGING_DIR/.VolumeIcon.icns" 2>/dev/null || true
fi

# 4. Generate Compressed DMG Image
echo "==> Generating compressed disk image at $DMG_PATH..."
rm -f "$DMG_PATH"
hdiutil create -volname "Aura" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"

# Clean staging folder
rm -rf "$STAGING_DIR"

# 5. Sign the DMG Container if Developer ID is available
if [ -n "$SIGN_IDENTITY" ]; then
    echo "==> Signing $DMG_PATH container..."
    codesign --force --sign "$SIGN_IDENTITY" "$DMG_PATH"
fi

# 6. Apple Notarization (if credentials supplied)
if [ -n "${NOTARY_KEY_PATH:-}" ] && [ -n "${NOTARY_KEY_ID:-}" ] && [ -n "${NOTARY_ISSUER:-}" ]; then
    echo "==> Submitting $DMG_PATH to Apple Notary Service via API Key..."
    xcrun notarytool submit "$DMG_PATH" \
        --key "$NOTARY_KEY_PATH" \
        --key-id "$NOTARY_KEY_ID" \
        --issuer "$NOTARY_ISSUER" \
        --wait

    echo "==> Stapling notarization ticket to $DMG_PATH..."
    xcrun stapler staple "$DMG_PATH"
    echo "==> Successfully notarized and stapled $DMG_PATH!"
elif [ -n "${NOTARY_PROFILE:-}" ]; then
    echo "==> Submitting $DMG_PATH to Apple Notary Service via Keychain Profile: $NOTARY_PROFILE..."
    xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
    echo "==> Stapling notarization ticket..."
    xcrun stapler staple "$DMG_PATH"
    echo "==> Successfully notarized and stapled $DMG_PATH!"
else
    echo "==> Skipping Apple Notarization (no notary credentials provided in environment)."
fi

# 7. Print Checksums and Final Information
echo "------------------------------------------"
echo "==> Build complete: $DMG_PATH"
echo "    Size: $(du -sh "$DMG_PATH" | cut -f1)"
echo "    SHA256: $(shasum -a 256 "$DMG_PATH" | cut -d ' ' -f 1)"
echo "=========================================="
