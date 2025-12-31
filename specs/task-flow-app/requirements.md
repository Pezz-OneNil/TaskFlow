# Requirements Document

## Introduction

TaskFlow is a macOS productivity application that combines intelligent screen capture, task management, Pomodoro timing, and Kanban organization. The app enables users to quickly capture information from any screen source (emails, messages, documents) across multiple monitors, synthesize it into actionable tasks with time and priority estimates, and manage their work sessions using timed focus periods with automatic task prioritization. The application features a modern cyberpunk-inspired dark UI with neon purple accents and uses local LLM models via Ollama for intelligent task title generation.

## Glossary

- **Task_Flow_App**: The main macOS application providing task and time management functionality
- **Screen_Capture_Engine**: The component responsible for capturing and processing screen content
- **Capture_Overlay_Controller**: The multi-monitor overlay system that enables screen region selection across all connected displays
- **Task_Manager**: The component that creates, stores, and organizes tasks
- **Pomodoro_Timer**: The timed focus session component based on the Pomodoro Technique
- **Kanban_Board**: The visual board for organizing tasks across their lifecycle (including completed and deleted)
- **Search_Term_Generator**: The component that extracts searchable keywords from task content
- **Persistence_Layer**: The component responsible for robust local data backup and recovery
- **Priority_Scheduler**: The component that automatically orders tasks based on time and priority
- **LLM_Summarizer**: The component that uses local Ollama models to generate task titles from OCR text
- **Ollama_Client**: The HTTP client for communicating with the local Ollama API
- **Screenshot_Manager**: The component that stores, retrieves, and crops task screenshots
- **Status_Bar**: The persistent UI component at the bottom of the main window that displays capture progress and errors
- **Status_Bar_Manager**: The service that manages status bar state transitions and messages
- **Settings_Manager**: The service that persists user preferences including selected LLM model
- **Assignee_Manager**: The service that manages and persists assignee names for autocomplete functionality
- **Search_Filter**: The component that filters tasks based on search queries across all task fields
- **Menu_Bar_Manager**: The service that manages the macOS menu bar status item for quick task creation
- **Menu_Bar_Icon**: The status item displayed in the macOS menu bar for TaskFlow
- **Menu_Bar_Menu**: The dropdown menu displayed when clicking the menu bar icon

## Requirements

### Requirement 1: Local Data Persistence

**User Story:** As a user, I want my tasks and app data to persist across device reboots, so that I never lose my work.

#### Acceptance Criteria

1. WHEN the application starts, THE Persistence_Layer SHALL load all previously saved tasks and settings from local storage
2. WHEN a task is created or modified, THE Persistence_Layer SHALL immediately persist the change to local storage
3. WHEN the application closes unexpectedly, THE Persistence_Layer SHALL ensure all data written up to that point is recoverable
4. THE Persistence_Layer SHALL store data in a human-readable format for manual recovery if needed
5. WHEN the application detects corrupted data, THE Persistence_Layer SHALL attempt recovery from the most recent valid backup

### Requirement 2: Multi-Monitor Screen Capture and Information Extraction

**User Story:** As a user, I want to capture information from any of my connected monitors with a single click, so that I can quickly create tasks from emails, messages, and documents regardless of which screen they're on.

#### Acceptance Criteria

1. WHEN the user clicks the capture button, THE Capture_Overlay_Controller SHALL display a semi-transparent overlay on ALL connected monitors simultaneously
2. WHEN overlays are displayed, THE Task_Flow_App SHALL allow the user to select a capture region on ANY of the connected monitors
3. WHEN a region is selected on any monitor, THE Screen_Capture_Engine SHALL capture that region accurately using the correct coordinate system for that display
4. WHEN screen content is captured, THE Screen_Capture_Engine SHALL extract text using OCR (Vision framework)
5. WHEN text is extracted, THE Screen_Capture_Engine SHALL identify key elements including sender, recipient, subject, and body content
6. WHEN extraction is complete, THE Task_Manager SHALL present the extracted information in a "Further Details" section for user review and editing
7. THE Screen_Capture_Engine SHALL support capture from email clients, Teams, Slack, calendar applications, and general documents
8. WHEN the user presses Escape during capture mode, THE Capture_Overlay_Controller SHALL cancel the capture and close all overlay windows
9. THE Capture_Overlay_Controller SHALL handle coordinate conversion between NSScreen coordinates (bottom-left origin) and CGWindowList coordinates (top-left origin) correctly for all monitor configurations

### Requirement 2A: Screenshot Storage and Cropping

**User Story:** As a user, I want to access and crop the original screenshot for any task, so that I can review the source information and refine what is stored.

#### Acceptance Criteria

1. WHEN a task is created from a screenshot, THE Task_Manager SHALL store the original screenshot image with the task
2. WHEN viewing a task, THE Task_Flow_App SHALL provide access to view the associated screenshot
3. WHEN viewing a screenshot, THE Task_Flow_App SHALL provide native cropping tools to refine the captured region
4. WHEN the user crops a screenshot, THE Task_Manager SHALL update the stored image and re-run OCR on the cropped region
5. IF a task has no associated screenshot, THE Task_Flow_App SHALL indicate this clearly in the task view

### Requirement 2B: LLM-Powered Task Title Generation

**User Story:** As a user, I want the app to automatically generate a task title from the captured content using a local LLM, so that I don't have to manually type titles while keeping my data private.

#### Acceptance Criteria

1. WHEN OCR text is extracted from a screenshot, THE LLM_Summarizer SHALL send the text to a local Ollama model for summarization
2. WHEN the LLM returns a summary, THE Task_Manager SHALL pre-populate the task title field with the generated summary
3. WHEN the LLM is unavailable or fails, THE Task_Manager SHALL fall back to using the first line of extracted text or leave the title empty
4. THE LLM_Summarizer SHALL use a locally-running Ollama model to ensure privacy and offline capability (no internet connection required)
5. WHEN a title is auto-generated, THE Task_Flow_App SHALL allow the user to edit or replace it before saving
6. THE LLM_Summarizer SHALL use gemma3:1b as the default model for quick title generation while maintaining quality
7. THE LLM_Summarizer SHALL use performance options (limited output tokens, lower temperature) to optimize response time
8. WHEN the application starts, THE LLM_Summarizer SHALL pre-warm the selected model to reduce first-request latency
9. THE Task_Flow_App SHALL provide a model selector dropdown in the UI to choose from available Ollama models
10. WHEN a model is selected, THE Settings_Manager SHALL persist the selection for future sessions
11. WHEN the application starts, THE LLM_Summarizer SHALL refresh the list of available models from Ollama
12. THE LLM_Summarizer SHALL focus on verbs and action words when generating task titles to make them actionable
13. WHEN the user does not provide a title, THE Task_Manager SHALL use the LLM-generated title as the task title

### Requirement 19: Immediate Task Creation with Parallel Processing

**User Story:** As a user, I want the task creation window to appear immediately after taking a screenshot, so that I can start editing while OCR and AI processing happen in the background.

#### Acceptance Criteria

1. WHEN a screenshot is captured, THE Task_Flow_App SHALL immediately display the task creation window with the screenshot visible
2. WHILE the task creation window is displayed, THE Screen_Capture_Engine SHALL run OCR processing in parallel with user interaction
3. WHILE the task creation window is displayed, THE LLM_Summarizer SHALL generate a contextual description summarizing the screenshot content
4. THE LLM_Summarizer SHALL interpret the context and suggest what action the user might need to take in the description
5. WHEN OCR processing completes, THE Task_Flow_App SHALL populate the "Further Details" field with the extracted text
6. WHEN LLM title generation completes, THE Task_Flow_App SHALL show the suggested title without overwriting user input
7. IF the user has not entered a title when creating the task, THE Task_Manager SHALL use the LLM-generated title
8. THE Task_Flow_App SHALL display processing indicators for OCR, AI Title, and AI Summary operations
9. THE Task_Flow_App SHALL allow the user to create the task at any time, even before processing completes
10. WHEN the task creation sheet is presented, THE Task_Flow_App SHALL ensure the screenshot is available to the sheet before processing begins (using item-based sheet binding)

### Requirement 3: Task Creation with Time and Priority

**User Story:** As a user, I want to quickly assign time estimates and priority levels to tasks, so that I can efficiently categorize my work.

#### Acceptance Criteria

1. WHEN creating a task, THE Task_Manager SHALL allow selection of time estimates: 10, 20, 40, 60, or greater than 60 minutes
2. WHEN creating a task, THE Task_Manager SHALL allow selection of priority levels: Low, Medium, or Mega
3. WHEN a task is created, THE Task_Manager SHALL store the task with its time estimate, priority, and captured content
4. THE Task_Manager SHALL provide quick-select UI elements for rapid time and priority assignment
5. WHEN a task is created without explicit values, THE Task_Manager SHALL default to 20 minutes and Medium priority

### Requirement 4: Pomodoro Timer with Auto-Prioritization

**User Story:** As a user, I want to start timed focus sessions that automatically prioritize my tasks from my Kanban board, so that I can work efficiently on what matters most.

#### Acceptance Criteria

1. WHEN the user starts a Pomodoro session, THE Pomodoro_Timer SHALL begin a configurable countdown timer
2. WHILE a session is active, THE Priority_Scheduler SHALL pull tasks from Kanban Backlog, In Progress, and Blocked columns
3. WHILE a session is active, THE Priority_Scheduler SHALL order tasks by priority (Mega > Medium > Low) then by time estimate (shortest first within same priority)
4. WHEN the remaining session time changes, THE Priority_Scheduler SHALL recalculate which tasks fit in the remaining time
5. WHEN a task is marked complete during a session, THE Priority_Scheduler SHALL automatically advance to the next prioritized task
6. WHEN the session timer expires, THE Pomodoro_Timer SHALL notify the user and pause task progression
7. THE Pomodoro_Timer SHALL display remaining time prominently during active sessions
8. WHEN the user double-clicks the current task card in Pomodoro view, THE Task_Flow_App SHALL open the task detail view for editing

### Requirement 5: Kanban Board for Task Lifecycle

**User Story:** As a user, I want tasks to automatically move to the Kanban board when completed or deleted, so that I can track all task outcomes visually.

#### Acceptance Criteria

1. WHEN the user moves a task to the Kanban board manually, THE Kanban_Board SHALL accept and display the task in the appropriate column
2. THE Kanban_Board SHALL provide columns for: Backlog, In Progress, Blocked, Done, and Deleted
3. WHEN a task is on the Kanban board, THE Task_Manager SHALL exclude it from Pomodoro session prioritization
4. WHEN the user moves a task from Kanban back to the task list, THE Task_Manager SHALL include it in session prioritization
5. THE Kanban_Board SHALL allow drag-and-drop movement between columns using native macOS drag gestures
6. WHEN the user marks a task as complete from the task list, THE Task_Manager SHALL automatically move it to the Kanban "Done" column
7. WHEN the user deletes a task from the task list, THE Task_Manager SHALL move it to the Kanban "Deleted" column instead of permanently removing it
8. WHEN viewing the Kanban board, THE Task_Flow_App SHALL visually distinguish the "Deleted" column from other columns
9. WHEN a task card is dragged over a different column, THE Kanban_Board SHALL provide visual feedback indicating the drop target
10. WHEN a task card is dropped on a valid column, THE Task_Manager SHALL immediately update the task's kanbanColumn and persist the change
11. WHEN a task card is clicked in the Kanban board, THE Task_Flow_App SHALL open the task detail view for editing

### Requirement 6: Search Term Generation

**User Story:** As a user, I want to copy search terms for a task to my clipboard, so that I can quickly find related content in Outlook, Teams, or Slack.

#### Acceptance Criteria

1. WHEN the user clicks the search button on a task, THE Search_Term_Generator SHALL extract relevant search terms from the task content
2. THE Search_Term_Generator SHALL identify and prioritize: rare keywords, sender/recipient names, subject lines, and unique identifiers
3. WHEN search terms are generated, THE Search_Term_Generator SHALL copy them to the system pasteboard
4. THE Search_Term_Generator SHALL format terms appropriately for common search interfaces
5. WHEN a task has insufficient content for search terms, THE Search_Term_Generator SHALL notify the user

### Requirement 7: Cyberpunk Dark UI Theme

**User Story:** As a user, I want a modern dark interface with cyberpunk aesthetics, so that the app feels clean, modern, and visually appealing.

#### Acceptance Criteria

1. THE Task_Flow_App SHALL use a dark color scheme as the default and only theme
2. THE Task_Flow_App SHALL feature purple and neon accent colors consistent with cyberpunk aesthetics
3. THE Task_Flow_App SHALL use clean, modern typography and spacing
4. THE Task_Flow_App SHALL apply subtle neon glow effects to interactive elements
5. THE Task_Flow_App SHALL maintain high contrast ratios for accessibility while preserving the dark aesthetic
6. WHEN displaying priority levels, THE Task_Flow_App SHALL use distinct neon colors: cyan for Low, purple for Medium, magenta/pink for Mega

### Requirement 8: macOS Native Application

**User Story:** As a user, I want the app to run natively on my Mac, so that it integrates well with my system and performs efficiently.

#### Acceptance Criteria

1. THE Task_Flow_App SHALL run as a native macOS application
2. THE Task_Flow_App SHALL request only necessary system permissions for screen capture and accessibility
3. WHEN permissions are required, THE Task_Flow_App SHALL guide the user through the permission grant process
4. THE Task_Flow_App SHALL support standard macOS keyboard shortcuts for common actions
5. THE Task_Flow_App SHALL persist window position and size between sessions

### Requirement 9: Capture Progress Status Bar

**User Story:** As a user, I want to see the progress and status of capture operations, so that I know what the app is doing and can identify any failures.

#### Acceptance Criteria

1. THE Task_Flow_App SHALL display a persistent status bar at the bottom of the main window
2. WHEN a capture operation begins, THE Status_Bar SHALL display "Starting capture..."
3. WHEN screenshot saving begins, THE Status_Bar SHALL display "Saving screenshot..."
4. WHEN OCR processing begins, THE Status_Bar SHALL display "Extracting text from image..."
5. WHEN LLM summarization begins, THE Status_Bar SHALL display "Generating task title..."
6. WHEN the LLM is unavailable, THE Status_Bar SHALL display "LLM unavailable - using fallback title"
7. WHEN all processing completes successfully, THE Status_Bar SHALL display success message or clear the status
8. IF any step fails, THE Status_Bar SHALL display an error message describing what failed
9. THE Status_Bar SHALL use distinct colors to indicate: processing (cyan), success (green), warning (yellow), error (red)
10. WHEN idle, THE Status_Bar SHALL display minimal information to avoid distraction

### Requirement 10: Task Assignment Tracking

**User Story:** As a user, I want to assign tasks to people or companies, so that I can track who is responsible for tasks I'm monitoring.

#### Acceptance Criteria

1. WHEN editing a task, THE Task_Flow_App SHALL provide an "Assigned To" text field for entering a person or company name
2. WHEN the user types in the Assigned To field, THE Assignee_Manager SHALL display autocomplete suggestions from previously saved names
3. WHEN a task is saved with an assignee, THE Assignee_Manager SHALL persist the name for future autocomplete suggestions
4. WHEN displaying a task in the task list or Kanban board, THE Task_Flow_App SHALL show the assignee name with a person icon
5. THE Assignee_Manager SHALL store assignee names sorted alphabetically for consistent autocomplete ordering

### Requirement 11: Screenshot Replacement

**User Story:** As a user, I want to replace or add a screenshot to an existing task, so that I can update the visual reference without recreating the task.

#### Acceptance Criteria

1. WHEN editing a task, THE Task_Flow_App SHALL provide a button to add or replace the screenshot
2. WHEN the user clicks the replace button, THE Task_Flow_App SHALL open a file picker for selecting an image file
3. WHEN a new image is selected, THE Screenshot_Manager SHALL save the new image and update the task reference
4. WHEN a new screenshot is added, THE Screen_Capture_Engine SHALL run OCR on the new image and update Further Details if empty
5. WHILE processing a new screenshot, THE Task_Flow_App SHALL display a loading indicator

### Requirement 12: Task Search and Filtering

**User Story:** As a user, I want to search and filter tasks by keywords, so that I can quickly find specific tasks across all my work.

#### Acceptance Criteria

1. THE Task_Flow_App SHALL display a search bar in the main navigation area
2. WHEN the user types in the search bar, THE Search_Filter SHALL filter tasks to show only those matching the query
3. THE Search_Filter SHALL search across: title, description, further details, assignee, keywords, sender, and subject fields
4. WHEN a search is active, THE Task_Flow_App SHALL display a visual indicator showing the search is filtering results
5. THE Task_Flow_App SHALL provide a clear button next to the search bar to remove all filters
6. WHEN the clear button is clicked, THE Search_Filter SHALL remove all filters and show all tasks
7. THE Search_Filter SHALL apply to both the Task List view and Kanban Board view

### Requirement 13: Custom App Icon

**User Story:** As a user, I want the app to have a distinctive custom icon, so that I can easily identify it in the Dock and Launchpad.

#### Acceptance Criteria

1. THE Task_Flow_App SHALL display a custom cyberpunk-themed icon in the macOS Dock
2. THE Task_Flow_App SHALL display the same custom icon in Launchpad
3. THE Task_Flow_App SHALL display the custom icon in Finder and application switcher
4. THE App_Icon SHALL feature the "TaskFlow" branding with purple/pink neon colors on a dark background
5. THE App_Icon SHALL have a transparent background (no white border) to integrate seamlessly with macOS
6. THE App_Icon SHALL be provided in all required macOS icon sizes (16x16 through 1024x1024 with retina variants)
7. THE App_Icon SHALL be bundled as an .icns file in the application Resources directory

### Requirement 14: Window Hiding During Capture

**User Story:** As a user, I want the TaskFlow window to hide when I start a capture, so that I can capture content that was behind the app window on a single-monitor setup.

#### Acceptance Criteria

1. WHEN the user clicks the capture button, THE Task_Flow_App SHALL hide the main window before displaying the capture overlay
2. WHEN the capture overlay is displayed, THE Task_Flow_App main window SHALL NOT be visible on any screen
3. WHEN a capture is completed successfully, THE Task_Flow_App SHALL restore the main window and bring it to focus
4. WHEN a capture is cancelled (Escape key), THE Task_Flow_App SHALL restore the main window and bring it to focus
5. THE Task_Flow_App SHALL provide a brief delay between hiding the window and showing the capture overlay to ensure the window is fully hidden
6. WHEN the task creation sheet is displayed after capture, THE Task_Flow_App main window SHALL be visible and focused

### Requirement 15: Menu Bar Integration

**User Story:** As a user, I want a menu bar icon for TaskFlow, so that I can quickly create tasks without switching to the app window.

#### Acceptance Criteria

1. THE Task_Flow_App SHALL display a status item icon in the macOS menu bar
2. THE Menu_Bar_Icon SHALL use the TaskFlow app icon (scaled to menu bar size) to match the application branding
3. WHEN the user clicks the menu bar icon, THE Task_Flow_App SHALL display a dropdown menu
4. THE Menu_Bar_Menu SHALL include a "Capture New Task" option that triggers the capture flow
5. THE Menu_Bar_Menu SHALL include a "Show TaskFlow" option that brings the main window to focus
6. THE Menu_Bar_Menu SHALL include a "Quit TaskFlow" option to exit the application
7. WHEN "Capture New Task" is selected, THE Task_Flow_App SHALL hide the main window and start the capture flow
8. THE Menu_Bar_Icon SHALL be visible whenever the application is running
9. WHILE processing a capture from the menu bar, THE Task_Flow_App SHALL display a loading overlay on screen showing progress

### Requirement 16: Pomodoro Skip Functionality

**User Story:** As a user, I want to skip tasks during a Pomodoro session without them reappearing, so that I can focus on other tasks.

#### Acceptance Criteria

1. WHEN the user clicks the Skip button during a Pomodoro session, THE Pomodoro_Timer SHALL advance to the next task
2. WHEN a task is skipped, THE Pomodoro_Timer SHALL NOT show that task again during the current session
3. WHEN a new Pomodoro session is started, THE Pomodoro_Timer SHALL clear the list of skipped tasks
4. THE Pomodoro_Timer SHALL track skipped tasks separately from completed tasks

### Requirement 17: Consistent Window Sizing

**User Story:** As a user, I want the window to maintain consistent size when switching tabs, so that the interface feels stable.

#### Acceptance Criteria

1. WHEN switching between tabs (Tasks, Pomodoro, Kanban), THE Task_Flow_App main window SHALL maintain the same size
2. THE Pomodoro_Timer view SHALL fill the available space using the full window dimensions
3. THE Pomodoro_Timer view content SHALL be centered within the available space

### Requirement 20: Data Migration and Upgrade Safety

**User Story:** As a user, I want my tasks to safely migrate when I upgrade TaskFlow, so that I never lose data and can recover from any issues.

#### Acceptance Criteria

1. THE Persistence_Layer SHALL track the current schema version in the database
2. WHEN the application starts with an older schema version, THE Persistence_Layer SHALL create an automatic backup before applying any migrations
3. WHEN migrations are applied, THE Persistence_Layer SHALL record each migration in a migration history table
4. IF a migration fails, THE Persistence_Layer SHALL rollback to the pre-migration state and notify the user
5. WHEN a database error occurs, THE Task_Flow_App SHALL display a user-friendly error dialog with recovery options
6. THE Task_Flow_App SHALL provide a "Backup & Restore" section in settings for manual backup management
7. WHEN the user clicks "Create Backup", THE Backup_Manager SHALL create a timestamped backup and confirm success
8. WHEN the user clicks "Restore from Backup", THE Task_Flow_App SHALL display available backups and allow selection
9. BEFORE restoring from backup, THE Task_Flow_App SHALL warn the user that current data will be replaced
10. WHEN restoration completes, THE Task_Flow_App SHALL reload all data and confirm success to the user
11. IF the database is corrupted on startup, THE Task_Flow_App SHALL automatically attempt recovery and notify the user of the outcome
12. THE Backup_Manager SHALL export backups in a portable format that can be manually imported on another machine
13. THE Backup_Manager SHALL include screenshots in backups as a zip archive containing both task data and associated images
14. THE Backup_Manager SHALL retain a maximum of 5 manual backups, automatically deleting older ones
15. THE Backup_Manager SHALL retain one daily backup for each of the last 14 days as a safety net
16. WHEN cleaning up backups, THE Backup_Manager SHALL preserve daily backups even if they exceed the manual backup limit

### Requirement 21: Task Editor Field Ordering

**User Story:** As a user, I want the task editor fields to be organized with the most important fields at the top, so that I can quickly edit common fields without scrolling.

#### Acceptance Criteria

1. WHEN displaying the task creation sheet, THE Task_Flow_App SHALL order fields as: Screenshot, Title, Description, Time Estimate, Priority, Further Details (from OCR)
2. WHEN displaying the task detail/edit view, THE Task_Flow_App SHALL order fields as: Screenshot, Metadata (if present), Title, Description, Assigned To, Time Estimate, Priority, Further Details (from OCR), Status
3. THE Task_Flow_App SHALL position the "Further Details (from OCR)" section at the bottom of the scrollable content in both views

### Requirement 18: Distributable Installer Package

**User Story:** As a user, I want an easy-to-use installer that sets up TaskFlow and all dependencies, so that I can start using the app without technical knowledge.

#### Acceptance Criteria

1. THE Installer SHALL be distributed as a DMG file containing TaskFlow.app and an installer script
2. WHEN the user runs the installer script, THE Installer SHALL check system requirements (macOS 13+, disk space, architecture)
3. WHEN Ollama is not installed, THE Installer SHALL download and install Ollama automatically
4. THE Installer SHALL automatically download the gemma3:1b model for AI-powered features
5. THE Installer SHALL display download progress for the model
7. WHEN installation completes, THE Installer SHALL copy TaskFlow.app to /Applications
8. THE Installer SHALL remove the quarantine attribute from TaskFlow.app to allow execution
9. THE Installer SHALL guide the user through granting Screen Recording permission
10. WHEN all steps complete, THE Installer SHALL display a summary and offer to launch TaskFlow
11. THE Installer SHALL support 100% offline operation after initial installation
