# Implementation Plan: TaskFlow App

## Overview

This implementation plan documents the TaskFlow macOS application development. The app provides intelligent screen capture across multiple monitors, task management, Pomodoro timing, and Kanban organization with local LLM integration via Ollama.

## Completed Tasks

### Phase 1: Core Infrastructure (Complete)

- [x] 1. Project structure and core data models
- [x] 2. Persistence layer with SQLite and backup
- [x] 3. Task Manager implementation
- [x] 4. Priority Scheduler implementation
- [x] 5. Pomodoro Engine implementation
- [x] 6. Screen Capture Engine (single monitor)
- [x] 7. Text Extractor with OCR
- [x] 8. Search Term Generator
- [x] 9. UI Theme and Styling (Cyberpunk)
- [x] 10. Task List View
- [x] 11. Pomodoro Timer View
- [x] 12. Kanban Board View
- [x] 13. Main Window and Navigation
- [x] 14. Permission Handling

### Phase 2: Enhanced Features (Complete)

- [x] 15. Extended Task model
- [x] 16. Screenshot Manager
- [x] 17. LLM Summarizer with Ollama
- [x] 18. Transparent Capture Overlay
- [x] 19. Task Creation Flow
- [x] 20. Screenshot Viewer
- [x] 21. Task Completion/Deletion
- [x] 22. Kanban Deleted column
- [x] 23. Task Detail View

### Phase 3: Status Bar and Kanban (Complete)

- [x] 24. Status Bar Manager
- [x] 25. Status Bar View
- [x] 26. Status Bar integration
- [x] 27. Kanban drag-and-drop
- [x] 28. Kanban task click to edit
- [x] 29. Capture flow fixes

### Phase 4: Multi-Monitor Support (Complete)

- [x] 30. Multi-monitor capture overlay
- [x] 31. AppKit-based overlay views
- [x] 32. Coordinate conversion
- [x] 33. Escape key handling

### Phase 5: LLM Optimization (Complete)

- [x] 34. Model warmup at startup
- [x] 35. Optimized model selection
- [x] 36. Performance options

### Phase 6: UI Refinements and Model Selection (Complete)

- [x] 37. Settings Manager for persisting user preferences
- [x] 38. Model selector dropdown in UI
- [x] 39. Dynamic model list from Ollama
- [x] 40. App code signing for permission persistence
- [x] 41. Updated time estimates (10, 20, 40, 60, 60+ min)
- [x] 42. Removed page titles (Tasks, Pomodoro, Kanban Board)
- [x] 43. Pomodoro pulls tasks from Kanban columns (Backlog, In Progress, Blocked)
- [x] 44. Double-click to edit task in Pomodoro view

### Phase 7: Task Assignment, Screenshot Replacement, and Search (Complete)

- [x] 45. Add assignedTo field to Task model
  - Added optional String field for person/company name
  - _Requirements: 10.1_

- [x] 46. Implement AssigneeManager service
  - Persists assignee names using UserDefaults
  - Provides autocomplete suggestions sorted alphabetically
  - _Requirements: 10.2, 10.3, 10.5_

- [x] 47. Add Assigned To field to TaskDetailView
  - Text field with autocomplete dropdown
  - Shows suggestions as user types
  - Saves new names for future autocomplete
  - _Requirements: 10.1, 10.2_

- [x] 48. Display assignee in task cards
  - Shows person icon and name in TaskRowView
  - Shows person icon and name in KanbanTaskCard
  - _Requirements: 10.4_

- [x] 49. Implement screenshot replacement in TaskDetailView
  - Add/Replace button in screenshot section
  - File picker for selecting new image
  - Runs OCR on new image
  - Updates task screenshotId
  - Loading indicator during processing
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 50. Implement search bar in MainWindowView
  - Search input field in tab bar
  - Clear button to remove filters
  - Visual indicator when search is active
  - _Requirements: 12.1, 12.4, 12.5_

- [x] 51. Implement search filtering
  - filterTasks function searches across all relevant fields
  - Case-insensitive matching
  - Applies to Task List and Kanban Board views
  - _Requirements: 12.2, 12.3, 12.6, 12.7_

- [x] 52. Update TaskListView with search support
  - Accept searchQuery and filterTasks parameters
  - Display search results indicator
  - _Requirements: 12.4, 12.7_

- [x] 53. Update KanbanBoardView with search support
  - Accept searchQuery and filterTasks parameters
  - Display search results indicator
  - _Requirements: 12.4, 12.7_

### Phase 8: App Icon and Branding (Complete)

- [x] 54. Create app icon resources directory
  - Created Resources/AppIcon.iconset/ directory structure
  - _Requirements: 13.6_

- [x] 55. Process source icon image
  - Converted white background to transparent using PIL
  - Saved as AppIcon_transparent.png
  - _Requirements: 13.5_

- [x] 56. Generate all required icon sizes
  - Generated 10 icon files (16x16 through 1024x1024 with retina variants)
  - Used sips command for resizing
  - _Requirements: 13.6_

- [x] 57. Create .icns bundle
  - Converted iconset to AppIcon.icns using iconutil
  - _Requirements: 13.7_

- [x] 58. Update build script
  - Added copy of AppIcon.icns to app bundle Resources directory
  - _Requirements: 13.3, 13.7_

- [x] 59. Configure Info.plist
  - Set CFBundleIconFile to "AppIcon"
  - _Requirements: 13.1, 13.2, 13.3_

- [x] 60. Verify icon display
  - Confirmed icon displays correctly in Dock
  - Confirmed icon displays correctly in Launchpad
  - Confirmed no white border (transparent background working)
  - _Requirements: 13.1, 13.2, 13.4, 13.5_

### Phase 9: Window Hiding and Menu Bar Integration (Complete)

- [x] 61. Implement window hiding during capture
  - Added mainWindow state variable with WindowAccessor helper
  - hideMainWindow() hides window before capture overlay
  - restoreMainWindow() restores window after capture completes/cancels
  - Added delay between hiding and showing overlay
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6_

- [x] 62. Create MenuBarManager service
  - Created MenuBarManager.swift in Services directory
  - Uses NSStatusBar.system.statusItem for menu bar presence
  - TaskFlow app icon (scaled to 18x18) as menu bar icon
  - Dropdown menu with capture, show app, and quit options
  - Loading overlay with animated spinner during capture processing
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 15.9_

- [x] 63. Integrate MenuBarManager with app lifecycle
  - Initialize MenuBarManager in TaskFlowApp.onAppear
  - Menu bar capture triggers same flow as main window capture
  - Uses NotificationCenter for cross-component communication
  - _Requirements: 15.7, 15.8_

- [x] 64. Update capture flow for window restoration
  - Added CaptureCompleted notification
  - Window restored on both success and cancel paths
  - App activated and brought to front after capture
  - _Requirements: 14.3, 14.4, 14.6_

- [x] 65. Update spec documentation
  - Added Requirements 14 and 15 to requirements.md
  - Added Menu Bar Manager interface to design.md
  - Added Window Hiding interface to design.md
  - Added Properties 26-28 to design.md
  - Added Phase 9 tasks to tasks.md
  - _Requirements: Documentation_

### Phase 10: Bug Fixes and UI Polish (Complete)

- [x] 66. Fix Pomodoro skip button functionality
  - Added skippedTaskIds Set to track skipped tasks during session
  - skipCurrentTask() now adds task to skipped set before advancing
  - refreshTaskQueue() filters out skipped tasks
  - Skipped tasks cleared when new session starts
  - _Requirements: 16.1, 16.2, 16.3, 16.4_

- [x] 67. Fix Pomodoro tab window sizing
  - Added GeometryReader to PomodoroTimerView body
  - Content fills available space with frame(width:height:)
  - Added Spacer() elements to center content vertically
  - Window no longer resizes when switching to Pomodoro tab
  - _Requirements: 17.1, 17.2, 17.3_

### Phase 11: Distribution and Installer (Complete)

- [x] 68. Create installer shell script
  - Interactive CLI installer with colored output
  - System requirements check (macOS 13+, disk space, architecture)
  - Ollama installation if not present
  - LLM model selection menu with descriptions and sizes
  - Model download with progress indication
  - TaskFlow.app installation to /Applications
  - Quarantine attribute removal
  - Permission configuration guidance
  - Post-installation summary and launch option
  - _Requirements: Offline operation, easy distribution_

- [x] 69. Create DMG packaging script
  - Builds TaskFlow.app if not present
  - Creates distributable DMG with app and installer
  - Outputs to dist/TaskFlow-Installer-{version}.dmg
  - _Requirements: Easy distribution_

- [x] 70. Create installer README
  - Installation options (full vs quick)
  - System requirements
  - Included LLM models
  - Troubleshooting guide
  - _Requirements: User documentation_

- [x] 71. Update design documentation
  - Added Distribution and Installation section
  - Documented installer features and flow
  - Added installer flow diagram
  - _Requirements: Documentation_

### Phase 12: Immediate Task Creation with Parallel Processing (Complete)

- [x] 72. Update capture flow for immediate display
  - Screenshot captured and task creation sheet shown immediately
  - Removed blocking processing overlay
  - Window restored before showing sheet
  - _Requirements: 19.1_

- [x] 73. Update TaskCreationSheet for parallel processing
  - Added ProcessingState enum for tracking async operations
  - Added processing indicators in header (OCR, AI Title, AI Summary)
  - OCR, title generation, and description generation run in parallel
  - User can edit fields while processing happens
  - _Requirements: 19.2, 19.8, 19.9_

- [x] 74. Implement LLM title suggestion behavior
  - Title field shows placeholder for AI suggestion
  - LLM-generated title shown as clickable suggestion below field
  - User can tap suggestion to use it
  - If user leaves title empty, LLM title used on create
  - _Requirements: 19.6, 19.7, 2B.13_

- [x] 75. Update LLM title generation prompt
  - Prompt now emphasizes verbs and action words
  - Suggests starting with action verbs (Review, Complete, Send, etc.)
  - _Requirements: 2B.12_

- [x] 76. Implement LLM description generation
  - Added generateDescription() method to LLMSummarizer
  - Generates 2-3 sentence contextual summary
  - Interprets context and suggests user action
  - Fallback to first few lines if LLM unavailable
  - _Requirements: 19.3, 19.4_

- [x] 77. Update spec documentation
  - Added Requirement 19 to requirements.md
  - Updated LLM Summarizer interface in design.md
  - Added Task Creation Sheet interface to design.md
  - Updated Screen Capture Processing Flow diagram
  - Added Properties 29-33 to design.md
  - _Requirements: Documentation_

## Current State

All features implemented and working including:
- Task assignment tracking with autocomplete
- Screenshot replacement/addition in task detail view
- Global search and filtering across all task fields
- Custom cyberpunk-themed app icon with transparent background
- Window hiding during capture for single-monitor setups
- Menu bar integration for quick task creation
- Pomodoro skip button properly advances to next task
- Consistent window sizing across all tabs
- Complete installer package for distribution
- Immediate task creation with parallel OCR/LLM processing
- Action-oriented LLM title generation with verb focus
- Contextual AI-generated descriptions
- gemma3:1b as the default and only LLM model
- First-capture bug fix using item-based sheet binding (v1.0.2)
- Schema version tracking and migration history
- Pre-migration automatic backups
- Settings tab with Backup & Restore UI
- Manual backup creation, import, export, and restore
- User-friendly database error handling with recovery options
- Backups include screenshots as zip archives (v1.0.4)
- Backup retention policy: 5 manual, 14 daily, unlimited pre-migration
- Daily automatic backups for data safety
- Screenshot persistence fix - screenshots now properly saved before task creation (v1.0.5)
- Restored tasks now return to active list (kanbanColumn = nil) instead of staying on Kanban
- Test suite fully passing (32 tests) with accurate documentation and meaningful coverage
- Email drag-and-drop for task creation with furtherDetails populated from email body
- "How to Use TaskFlow" guidance in About tab

### Phase 13: Model Standardization (Complete)

- [x] 78. Update LLMSummarizer to use gemma3:1b as default
  - Changed defaultModel to "gemma3:1b"
  - Updated fallback models to gemma3 variants only
  - _Requirements: 2B.6_

- [x] 79. Simplify installer for single model
  - Removed model selection menu
  - Automatically downloads gemma3:1b
  - Reduced disk space requirement to 5GB
  - _Requirements: 18.4, 18.5_

- [x] 80. Update README.txt
  - Updated model information to gemma3:1b only
  - Simplified troubleshooting section
  - _Requirements: Documentation_

- [x] 81. Update spec documentation
  - Updated requirements.md with gemma3:1b references
  - Updated design.md LLM Summarizer interface
  - Updated design.md installer documentation
  - Added Phase 13 to tasks.md
  - _Requirements: Documentation_

### Phase 14: First-Capture Bug Fix (Complete)

- [x] 82. Fix OCR/LLM not loading on first screen capture
  - Changed from sheet(isPresented:) to sheet(item:) binding pattern
  - Created CapturedScreenshotItem struct wrapping screenshot with Identifiable
  - Screenshot now passed directly through item binding, guaranteeing availability
  - Eliminates SwiftUI state propagation race condition
  - _Requirements: 19.1, 19.10_

- [x] 83. Update spec documentation
  - Added Requirement 19.10 for first-capture reliability
  - Added CapturedScreenshotItem interface to design.md
  - Added Property 34 for first-capture screenshot availability
  - Added Phase 14 to tasks.md
  - _Requirements: Documentation_

- [x] 84. Create updated DMG v1.0.2
  - Built and tested fix
  - Created TaskFlow-Installer-1.0.2.dmg
  - _Requirements: Distribution_

### Phase 15: Data Migration and Upgrade Safety (Complete)

- [x] 85. Implement schema version tracking
  - Added schema_info table to track current version
  - Added migration_history table to record applied migrations
  - CURRENT_SCHEMA_VERSION constant for version management
  - _Requirements: 20.1, 20.3_

- [x] 86. Implement pre-migration backup
  - Automatic backup created before any schema upgrade
  - Backup path stored in MigrationResult for user reference
  - _Requirements: 20.2_

- [x] 87. Update DatabaseManager with versioned migrations
  - createSchemaWithMigrations() replaces old createSchema()
  - Migrations run in order: v1_base_schema, v2_additional_columns
  - Each migration recorded in migration_history
  - MigrationResult struct for reporting success/failure
  - _Requirements: 20.1, 20.3, 20.4_

- [x] 88. Enhance BackupManager with UI support
  - Added BackupInfo struct with formatted date/size
  - Added availableBackups published property
  - Added isCreatingBackup and isRestoring state
  - Added exportBackup() and importBackup() methods
  - Added deleteBackup() method
  - _Requirements: 20.6, 20.7, 20.8, 20.12_

- [x] 89. Create BackupRestoreView
  - Settings tab with Backup & Restore UI
  - Shows database status (schema version, last backup, task count)
  - Create Backup button with success/error feedback
  - Import Backup from file picker
  - List of available backups with restore/export/delete actions
  - Restore confirmation dialog with warning
  - Open Backup Folder button
  - _Requirements: 20.6, 20.7, 20.8, 20.9, 20.10_

- [x] 90. Create DatabaseErrorView
  - User-friendly error display for database issues
  - Shows migration details when migration fails
  - Recovery options: Retry, Restore from Backup, Open Folder, Quit
  - Backup location info for manual recovery
  - _Requirements: 20.5, 20.11_

- [x] 91. Add Settings tab to MainWindowView
  - Added NavigationTab.settings case
  - Added backupManager parameter to MainWindowView
  - Settings tab shows BackupRestoreView
  - _Requirements: 20.6_

- [x] 92. Update TaskRecord for assigned_to column
  - Added assignedTo field to TaskRecord
  - Updated CodingKeys with assigned_to mapping
  - Updated init and toTask conversion
  - _Requirements: Schema consistency_

- [x] 93. Implement screenshot inclusion in backups
  - Backups now created as zip archives containing tasks.json and screenshots/
  - Added ZipManifest struct for backup metadata (taskCount, screenshotCount)
  - createZipBackup() copies all referenced screenshots to archive
  - restoreFromZipBackup() extracts and restores screenshots to Screenshots directory
  - _Requirements: 20.13_

- [x] 94. Implement backup retention policy
  - Added BackupType enum (manual, daily, preMigration)
  - Manual backups limited to 5 (oldest deleted when exceeded)
  - Daily backups kept for 14 days (one per day)
  - Pre-migration backups kept indefinitely
  - cleanupOldBackups() enforces retention policy after each backup
  - _Requirements: 20.14, 20.15, 20.16_

- [x] 95. Implement daily backup scheduling
  - Added startDailyBackupSchedule() - checks hourly if daily backup needed
  - createDailyBackupIfNeeded() creates backup if none exists for today
  - Replaced periodic 5-minute backups with daily backup schedule
  - _Requirements: 20.15_

- [x] 96. Update BackupRestoreView for new backup info
  - Display backup type badge (Manual/Daily/Pre-Migration)
  - Show screenshot count in backup row
  - Different icon for zip vs json backups
  - Color-coded type badges (purple/cyan/magenta)
  - Support import/export of both .json and .zip files
  - _Requirements: 20.13, UI enhancement_

- [x] 97. Update spec documentation
  - Added Backup Manager Interface to design.md
  - Added Properties 39-41 for backup features
  - Added Phase 15 continuation tasks (93-97) to tasks.md
  - _Requirements: Documentation_

### Phase 16: UI Field Ordering (Complete)

- [x] 98. Reorder task editor fields
  - Moved "Further Details (from OCR)" to bottom of TaskDetailView
  - Moved "Further Details (from OCR)" to bottom of TaskCreationSheet
  - New order: Screenshot, Title, Description, (Assigned To), Time Estimate, Priority, Further Details
  - _Requirements: 21.1, 21.2, 21.3_

- [x] 99. Update spec documentation
  - Added Requirement 21 for task editor field ordering
  - Added Phase 16 to tasks.md
  - _Requirements: Documentation_

### Phase 17: Screenshot Persistence Fix (Complete)

- [x] 100. Fix screenshot disappearing after task creation
  - Root cause: CapturedScreenshotItem.id was a random UUID used for SwiftUI sheet binding, not the actual saved screenshot ID
  - Screenshot was saved in TaskCreationSheet with a different UUID than passed to the task
  - Fix: Save screenshot in MainWindowView.processCapture() BEFORE showing sheet, use returned ID
  - TaskCreationSheet now uses existing screenshot ID instead of saving again
  - _Requirements: 2A.1, 19.1, 19.10_

- [x] 101. Update version to 1.0.5
  - Incremented version in AppInfo.swift
  - Created TaskFlow-Installer-1.0.5.dmg
  - _Requirements: Distribution_

### Phase 18: Bug Fixes and Test Improvements (Complete)

- [x] 102. Fix restored tasks not returning to active list
  - Changed restoreFromDeleted() to set kanbanColumn = nil instead of .backlog
  - Restored tasks now re-enter the active task list and Pomodoro prioritization
  - Previously, restored tasks remained on Kanban board and were excluded from active filtering
  - _Requirements: 4.5, 5.1_

- [x] 103. Fix TimeEstimate documentation discrepancy in tests
  - Updated TaskFieldBoundsTests.swift docstring from [15, 30, 45, 60, 90] to [10, 20, 40, 60, 90]
  - Updated expected values to match actual TimeEstimate enum
  - Updated TestRunner Property 4 docstring and expected values
  - _Requirements: 3.1, Documentation consistency_

- [x] 104. Replace placeholder test with meaningful tests
  - Removed trivial `#expect(true)` assertion from TaskFlowTests.swift
  - Added PriorityScheduler ordering test (verifies high priority before low)
  - Added Task default values test (verifies priority, timeEstimate, kanbanColumn defaults)
  - Converted from Swift Testing to XCTest framework for consistency
  - _Requirements: Test coverage_

- [x] 105. Fix branding consistency in spec documents
  - Changed "Task Flow" to "TaskFlow" in requirements.md
  - Changed "Task Flow" to "TaskFlow" in design.md
  - Changed "Task Flow" to "TaskFlow" in tasks.md
  - _Requirements: Branding consistency_

- [x] 106. Update TestRunner tests for Pomodoro/restore behavior
  - Fixed Property 7 test to move tasks to Kanban backlog before starting Pomodoro
  - Pomodoro pulls from Kanban columns, not active task list
  - Fixed Integration tests to expect kanbanColumn = nil after restore instead of .backlog
  - All 32 tests now pass
  - _Requirements: 4.5, 5.1, Test accuracy_

## Build Commands

```bash
cd TaskerApp/TaskFlow
swift build -c release
./build-app.sh
cp -r TaskFlow.app /Applications/
open /Applications/TaskFlow.app
```

## Distribution Commands

```bash
# Create distributable DMG
cd TaskerApp/TaskFlow/Installer
./create-dmg.sh

# Output: TaskerApp/TaskFlow/dist/TaskFlow-Installer-1.0.0.dmg
```

The DMG contains:
- `TaskFlow.app` - The application
- `install-taskflow.sh` - Interactive installer (auto-installs gemma3:1b)
- `README.txt` - Installation instructions
