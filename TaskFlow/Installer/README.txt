╔══════════════════════════════════════════════════════════════╗
║                    TaskFlow v1.1.0                           ║
║              © 2025 Pezz. All rights reserved.               ║
╚══════════════════════════════════════════════════════════════╝

Welcome to TaskFlow - Your Intelligent Task Management App!

TaskFlow is proprietary software. Unauthorized copying, modification,
distribution, or use of this software is strictly prohibited.


⚠️  IMPORTANT: FIRST-TIME INSTALLATION ON macOS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

macOS may show a security warning when you first open TaskFlow:
"Apple could not verify TaskFlow is free of malware"

This is normal for apps distributed outside the Mac App Store.
TaskFlow is safe - follow these steps to open it:

┌─────────────────────────────────────────────────────────────┐
│  METHOD 1: Right-Click to Open (Easiest)                    │
├─────────────────────────────────────────────────────────────┤
│  1. Drag TaskFlow.app to your Applications folder           │
│  2. RIGHT-CLICK (or Control+click) on TaskFlow.app          │
│  3. Select "Open" from the menu                             │
│  4. Click "Open" in the security dialog                     │
│  5. TaskFlow will now open normally every time!             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  METHOD 2: System Settings                                  │
├─────────────────────────────────────────────────────────────┤
│  1. Try to open TaskFlow (it will be blocked)               │
│  2. Open System Settings → Privacy & Security               │
│  3. Scroll down to find the message about TaskFlow          │
│  4. Click "Open Anyway"                                     │
│  5. Click "Open" in the confirmation dialog                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  METHOD 3: Terminal (Advanced Users)                        │
├─────────────────────────────────────────────────────────────┤
│  Run this command after dragging to Applications:           │
│                                                             │
│  xattr -cr /Applications/TaskFlow.app                       │
│                                                             │
│  This removes the quarantine flag from downloaded files.    │
└─────────────────────────────────────────────────────────────┘

You only need to do this ONCE. After the first successful open,
macOS will remember your choice and TaskFlow will open normally.


INSTALLATION OPTIONS:
━━━━━━━━━━━━━━━━━━━━━

Option 1: Full Installation (Recommended)
-----------------------------------------
Run the installer script for complete setup including Ollama and the LLM model:

1. Open Terminal
2. Drag 'install-taskflow.sh' into the Terminal window
3. Press Enter and follow the prompts

The installer will:
• Install TaskFlow to /Applications
• Install Ollama (if not present)
• Download the gemma3:1b model for offline AI features
• Guide you through permission setup


Option 2: Quick Installation
----------------------------
If you already have Ollama installed with gemma3:1b:

1. Drag 'TaskFlow.app' to your Applications folder
2. RIGHT-CLICK → Open (see security note above)
3. Grant Screen Recording permission when prompted


REQUIREMENTS:
━━━━━━━━━━━━━
• macOS 13 (Ventura) or later
• 5GB+ free disk space (for LLM model)
• Apple Silicon (M1/M2/M3) or Intel Mac


AFTER INSTALLATION:
━━━━━━━━━━━━━━━━━━━
1. Launch TaskFlow from Applications or Launchpad
2. Grant Screen Recording permission in System Settings
3. Ensure Ollama is running (it starts automatically)
4. Start capturing tasks!


PERMISSIONS REQUIRED:
━━━━━━━━━━━━━━━━━━━━━
TaskFlow needs the following permissions to work properly:

• Screen Recording - For capturing screenshots of tasks
  → System Settings → Privacy & Security → Screen Recording → Enable TaskFlow

• Accessibility (optional) - For global keyboard shortcuts
  → System Settings → Privacy & Security → Accessibility → Enable TaskFlow


OFFLINE OPERATION:
━━━━━━━━━━━━━━━━━━
TaskFlow is designed for 100% offline use after installation.
All AI features run locally on your Mac using Ollama.
No internet connection is required for daily use.


LLM MODEL:
━━━━━━━━━━
TaskFlow uses the gemma3:1b model (~1.5GB) for AI-powered features:
• Fast and capable model optimized for quick title generation
• Generates action-oriented task titles from screenshots
• Creates contextual descriptions summarizing captured content

The model is downloaded during installation and runs entirely on your Mac.


TROUBLESHOOTING:
━━━━━━━━━━━━━━━━

"TaskFlow can't be opened" / "Cannot verify" warning
  → Use RIGHT-CLICK → Open (see installation instructions above)
  → Or: System Settings → Privacy & Security → Open Anyway

"TaskFlow is damaged and can't be opened"
  → Run in Terminal: xattr -cr /Applications/TaskFlow.app

Screen capture not working
  → Grant Screen Recording permission in System Settings
  → You may need to restart TaskFlow after granting permission

AI titles not generating
  → Ensure Ollama is running (check menu bar for Ollama icon)
  → Open Terminal and run: ollama serve

Model not found
  → Run in Terminal: ollama pull gemma3:1b


COPYRIGHT & LICENSE:
━━━━━━━━━━━━━━━━━━━━
TaskFlow v1.1.0
© 2025 Pezz. All rights reserved.

This software is protected by copyright law and international treaties.
Unauthorized reproduction or distribution of this software, or any portion
of it, may result in severe civil and criminal penalties.


Enjoy TaskFlow! 🚀
