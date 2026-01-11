#!/bin/bash
# Idempotent version bump script
# Usage: ./bump-version.sh [major|minor|patch|build]

VERSION_FILE="Sources/PodoJuice/Version.swift"
cd "$(dirname "$0")/.."

if [ ! -f "$VERSION_FILE" ]; then
    echo "Version.swift not found"
    exit 1
fi

BUMP_TYPE="${1:-build}"

# Extract current values
MAJOR=$(grep "static let major" "$VERSION_FILE" | grep -o '[0-9]*')
MINOR=$(grep "static let minor" "$VERSION_FILE" | grep -o '[0-9]*')
PATCH=$(grep "static let patch" "$VERSION_FILE" | grep -o '[0-9]*')
BUILD=$(grep "static let build" "$VERSION_FILE" | grep -o '[0-9]*')

case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        BUILD=1
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        BUILD=1
        ;;
    patch)
        PATCH=$((PATCH + 1))
        BUILD=1
        ;;
    build)
        BUILD=$((BUILD + 1))
        ;;
esac

# Write back
cat > "$VERSION_FILE" << EOFV
import Foundation

struct PodoJuiceVersion {
    static let major = $MAJOR
    static let minor = $MINOR
    static let patch = $PATCH
    static let build = $BUILD
    
    static var string: String {
        "\(major).\(minor).\(patch)"
    }
    
    static var full: String {
        "\(major).\(minor).\(patch) (build \(build))"
    }
}
EOFV

echo "Version: $MAJOR.$MINOR.$PATCH (build $BUILD)"
