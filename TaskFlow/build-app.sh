#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# TaskFlow Build Script
# © 2025 Pezz. All rights reserved.
# 
# Build TaskFlow as a macOS .app bundle
# Run this script from the TaskerApp/TaskFlow directory
# ═══════════════════════════════════════════════════════════════════════════════

set -e

APP_VERSION="1.0.4"
COPYRIGHT="© 2025 Pezz. All rights reserved."

echo "🔨 Building TaskFlow v$APP_VERSION for release..."
echo "   $COPYRIGHT"
echo ""

# Build release version
swift build -c release

echo "📦 Creating app bundle..."

# Create app bundle structure
APP_NAME="TaskFlow"
APP_DIR="$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Clean previous build
rm -rf "$APP_DIR"

# Create directories
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp ".build/release/TaskFlow" "$MACOS_DIR/"

# Copy Info.plist
cp "Sources/TaskFlow/Info.plist" "$CONTENTS_DIR/"

# Copy app icon
cp "Resources/AppIcon.icns" "$RESOURCES_DIR/"

# Create PkgInfo
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Code sign the app with ad-hoc signature
# This helps macOS remember permissions between launches
echo "🔏 Code signing app bundle..."
codesign --force --deep --sign - "$APP_DIR"

echo "✅ App bundle created: $APP_DIR"
echo ""
echo "To install, run:"
echo "  cp -r TaskFlow.app /Applications/"
echo ""
echo "Or drag TaskFlow.app to your Applications folder in Finder."
echo ""
echo "To run now:"
echo "  open TaskFlow.app"
echo ""
echo "⚠️  Note: You may need to grant Screen Recording permission in"
echo "   System Settings > Privacy & Security > Screen Recording"
echo "   The permission should persist after granting it once."
