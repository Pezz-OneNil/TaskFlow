# Implementation Plan: Annual Calendar

## Overview

This implementation plan breaks down the Annual Calendar feature into discrete coding tasks. The approach is incremental: first establishing data models and persistence, then building managers, and finally creating the UI components. Property-based tests are included as optional sub-tasks to validate correctness properties.

## Tasks

- [x] 1. Extend database schema for calendar events
  - Add migration to DatabaseManager for `calendar_events` table
  - Create table with columns: id, category_id, start_date, end_date, label, created_at, updated_at
  - Add index on start_date and end_date for efficient queries
  - Increment CURRENT_SCHEMA_VERSION
  - _Requirements: 7.1, 7.4, 7.5_

- [x] 2. Create data models
  - [x] 2.1 Create EventCategory model and CategoryColor enum
    - Define CategoryColor enum with 10 cyberpunk colors and rawValue 1-10
    - Add color and textColor computed properties
    - Define EventCategory struct with id, name, and color
    - _Requirements: 3.1, 3.6_

  - [x] 2.2 Create CalendarEvent model
    - Define CalendarEvent struct with id, categoryId, startDate, endDate, label, createdAt, updatedAt
    - Implement `contains(date:)` method for date range checking
    - Implement `durationDays` computed property
    - _Requirements: 4.3, 7.4_

  - [x] 2.3 Write property test for CalendarEvent.contains(date:)
    - **Property 7: Event date containment**
    - Generate random start/end dates and test dates
    - Verify contains() returns true iff start ≤ date ≤ end
    - **Validates: Requirements 4.3**

  - [x] 2.4 Create CalendarEventRecord for GRDB persistence
    - Define CalendarEventRecord with FetchableRecord and PersistableRecord conformance
    - Implement init(from: CalendarEvent) and toCalendarEvent() conversion methods
    - _Requirements: 7.1_

  - [x] 2.5 Create TaskActivityStats struct
    - Define struct with date, tasksAdded, tasksCompleted properties
    - _Requirements: 6.1, 6.2_

- [x] 3. Checkpoint - Verify models compile
  - Ensure all model files compile without errors
  - Run existing tests to verify no regressions

- [x] 4. Create EventCategoryManager
  - [x] 4.1 Implement EventCategoryManager singleton
    - Create shared instance with @Published categories array
    - Implement loadCategories() to initialize 10 categories with default names
    - Implement updateCategoryName(id:name:) method
    - Implement category(for id:) lookup method
    - Persist category names to UserDefaults
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [x] 4.2 Write property test for category name editing
    - **Property 5: Category name editing**
    - Generate random category IDs (1-10) and non-empty strings
    - Verify updateCategoryName followed by category(for:) returns updated name
    - **Validates: Requirements 3.3**

  - [x] 4.3 Write property test for category name persistence
    - **Property 6: Category name persistence round-trip**
    - Generate category ID and name, save, create new manager instance, verify name
    - **Validates: Requirements 3.4**

- [x] 5. Create CalendarEventManager
  - [x] 5.1 Implement CalendarEventManager singleton
    - Create shared instance with @Published events array
    - Implement loadEvents() to fetch from database
    - Implement createEvent(categoryId:startDate:endDate:label:) method
    - Implement updateEvent(_:) method
    - Implement deleteEvent(id:) method
    - Implement events(forYear:) filtering method
    - Implement events(containing:) filtering method
    - _Requirements: 4.3, 4.8, 7.1, 7.3_

  - [x] 5.2 Write property test for event persistence round-trip
    - **Property 9: Event persistence round-trip**
    - Generate valid events, save, reload manager, verify equality
    - **Validates: Requirements 4.8, 7.1, 7.3**

  - [x] 5.3 Write property test for event label accessibility
    - **Property 8: Event label accessibility**
    - Generate random label strings, create events, verify label preserved
    - **Validates: Requirements 4.5**

- [x] 6. Extend TaskManager for activity stats
  - [x] 6.1 Add getActivityStats(for year:) method to TaskManager
    - Iterate through tasks and count by createdAt date for tasksAdded
    - Count completed tasks by updatedAt date for tasksCompleted
    - Return dictionary mapping Date to TaskActivityStats
    - _Requirements: 6.1, 6.2_

  - [x] 6.2 Write property test for task activity stats accuracy
    - **Property 10: Task activity stats accuracy**
    - Generate random tasks with various dates and statuses
    - Verify counts match expected values
    - **Validates: Requirements 6.1, 6.2**

- [x] 7. Checkpoint - Verify managers work
  - Ensure all manager files compile
  - Run property tests to verify correctness
  - Test basic CRUD operations manually if needed

- [x] 8. Extend SettingsManager for Annual Calendar toggle
  - [x] 8.1 Add showAnnualCalendar setting to SettingsManager
    - Add key constant for "showAnnualCalendar"
    - Add @Published property with UserDefaults persistence
    - Default to false (tab hidden initially)
    - _Requirements: 1.4_

  - [x] 8.2 Write property test for settings toggle persistence
    - **Property 2: Settings toggle persistence round-trip**
    - Generate random booleans, write to setting, verify read returns same value
    - **Validates: Requirements 1.4, 1.5**

- [x] 9. Extend NavigationTab for Annual tab
  - [x] 9.1 Add annual case to NavigationTab enum
    - Add `.annual` case with "Annual" rawValue
    - Add calendar icon and accentYellow color
    - Implement static visibleTabs(showAnnual:) method
    - _Requirements: 1.2, 1.3_

  - [x] 9.2 Write property test for tab visibility
    - **Property 1: Settings toggle controls tab visibility**
    - Generate random boolean, verify visibleTabs output matches
    - **Validates: Requirements 1.2, 1.3**

- [x] 10. Create Annual Calendar UI components
  - [x] 10.1 Create DayCell view
    - Display day number and day-of-week abbreviation
    - Display task activity indicators (↑count, ↓count) in corner
    - Apply CyberpunkTheme styling
    - Add hover state with subtle visual feedback
    - _Requirements: 2.3, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 8.1_

  - [x] 10.2 Write property test for day cell date display
    - **Property 3: Day cell displays correct date information**
    - Generate random dates, verify day number and weekday are correct
    - **Validates: Requirements 2.3**

  - [x] 10.3 Create MonthColumnView
    - Display month name header
    - Display grid of DayCells for all days in month
    - Handle variable month lengths
    - _Requirements: 2.1, 2.2_

  - [x] 10.4 Create EventBlockView
    - Display colored rectangle with category color
    - Display text label within block
    - Add hover state with glow effect
    - Handle click for editing
    - _Requirements: 4.4, 5.1, 5.3, 5.4, 8.2_

  - [x] 10.5 Create YearSelectorView
    - Dropdown picker for years 2025-2035
    - Default selection to 2026
    - Styled with CyberpunkTheme
    - _Requirements: 2.5, 2.6, 2.7, 2.8_

  - [x] 10.6 Write property test for year selection
    - **Property 4: Year selection updates calendar display**
    - Generate random years, verify correct month/day counts
    - **Validates: Requirements 2.7**

- [x] 11. Create Event Editor components
  - [x] 11.1 Create EventEditorSheet view
    - Category picker showing all 10 categories with colors
    - Text field for event label
    - Date pickers for start and end dates
    - Save and Cancel buttons
    - Delete button for existing events
    - Handle Escape key to cancel
    - _Requirements: 4.2, 4.6, 4.7, 8.4_

  - [x] 11.2 Create CategoryEditorView for settings
    - List all 10 categories with color swatches
    - Editable text fields for category names
    - _Requirements: 3.2, 3.3_

- [x] 12. Create main AnnualCalendarView
  - [x] 12.1 Implement AnnualCalendarView
    - Year selector at top
    - 12-column grid layout for months
    - Overlay EventBlocks on calendar grid
    - Handle drag selection for event creation
    - Integrate with CalendarEventManager and EventCategoryManager
    - Integrate with TaskManager for activity stats
    - _Requirements: 2.1, 2.2, 2.4, 4.1, 5.2, 5.5_

  - [x] 12.2 Add category panel/sidebar
    - Display category legend with colors and names
    - Quick access to category editor
    - _Requirements: 3.2_

- [x] 13. Integrate Annual tab into MainWindowView
  - [x] 13.1 Update MainWindowView tab bar
    - Use NavigationTab.visibleTabs(showAnnual:) for tab list
    - Observe SettingsManager.showAnnualCalendar
    - Add case for .annual in contentView switch
    - _Requirements: 1.2, 1.3_

  - [x] 13.2 Add Annual Calendar toggle to settings view
    - Add toggle in BackupRestoreView (settings tab)
    - Label: "Show Annual Calendar"
    - Bind to SettingsManager.showAnnualCalendar
    - _Requirements: 1.1_

- [x] 14. Checkpoint - Full integration test
  - Verify Annual tab appears/hides based on setting
  - Test event creation, editing, and deletion
  - Test category name editing
  - Verify task indicators display correctly
  - Ensure all tests pass, ask the user if questions arise

- [x] 15. Final polish and edge cases
  - [x] 15.1 Handle leap years correctly
    - Verify February shows 29 days in leap years
    - _Requirements: 2.7_

  - [x] 15.2 Handle events spanning year boundaries
    - Events starting in previous year should appear
    - Events ending in next year should appear
    - _Requirements: 5.5_

  - [x] 15.3 Add keyboard navigation support
    - Arrow keys to navigate days
    - Enter to select/edit
    - Escape to cancel
    - _Requirements: 8.3_

- [x] 16. Final checkpoint
  - Ensure all tests pass
  - Verify no performance issues with full year display
  - Ask the user if questions arise

- [x] 17. Event drag-to-move functionality
  - [x] 17.1 Add drag gesture to EventBlockView
    - Implement vertical drag to move events to different dates
    - Preserve event duration when moving (end date moves proportionally)
    - Add visual feedback during drag (opacity change, cursor change)
    - _Requirements: 9.1, 9.2, 9.3_

  - [x] 17.2 Implement moveEvent handler in AnnualCalendarView
    - Calculate new start/end dates based on drag distance
    - Update event via CalendarEventManager
    - _Requirements: 9.4_

- [x] 18. Event drag-to-resize functionality
  - [x] 18.1 Add resize handle to EventBlockView
    - Create ResizeHandleCompact component with grip indicator
    - Position on right edge of event block
    - Change cursor to resize cursor on hover
    - _Requirements: 10.1, 10.5_

  - [x] 18.2 Implement resize gesture
    - Drag handle vertically to adjust end date
    - Prevent end date from going before start date
    - Show updated duration indicator during resize
    - _Requirements: 10.2, 10.3, 10.4_

  - [x] 18.3 Implement resizeEvent handler in AnnualCalendarView
    - Calculate new end date based on drag distance
    - Validate end date >= start date
    - Update event via CalendarEventManager
    - _Requirements: 10.2, 10.3_

- [x] 19. Responsive tab bar
  - [x] 19.1 Add GeometryReader to tab bar
    - Detect window width for responsive behavior
    - _Requirements: 11.1, 11.2_

  - [x] 19.2 Update TabButton for responsive display
    - Add showText parameter to control text visibility
    - Show icons only when width < 700px
    - Add tooltips for icons-only mode
    - Prevent text wrapping with fixedSize modifier
    - _Requirements: 11.2, 11.3, 11.4_

  - [x] 19.3 Conditionally hide search bar and model selector
    - Hide search bar when width < 600px
    - Hide model selector when width < 800px
    - _Requirements: 11.5, 11.6_

- [x] 20. Responsive Kanban board
  - [x] 20.1 Add GeometryReader to KanbanBoardView
    - Calculate equal column widths based on available space
    - Set minimum column width of 140px
    - _Requirements: 12.1, 12.2, 12.3_

  - [x] 20.2 Update KanbanColumnView
    - Remove fixed minWidth/maxWidth constraints
    - Accept explicit width from parent
    - Ensure all columns always visible
    - _Requirements: 12.4_

- [x] 21. Calendar events in backups
  - [x] 21.1 Update BackupData structure
    - Add optional calendarEvents array to BackupData
    - Add optional categoryNames dictionary for custom category names
    - Maintain backward compatibility with existing backups
    - _Requirements: 13.5_

  - [x] 21.2 Update backup creation
    - Include CalendarEventRecord.fetchAll in backup data
    - Include category names from UserDefaults
    - _Requirements: 13.1, 13.2_

  - [x] 21.3 Update backup restoration
    - Restore calendar events to database if present
    - Restore category names to UserDefaults if present
    - Reload CalendarEventManager after restore
    - _Requirements: 13.3, 13.4_

- [x] 22. Multi-event day popover
  - [x] 22.1 Add popover state to DayCellView
    - Add showAllEventsPopover state variable
    - Trigger popover on "+N" indicator click
    - _Requirements: 14.1, 14.2_

  - [x] 22.2 Create popover content view
    - Display date header with event count
    - List all events with category color, name, and duration
    - Handle event tap to open editor
    - _Requirements: 14.3, 14.4, 14.5_

- [x] 23. Event editor reliability fix
  - [x] 23.1 Refactor sheet presentation in AnnualCalendarView
    - Replace sheet(isPresented:) with sheet(item:) for event editing
    - Create EditableEvent wrapper type for Identifiable conformance
    - Create NewEventDates wrapper type for new event creation
    - Ensure event data is available when sheet opens
    - _Requirements: 15.1, 15.2, 15.3_

## Notes

- All tasks including property-based tests are required for comprehensive coverage
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- Unit tests (not listed separately) should be written alongside implementation for edge cases
