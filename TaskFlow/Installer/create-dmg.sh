#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# TaskFlow DMG Creator
# © 2025 Pezz. All rights reserved.
# 
# Creates a distributable DMG containing TaskFlow.app and the installer
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
APP_NAME="TaskFlow"
DMG_NAME="TaskFlow-Installer"
VERSION="1.0.4"
COPYRIGHT="© 2025 Pezz. All rights reserved."
VOLUME_NAME="TaskFlow Installer"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/.."
BUILD_DIR="$PROJECT_DIR/dist"
DMG_TEMP="$BUILD_DIR/dmg-temp"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  TaskFlow DMG Creator${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if TaskFlow.app exists
if [ ! -d "$PROJECT_DIR/$APP_NAME.app" ]; then
    echo -e "${YELLOW}TaskFlow.app not found. Building...${NC}"
    cd "$PROJECT_DIR"
    ./build-app.sh
    cd "$SCRIPT_DIR"
fi

if [ ! -d "$PROJECT_DIR/$APP_NAME.app" ]; then
    echo -e "${RED}Error: Failed to build TaskFlow.app${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found TaskFlow.app"

# Clean and create build directory
echo -e "\n${CYAN}Preparing build directory...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$DMG_TEMP"

# Copy files to DMG temp directory
echo -e "${CYAN}Copying files...${NC}"
cp -R "$PROJECT_DIR/$APP_NAME.app" "$DMG_TEMP/"
cp "$SCRIPT_DIR/install-taskflow.sh" "$DMG_TEMP/"
cp "$SCRIPT_DIR/README.txt" "$DMG_TEMP/" 2>/dev/null || true

# Make installer executable
chmod +x "$DMG_TEMP/install-taskflow.sh"

# Create README if it doesn't exist
if [ ! -f "$DMG_TEMP/README.txt" ]; then
    cat > "$DMG_TEMP/README.txt" << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    TaskFlow Installer                        ║
╚══════════════════════════════════════════════════════════════╝

Welcome to TaskFlow - Your Intelligent Task Management App!

INSTALLATION OPTIONS:
━━━━━━━━━━━━━━━━━━━━━

Option 1: Full Installation (Recommended)
-----------------------------------------
Run the installer script for complete setup including Ollama and LLM models:

1. Open Terminal
2. Drag 'install-taskflow.sh' into the Terminal window
3. Press Enter and follow the prompts

The installer will:
• Install TaskFlow to /Applications
• Install Ollama (if not present)
• Download your selected LLM models for offline use
• Guide you through permission setup


Option 2: Quick Installation
----------------------------
If you already have Ollama installed with models:

1. Drag 'TaskFlow.app' to your Applications folder
2. Open TaskFlow from Applications
3. Grant Screen Recording permission when prompted


REQUIREMENTS:
━━━━━━━━━━━━━
• macOS 13 (Ventura) or later
• 20GB+ free disk space (for LLM models)
• Apple Silicon (M1/M2/M3) or Intel Mac


AFTER INSTALLATION:
━━━━━━━━━━━━━━━━━━━
1. Launch TaskFlow from Applications or Launchpad
2. Grant Screen Recording permission in System Settings
3. Ensure Ollama is running (it starts automatically)
4. Start capturing tasks!


SUPPORT:
━━━━━━━━
For issues or questions, please refer to the documentation
or contact support.


Enjoy TaskFlow! 🚀
EOF
fi

echo -e "${GREEN}✓${NC} Files prepared"

# Create DMG
echo -e "\n${CYAN}Creating DMG...${NC}"
DMG_PATH="$BUILD_DIR/${DMG_NAME}-${VERSION}.dmg"

# Remove existing DMG if present
rm -f "$DMG_PATH"

# Create DMG using hdiutil
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$DMG_PATH"

echo -e "${GREEN}✓${NC} DMG created"

# Clean up temp directory
rm -rf "$DMG_TEMP"

# Get DMG size
DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  DMG Created Successfully!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Location: ${YELLOW}$DMG_PATH${NC}"
echo -e "  Size: ${YELLOW}$DMG_SIZE${NC}"
echo ""
echo -e "  To distribute:"
echo -e "  1. Share the DMG file with users"
echo -e "  2. Users double-click to mount"
echo -e "  3. Users run install-taskflow.sh for full setup"
echo ""
