#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# TaskFlow Build Script
# © 2025 Pezz. All rights reserved.
# 
# Build TaskFlow as a macOS .app bundle with code signing and notarization
# Run this script from the TaskFlow/TaskFlow directory
#
# PREREQUISITES FOR DISTRIBUTION:
# 1. Apple Developer Program membership ($99/year)
# 2. Developer ID Application certificate installed in Keychain
# 3. Developer ID Installer certificate installed in Keychain (for DMG)
# 4. App-specific password for notarization (create at appleid.apple.com)
#
# ENVIRONMENT VARIABLES (for signed/notarized builds):
#   DEVELOPER_ID       - Your Developer ID (e.g., "Developer ID Application: Your Name (TEAMID)")
#   APPLE_ID           - Your Apple ID email
#   APPLE_TEAM_ID      - Your 10-character Team ID
#   NOTARIZE_PASSWORD  - App-specific password (stored in keychain recommended)
#
# USAGE:
#   ./build-app.sh              # Build with ad-hoc signing (development)
#   ./build-app.sh --sign       # Build with Developer ID signing
#   ./build-app.sh --notarize   # Build, sign, and notarize for distribution
#   ./build-app.sh --dmg        # Create DMG (add --notarize for distribution)
# ═══════════════════════════════════════════════════════════════════════════════

set -e

APP_VERSION="1.1.0"
COPYRIGHT="© 2025 Pezz. All rights reserved."
BUNDLE_ID="com.pezz.TaskFlow"

# Parse arguments
SIGN_APP=false
NOTARIZE_APP=false
CREATE_DMG=false

for arg in "$@"; do
    case $arg in
        --sign)
            SIGN_APP=true
            ;;
        --notarize)
            SIGN_APP=true
            NOTARIZE_APP=true
            ;;
        --dmg)
            CREATE_DMG=true
            ;;
        --help)
            echo "Usage: ./build-app.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --sign       Sign with Developer ID certificate"
            echo "  --notarize   Sign and notarize for distribution"
            echo "  --dmg        Create DMG installer"
            echo "  --help       Show this help message"
            echo ""
            echo "Environment variables for signing/notarization:"
            echo "  DEVELOPER_ID       Developer ID Application certificate name"
            echo "  APPLE_ID           Apple ID email for notarization"
            echo "  APPLE_TEAM_ID      10-character Team ID"
            echo "  NOTARIZE_PASSWORD  App-specific password"
            exit 0
            ;;
    esac
done

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

# Code signing
if [ "$SIGN_APP" = true ]; then
    # Check for required environment variables
    if [ -z "$DEVELOPER_ID" ]; then
        echo "❌ Error: DEVELOPER_ID environment variable not set"
        echo "   Set it to your Developer ID Application certificate name, e.g.:"
        echo "   export DEVELOPER_ID=\"Developer ID Application: Your Name (TEAMID)\""
        exit 1
    fi
    
    echo "🔏 Code signing app bundle with Developer ID..."
    echo "   Certificate: $DEVELOPER_ID"
    
    # Sign with hardened runtime (required for notarization)
    codesign --force --deep --options runtime \
        --entitlements "TaskFlow.entitlements" \
        --sign "$DEVELOPER_ID" \
        "$APP_DIR"
    
    # Verify signature
    echo "🔍 Verifying code signature..."
    codesign --verify --verbose=2 "$APP_DIR"
    
    echo "✅ Code signing complete"
else
    # Ad-hoc signing for development
    echo "🔏 Code signing app bundle (ad-hoc for development)..."
    codesign --force --deep --sign - "$APP_DIR"
    echo "⚠️  Note: Ad-hoc signed apps will show Gatekeeper warnings on other Macs"
fi

# Notarization
if [ "$NOTARIZE_APP" = true ]; then
    # Check for required environment variables
    if [ -z "$APPLE_ID" ] || [ -z "$APPLE_TEAM_ID" ] || [ -z "$NOTARIZE_PASSWORD" ]; then
        echo "❌ Error: Missing environment variables for notarization"
        echo "   Required: APPLE_ID, APPLE_TEAM_ID, NOTARIZE_PASSWORD"
        exit 1
    fi
    
    echo ""
    echo "📤 Submitting app for notarization..."
    echo "   This may take several minutes..."
    
    # Create a zip for notarization
    ZIP_FILE="TaskFlow-notarize.zip"
    ditto -c -k --keepParent "$APP_DIR" "$ZIP_FILE"
    
    # Submit for notarization
    xcrun notarytool submit "$ZIP_FILE" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$NOTARIZE_PASSWORD" \
        --wait
    
    # Clean up zip
    rm "$ZIP_FILE"
    
    # Staple the notarization ticket to the app
    echo "📎 Stapling notarization ticket..."
    xcrun stapler staple "$APP_DIR"
    
    # Verify notarization
    echo "🔍 Verifying notarization..."
    spctl --assess --verbose=2 "$APP_DIR"
    
    echo "✅ Notarization complete - app is ready for distribution!"
fi

# Create DMG
if [ "$CREATE_DMG" = true ]; then
    echo ""
    echo "💿 Creating DMG installer..."
    
    DMG_NAME="TaskFlow-$APP_VERSION.dmg"
    DMG_TEMP="TaskFlow-temp.dmg"
    DMG_VOLUME="TaskFlow"
    
    # Remove old DMG if exists
    rm -f "$DMG_NAME" "$DMG_TEMP"
    
    # Create temporary DMG
    hdiutil create -srcfolder "$APP_DIR" -volname "$DMG_VOLUME" -fs HFS+ \
        -fsargs "-c c=64,a=16,e=16" -format UDRW "$DMG_TEMP"
    
    # Mount it
    MOUNT_DIR=$(hdiutil attach -readwrite -noverify "$DMG_TEMP" | grep "/Volumes/$DMG_VOLUME" | awk '{print $3}')
    
    # Create Applications symlink
    ln -s /Applications "$MOUNT_DIR/Applications"
    
    # Set window properties (optional - makes DMG look nicer)
    # You can customize this with a background image
    
    # Unmount
    hdiutil detach "$MOUNT_DIR"
    
    # Convert to compressed DMG
    hdiutil convert "$DMG_TEMP" -format UDZO -imagekey zlib-level=9 -o "$DMG_NAME"
    rm "$DMG_TEMP"
    
    # Sign the DMG if we have a Developer ID
    if [ "$SIGN_APP" = true ] && [ -n "$DEVELOPER_ID" ]; then
        echo "🔏 Signing DMG..."
        # Use Installer certificate for DMG if available, otherwise use Application cert
        INSTALLER_ID="${DEVELOPER_ID/Application/Installer}"
        codesign --force --sign "$INSTALLER_ID" "$DMG_NAME" 2>/dev/null || \
        codesign --force --sign "$DEVELOPER_ID" "$DMG_NAME"
    fi
    
    # Notarize DMG if requested
    if [ "$NOTARIZE_APP" = true ]; then
        echo "📤 Submitting DMG for notarization..."
        xcrun notarytool submit "$DMG_NAME" \
            --apple-id "$APPLE_ID" \
            --team-id "$APPLE_TEAM_ID" \
            --password "$NOTARIZE_PASSWORD" \
            --wait
        
        echo "📎 Stapling notarization ticket to DMG..."
        xcrun stapler staple "$DMG_NAME"
    fi
    
    echo "✅ DMG created: $DMG_NAME"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════════════════"
echo "✅ Build complete: $APP_DIR"
echo "═══════════════════════════════════════════════════════════════════════════════"
echo ""

if [ "$NOTARIZE_APP" = true ]; then
    echo "🎉 App is signed and notarized - ready for distribution!"
    echo "   Users will not see Gatekeeper warnings."
elif [ "$SIGN_APP" = true ]; then
    echo "🔏 App is signed with Developer ID."
    echo "   Run with --notarize to submit for Apple notarization."
else
    echo "⚠️  App has ad-hoc signature (development only)."
    echo "   Users will see: \"Apple could not verify this app\""
    echo ""
    echo "   For distribution, run:"
    echo "   ./build-app.sh --notarize --dmg"
fi

echo ""
echo "To install locally:"
echo "  cp -r TaskFlow.app /Applications/"
echo ""
echo "To run now:"
echo "  open TaskFlow.app"
