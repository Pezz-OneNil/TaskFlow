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
VERSION="1.3.0"
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

# Create the combined installation guide with nice formatting
cat > "$DMG_TEMP/📖 Installation Guide.txt" << 'EOF'


    ████████╗ █████╗ ███████╗██╗  ██╗███████╗██╗      ██████╗ ██╗    ██╗
    ╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝██╔════╝██║     ██╔═══██╗██║    ██║
       ██║   ███████║███████╗█████╔╝ █████╗  ██║     ██║   ██║██║ █╗ ██║
       ██║   ██╔══██║╚════██║██╔═██╗ ██╔══╝  ██║     ██║   ██║██║███╗██║
       ██║   ██║  ██║███████║██║  ██╗██║     ███████╗╚██████╔╝╚███╔███╔╝
       ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝

                        ✨ Version 1.3.0 ✨
                   © 2025 Pezz. All rights reserved.

    ═══════════════════════════════════════════════════════════════════


    ⚡ QUICK START (2 minutes)
    ─────────────────────────────────────────────────────────────────

        ┌─────────────────────────────────────────────────────────┐
        │                                                         │
        │   1️⃣   Drag TaskFlow.app ──→ Applications folder        │
        │                                                         │
        │   2️⃣   Right-click TaskFlow.app → Select "Open"         │
        │                                                         │
        │   3️⃣   Click "Open" in the security dialog              │
        │                                                         │
        │   ✅  Done! TaskFlow opens normally from now on.         │
        │                                                         │
        └─────────────────────────────────────────────────────────┘


    ⚠️  MACOS SECURITY NOTE
    ─────────────────────────────────────────────────────────────────

    When you first open TaskFlow, macOS may display:

        ╭──────────────────────────────────────────────────────╮
        │  "Apple could not verify TaskFlow is free           │
        │   of malware that may harm your Mac"                │
        ╰──────────────────────────────────────────────────────╯

    This is NORMAL for apps distributed outside the Mac App Store.
    TaskFlow is completely safe! Use one of these methods to open it:


        METHOD A: Right-Click (Recommended)
        ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
        • Right-click (or Control+click) on TaskFlow.app
        • Select "Open" from the context menu
        • Click "Open" in the dialog


        METHOD B: System Settings
        ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
        • Open System Settings → Privacy & Security
        • Scroll down to find the TaskFlow message
        • Click "Open Anyway"


        METHOD C: Terminal (Advanced)
        ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
        • Open Terminal and run:
          xattr -cr /Applications/TaskFlow.app


    🚀 FULL INSTALLATION (with AI Features)
    ─────────────────────────────────────────────────────────────────

    For AI-powered task title generation, run the installer script:

        ┌─────────────────────────────────────────────────────────┐
        │                                                         │
        │   1. Open Terminal (search "Terminal" in Spotlight)     │
        │                                                         │
        │   2. Drag "install-taskflow.sh" into Terminal window    │
        │                                                         │
        │   3. Press Enter and follow the prompts                 │
        │                                                         │
        └─────────────────────────────────────────────────────────┘

    The installer will:
        ✦ Install TaskFlow to /Applications
        ✦ Install Ollama (local AI runtime)
        ✦ Download the gemma3:1b model (~1.5GB)
        ✦ Configure permissions


    📋 REQUIREMENTS
    ─────────────────────────────────────────────────────────────────

        ╭────────────────────────────────────────────────────────╮
        │  ◉ macOS 13 (Ventura) or later                        │
        │  ◉ 5GB free disk space (for AI model)                 │
        │  ◉ Apple Silicon (M1/M2/M3) or Intel Mac              │
        ╰────────────────────────────────────────────────────────╯


    🔐 PERMISSIONS NEEDED
    ─────────────────────────────────────────────────────────────────

        Screen Recording     →  For capturing task screenshots
        Accessibility        →  For global keyboard shortcuts (optional)

        Grant these in: System Settings → Privacy & Security


    🎯 AFTER INSTALLATION
    ─────────────────────────────────────────────────────────────────

        1. Launch TaskFlow from Applications or Launchpad
        2. Grant Screen Recording permission when prompted
        3. Ensure Ollama is running (check menu bar)
        4. Press ⌘⇧C to capture your first task!


    🔧 TROUBLESHOOTING
    ─────────────────────────────────────────────────────────────────

        "TaskFlow can't be opened"
        → Right-click → Open (see security note above)

        "TaskFlow is damaged"
        → Run: xattr -cr /Applications/TaskFlow.app

        Screen capture not working
        → Grant Screen Recording in System Settings
        → Restart TaskFlow after granting

        AI titles not generating
        → Check Ollama is running (menu bar icon)
        → Run: ollama serve

        Model not found
        → Run: ollama pull gemma3:1b


    💡 FEATURES
    ─────────────────────────────────────────────────────────────────

        ✦ Kanban Board          Organize tasks visually
        ✦ Screenshot Capture    Capture context with tasks
        ✦ AI Task Titles        Auto-generate titles with local AI
        ✦ Time Tracking         Built-in Pomodoro timer
        ✦ 100% Offline          All data stays on your Mac
        ✦ Multi-Select          Bulk delete with ⌘+Click
        ✦ Outlook Integration   Capture emails as tasks (optional)


    ═══════════════════════════════════════════════════════════════════

                         Enjoy TaskFlow! 🚀

                    Questions? Check the app's Help menu.

    ═══════════════════════════════════════════════════════════════════


EOF

# Create Applications folder symlink for easy drag-and-drop
ln -s /Applications "$DMG_TEMP/Applications"

# Make installer executable
chmod +x "$DMG_TEMP/install-taskflow.sh"

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
