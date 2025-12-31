<![CDATA[<div align="center">

# ⚡ TASKFLOW ⚡

<img src="Resources/AppIcon_transparent.png" alt="TaskFlow Logo" width="180" height="180">

### 「 INTELLIGENT TASK MANAGEMENT FOR macOS 」

*Capture • Organize • Conquer*

[![Version](https://img.shields.io/badge/VERSION-1.2.0-00F5FF?style=for-the-badge&labelColor=0D0D0D)](../../releases)
[![Platform](https://img.shields.io/badge/macOS-13%2B-FF006E?style=for-the-badge&labelColor=0D0D0D)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/SWIFT-5.9-FFE66D?style=for-the-badge&labelColor=0D0D0D)](https://swift.org)
[![License](https://img.shields.io/badge/LICENSE-Proprietary-9D4EDD?style=for-the-badge&labelColor=0D0D0D)](LICENSE)

---

```
╔══════════════════════════════════════════════════════════════════╗
║  ████████╗ █████╗ ███████╗██╗  ██╗███████╗██╗      ██████╗ ██╗    ║
║  ╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝██╔════╝██║     ██╔═══██╗██║    ║
║     ██║   ███████║███████╗█████╔╝ █████╗  ██║     ██║   ██║██║    ║
║     ██║   ██╔══██║╚════██║██╔═██╗ ██╔══╝  ██║     ██║   ██║██║    ║
║     ██║   ██║  ██║███████║██║  ██╗██║     ███████╗╚██████╔╝███████║
║     ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝ ╚══════╝
╚══════════════════════════════════════════════════════════════════╝
```

</div>

---

## 🌆 FEATURES

<table>
<tr>
<td width="50%">

### 📋 KANBAN BOARD
```
┌─────────┬─────────┬─────────┐
│ BACKLOG │ TO DO   │ IN PROG │
├─────────┼─────────┼─────────┤
│ ▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓▓ │
│ ▓▓▓▓▓▓▓ │ ▓▓▓▓▓▓▓ │         │
│         │         │         │
└─────────┴─────────┴─────────┘
```
Drag-and-drop task management with responsive columns that adapt to any window size.

</td>
<td width="50%">

### 📅 ANNUAL CALENDAR
```
┌───┬───┬───┬───┬───┬───┐
│JAN│FEB│MAR│APR│MAY│JUN│
├───┼───┼───┼───┼───┼───┤
│▓▓▓│   │▓▓▓▓▓▓▓│   │▓▓▓│
│   │▓▓▓│       │▓▓▓│   │
└───┴───┴───┴───┴───┴───┘
```
Full year planning with 10 cyberpunk color categories, drag-to-move, and drag-to-resize events.

</td>
</tr>
<tr>
<td>

### 📸 SCREENSHOT CAPTURE
Press `⌘⇧C` to capture any screen area. Screenshots auto-attach to new tasks for visual context.

</td>
<td>

### 🤖 AI-POWERED TITLES
Local LLM generates smart task titles from screenshots. 100% offline via Ollama.

</td>
</tr>
<tr>
<td>

### ⏱️ POMODORO TIMER
Built-in time tracking with configurable work/break intervals and visual countdown.

</td>
<td>

### 📧 OUTLOOK INTEGRATION
Drag `.eml` files to create tasks from emails. Extracts subject and content automatically.

</td>
</tr>
</table>

---

## 🎨 CYBERPUNK AESTHETIC

<div align="center">

| Color | Name | Hex |
|:---:|:---|:---:|
| 🟣 | Neon Pink | `#FF006E` |
| 🔵 | Electric Blue | `#00F5FF` |
| 🟢 | Acid Green | `#39FF14` |
| 🟠 | Hot Orange | `#FF6B35` |
| 🟣 | Deep Purple | `#9D4EDD` |
| 🟡 | Golden Yellow | `#FFE66D` |
| 🔴 | Crimson Red | `#DC143C` |
| 🟢 | Mint Green | `#00FF7F` |
| 🔵 | Sky Blue | `#87CEEB` |
| 🟣 | Lavender | `#E6E6FA` |

</div>

---

## 🔒 PRIVACY FIRST

```
╔═══════════════════════════════════════════════════════════╗
║  ██████╗ ███████╗███████╗██╗     ██╗███╗   ██╗███████╗   ║
║ ██╔═══██╗██╔════╝██╔════╝██║     ██║████╗  ██║██╔════╝   ║
║ ██║   ██║█████╗  █████╗  ██║     ██║██╔██╗ ██║█████╗     ║
║ ██║   ██║██╔══╝  ██╔══╝  ██║     ██║██║╚██╗██║██╔══╝     ║
║ ╚██████╔╝██║     ██║     ███████╗██║██║ ╚████║███████╗   ║
║  ╚═════╝ ╚═╝     ╚═╝     ╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝   ║
╚═══════════════════════════════════════════════════════════╝
```

- **Local SQLite Database** — All data stays on your Mac
- **On-Device AI** — Ollama runs entirely locally
- **Zero Telemetry** — No tracking, no cloud sync, no data collection
- **Full Backup Control** — Export/import your data anytime

---

## 📥 INSTALLATION

### Requirements
```
┌────────────────────────────────────┐
│ • macOS 13 (Ventura) or later      │
│ • Apple Silicon or Intel Mac       │
│ • 5GB free space (for AI model)    │
└────────────────────────────────────┘
```

### Quick Install
1. Download the latest DMG from [**Releases**](../../releases)
2. Open DMG → Drag `TaskFlow.app` to Applications
3. Right-click → **Open** (required for first launch)
4. Grant Screen Recording permission when prompted

### Full Install (with AI)
```bash
# Open the DMG and run:
./install-taskflow.sh
```
The installer sets up Ollama and downloads the AI model automatically.

> ⚠️ **First Launch:** macOS may show *"Apple could not verify TaskFlow"*  
> This is normal. Right-click → Open → Click Open in the dialog.

---

## ⌨️ KEYBOARD SHORTCUTS

<div align="center">

| Shortcut | Action |
|:---:|:---|
| `⌘⇧C` | Capture screenshot |
| `⌘N` | New task |
| `⌘,` | Settings |
| `⌘Q` | Quit |
| `←` `→` `↑` `↓` | Navigate calendar |
| `Enter` | Create/edit event |
| `Escape` | Cancel/deselect |

</div>

---

## 🛠️ BUILD FROM SOURCE

```bash
# Clone
git clone https://github.com/Pezz-OneNil/TaskFlow.git
cd TaskFlow/TaskFlow

# Build release
swift build -c release

# Build app bundle + DMG
./build-app.sh --dmg

# Install
cp -r TaskFlow.app /Applications/
```

---

## 📁 PROJECT STRUCTURE

```
TaskFlow/
├── Sources/
│   ├── TaskFlow/           # App entry point
│   └── TaskFlowLib/        # Core library
│       ├── Models/         # Data models
│       ├── Views/          # SwiftUI views
│       ├── Services/       # Business logic
│       └── Persistence/    # Database layer
├── Tests/                  # Unit & property tests
├── Resources/              # Icons & assets
└── Installer/              # DMG scripts
```

---

## 📜 VERSION HISTORY

<div align="center">

### `v1.2.0` — CURRENT

</div>

```diff
+ Annual Calendar — Full year planning with colored events
+ 10 Cyberpunk Categories — Customizable event colors
+ Drag-to-Move Events — Reschedule by dragging
+ Drag-to-Resize Events — Extend/shrink duration by dragging edge
+ Task Activity Indicators — See ↑added/↓completed per day
+ Multi-Event Day Popover — Access all events on busy days
+ Calendar Backup Integration — Events included in backups
+ Responsive Tab Bar — Icons-only mode at narrow widths
+ Responsive Kanban — Equal-width columns at any size
+ Keyboard Navigation — Arrow keys, Enter, Escape
```

<div align="center">

### `v1.1.0`

</div>

```diff
+ Outlook email integration
+ Multi-select task deletion
+ Bug fixes & performance improvements
```

<div align="center">

### `v1.0.0`

</div>

```diff
+ Initial release
+ Kanban board with drag-and-drop
+ Screenshot capture
+ AI-powered task titles
+ Pomodoro timer
```

---

## 📄 LICENSE

```
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   TaskFlow is proprietary software.                               ║
║                                                                   ║
║   © 2025 Pezz. All rights reserved.                               ║
║                                                                   ║
║   This software is protected by copyright law and international   ║
║   treaties. Unauthorized copying, modification, distribution,     ║
║   or use is strictly prohibited.                                  ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

## 🙏 ACKNOWLEDGMENTS

- [**GRDB.swift**](https://github.com/groue/GRDB.swift) — SQLite toolkit
- [**Ollama**](https://ollama.ai) — Local LLM runtime
- [**Google Gemma**](https://ai.google.dev/gemma) — AI model

---

<div align="center">

```
═══════════════════════════════════════════════════════════════
                Made with ⚡ for productivity enthusiasts
═══════════════════════════════════════════════════════════════
```

**[⬆ Back to Top](#-taskflow-)**

</div>
]]>