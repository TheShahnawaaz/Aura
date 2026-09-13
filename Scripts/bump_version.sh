#!/usr/bin/env bash
set -e

# Change to project root
cd "$(dirname "$0")/.."

NEW_VERSION="$1"
CUSTOM_BUILD="$2"

if [ -z "$NEW_VERSION" ]; then
    CURRENT_VERSION=$(cat VERSION 2>/dev/null || echo "1.0.0")
    echo "Usage: ./Scripts/bump_version.sh <new_version|patch|minor|major> [build_number]"
    echo "Current version: $CURRENT_VERSION"
    exit 1
fi

CURRENT_VERSION=$(cat VERSION 2>/dev/null || echo "1.0.0")
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Handle semantic bump keywords
case "$NEW_VERSION" in
    patch)
        PATCH=$((PATCH + 1))
        TARGET_VERSION="$MAJOR.$MINOR.$PATCH"
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        TARGET_VERSION="$MAJOR.$MINOR.$PATCH"
        ;;
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        TARGET_VERSION="$MAJOR.$MINOR.$PATCH"
        ;;
    *)
        TARGET_VERSION="$NEW_VERSION"
        ;;
esac

# Validate semver format (X.Y.Z)
if [[ ! "$TARGET_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+.*$ ]]; then
    echo "Error: Version '$TARGET_VERSION' does not match semver format (e.g. 1.0.0)"
    exit 1
fi

# Calculate or parse build number
CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" Resources/Info.plist 2>/dev/null || echo "1")
if [ -n "$CUSTOM_BUILD" ]; then
    TARGET_BUILD="$CUSTOM_BUILD"
else
    TARGET_BUILD=$((CURRENT_BUILD + 1))
fi

TODAY=$(date "+%Y-%m-%d")

echo "==> Bumping Aura version:"
echo "    Version: $CURRENT_VERSION -> $TARGET_VERSION"
echo "    Build:   $CURRENT_BUILD -> $TARGET_BUILD"
echo "    Date:    $TODAY"

# 1. Update VERSION file
echo "$TARGET_VERSION" > VERSION

# 2. Update Sources/Aura/System/AuraVersion.swift
cat << SWIFTEOF > Sources/Aura/System/AuraVersion.swift
import Foundation

/// Single source of truth for version and distribution metadata in Aura.
public enum AuraVersion {
    /// Current semantic version string (e.g. "1.0.0").
    public static let current = "$TARGET_VERSION"

    /// Internal build number string (e.g. "1").
    public static let build = "$TARGET_BUILD"

    /// Release date string for this build.
    public static let releaseDate = "$TODAY"

    /// Public GitHub repository identifier.
    public static let repository = "TheShahnawaaz/Aura"

    /// GitHub Releases latest API endpoint.
    public static var releasesApiURL: URL {
        URL(string: "https://api.github.com/repos/\(repository)/releases/latest")!
    }

    /// Direct DMG download URL for latest release.
    public static var latestDmgDownloadURL: URL {
        URL(string: "https://github.com/\(repository)/releases/latest/download/Aura.dmg")!
    }

    /// GitHub Releases page for manual browsing.
    public static var releasesWebURL: URL {
        URL(string: "https://github.com/\(repository)/releases")!
    }

    /// Formatted display string, e.g. "v$TARGET_VERSION (Build $TARGET_BUILD)".
    public static var displayString: String {
        "v\(current) (Build \(build))"
    }
}
SWIFTEOF

# 3. Update Resources/Info.plist
if [ -f "Resources/Info.plist" ]; then
    plutil -replace CFBundleShortVersionString -string "$TARGET_VERSION" Resources/Info.plist
    plutil -replace CFBundleVersion -string "$TARGET_BUILD" Resources/Info.plist
fi

# 4. Update web/package.json
if [ -f "web/package.json" ]; then
    # Use node to cleanly update version field preserving indentation
    node -e "
        const fs = require('fs');
        const pkg = JSON.parse(fs.readFileSync('web/package.json', 'utf8'));
        pkg.version = '$TARGET_VERSION';
        fs.writeFileSync('web/package.json', JSON.stringify(pkg, null, 2) + '\n');
    "
fi

# 5. Check CHANGELOG.md
if ! grep -q "## \[$TARGET_VERSION\]" CHANGELOG.md; then
    echo "Notice: CHANGELOG.md does not yet have a section for ## [$TARGET_VERSION]."
    echo "Remember to document changes under ## [$TARGET_VERSION] - $TODAY in CHANGELOG.md."
fi

echo "==> Successfully synchronized all version references to $TARGET_VERSION ($TARGET_BUILD)!"
