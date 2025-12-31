# TaskFlow

<p align="center">
  <img src="Resources/AppIcon_transparent.png" alt="TaskFlow Logo" width="128" height="128">
</p>

<p align="center">
  <strong>Intelligent Task Management for macOS</strong><br>
  Capture, organize, and complete tasks with AI-powered assistance
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.2.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey.svg" alt="Platform">
  <img src="https://img.shields.io/badge/swift-5.9-orange.svg" alt="Swift">
  <img src="https://img.shields.io/badge/license-Proprietary-red.svg" alt="License">
</p>

---

## ✨ Features

### 📋 Kanban Board
Organize your tasks visually with a beautiful drag-and-drop Kanban board featuring customizable columns:
- **To Do** - Tasks waiting to be started
- **In Progress** - Tasks you're actively working on
- **Done** - Completed tasks

### 📸 Screenshot Capture
Capture context directly from your screen:
- Press `⌘⇧C` to capture any area of your screen
- Screenshots are automatically attached to new tasks
- Visual context helps you remember what needs to be done

### 🤖 AI-Powered Task Titles
Let AI generate smart, action-oriented task titles:
- Powered by local LLM (Ollama with gemma3:1b)
- Analyzes screenshot content to suggest relevant titles
- 100% offline - your data never leaves your Mac

### 📅 Annual Calendar (NEW in v1.2.0)
Plan your year with a comprehensive annual calendar view:
- **12-month grid layout** - See your entire year at a glance
- **10 color-coded categories** - Organize events with cyberpunk-styled colors
- **Multi-day events** - Create events spanning multiple days
- **Task activity indicators** - See daily task additions (↑) and completions (↓)
- **Year selector** - Navigate years 2025-2035
- **Keyboard navigation** - Arrow keys, Enter, and Escape support
- **Category customization** - Edit category names to fit your workflow

### ⏱️ Pomodoro Timer
Built-in time tracking with Pomodoro technique:
- Configurable work and break intervals
- Visual countdown timer
- Automatic break reminders

### 📧 Outlook Integration
Capture emails as tasks (optional):
- Drag and drop `.eml` files directly into TaskFlow
- Automatically extracts subject and content
- Creates tasks from email threads

### 🎨 Cyberpunk Theme
A stunning dark theme with neon accents:
- Easy on the eyes for long work sessions
- Consistent styling throughout the app
- Subtle animations and hover effects

### 🔒 100% Offline & Private
Your data stays on your Mac:
- All data stored locally in SQLite
- AI runs entirely on-device via Ollama
- No cloud sync, no telemetry, no tracking

---

## 📥 Installation

### Requirements
- macOS 13 (Ventura) or later
- Apple Silicon (M1/M2/M3) or Intel Mac
- 5GB free disk space (for AI model)

### Quick Install
1. Download the latest DMG from [Releases](../../releases)
2. Open the DMG and drag `TaskFlow.app` to Applications
3. Right-click → Open (required for first launch)
4. Grant Screen Recording permission when prompted

### Full Install (with AI Features)
1. Download the DMG and open it
2. Run `install-taskflow.sh` in Terminal
3. The installer will set up Ollama and download the AI model

### First Launch Security Note
macOS may show: *"Apple could not verify TaskFlow"*

This is normal for apps outside the App Store. To open:
- **Right-click** → **Open** → Click **Open** in the dialog

---

## 🎮 Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘⇧C` | Capture screenshot for new task |
| `⌘N` | New task |
| `⌘,` | Open settings |
| `⌘Q` | Quit TaskFlow |
| `Arrow Keys` | Navigate calendar (in Annual view) |
| `Enter` | Create/edit event (in Annual view) |
| `Escape` | Cancel/deselect |

---

## 🛠️ Building from Source

### Prerequisites
- Xcode 15+ or Swift 5.9+
- macOS 13+

### Build Commands
```bash
# Clone the repository
git clone https://github.com/Pezz-OneNil/TaskFlow.git
cd TaskFlow/TaskFlow

# Build release version
swift build -c release

# Build app bundle with DMG
./build-app.sh --dmg

# Install to Applications
cp -r TaskFlow.app /Applications/
```

---

## 📁 Project Structure

```
TaskFlow/
├── Sources/
│   ├── TaskFlow/           # Main app entry point
│   └── TaskFlowLib/        # Core library
│       ├── Models/         # Data models
│       ├── Views/          # SwiftUI views
│       ├── Services/       # Business logic
│       └── Persistence/    # Database layer
├── Tests/                  # Unit & property tests
├── Resources/              # App icons & assets
└── Installer/              # DMG creation scripts
```

---

## 🔄 Version History

### v1.2.0 (Current)
- ✨ **Annual Calendar** - Full year planning with colored events
- 🎨 10 cyberpunk-styled event categories
- 📊 Task activity indicators on calendar days
- ⌨️ Keyboard navigation support
- 🔧 Settings toggle for Annual Calendar tab

### v1.1.0
- 📧 Outlook email integration
- 🎯 Multi-select task deletion
- 🐛 Bug fixes and performance improvements

### v1.0.0
- 🚀 Initial release
- 📋 Kanban board with drag-and-drop
- 📸 Screenshot capture
- 🤖 AI-powered task titles
- ⏱️ Pomodoro timer

---

## 📄 License

TaskFlow is proprietary software.

© 2025 Pezz. All rights reserved.

This software is protected by copyright law and international treaties. Unauthorized copying, modification, distribution, or use of this software is strictly prohibited.

---

## 🙏 Acknowledgments

- [GRDB.swift](https://github.com/groue/GRDB.swift) - SQLite toolkit for Swift
- [Ollama](https://ollama.ai) - Local LLM runtime
- [Google Gemma](https://ai.google.dev/gemma) - AI model for task title generation

---

<p align="center">
  Made with ❤️ for productivity enthusiasts
</p>
