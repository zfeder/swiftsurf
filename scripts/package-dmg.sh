#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/swiftsurf.xcodeproj"
SCHEME="swiftsurf"
BUILD_DIR="$ROOT_DIR/dist/build"
STAGING_DIR="$ROOT_DIR/dist/staging"
APP_PATH="$BUILD_DIR/Release/swiftsurf.app"
DMG_PATH="$ROOT_DIR/dist/SwiftSurf.dmg"

rm -rf "$BUILD_DIR" "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$BUILD_DIR" "$STAGING_DIR"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  CODE_SIGNING_ALLOWED=NO \
  build >/dev/null

BUILT_APP="$BUILD_DIR/DerivedData/Build/Products/Release/swiftsurf.app"
cp -R "$BUILT_APP" "$STAGING_DIR/SwiftSurf.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "SwiftSurf" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

echo "Created $DMG_PATH"
