# Requirements Document

## Introduction

The Annual Calendar feature provides a full year-at-a-glance view within TaskFlow, allowing users to visualize their entire year with colored event blocks spanning multiple days. This feature integrates with the existing task system to display daily task activity indicators, gamifying productivity by showing tasks added and completed per day. The calendar follows the existing cyberpunk aesthetic and is accessible via a toggleable tab in settings.

## Glossary

- **Annual_Calendar**: A full-year calendar view displaying all 12 months in a grid layout, similar to wall calendar format
- **Category**: A named color preset used to classify calendar events (e.g., "Work Travel", "Family Holiday")
- **Event_Block**: A colored rectangular overlay spanning one or more consecutive days on the calendar
- **Task_Indicator**: Small visual elements in the corner of each day cell showing task activity counts
- **Day_Cell**: An individual day square within the calendar grid containing the date number and optional indicators

## Requirements

### Requirement 1: Settings Toggle for Annual Calendar Tab

**User Story:** As a user, I want to enable or disable the Annual Calendar tab from settings, so that I can customize my TaskFlow interface.

#### Acceptance Criteria

1. WHEN a user navigates to the Settings tab, THE Settings_View SHALL display a toggle option labeled "Show Annual Calendar"
2. WHEN the toggle is enabled, THE Navigation_Tab_Bar SHALL display an "Annual" tab between existing tabs
3. WHEN the toggle is disabled, THE Navigation_Tab_Bar SHALL hide the "Annual" tab
4. THE Settings_Manager SHALL persist the toggle state between application sessions
5. WHEN the application launches, THE Navigation_Tab_Bar SHALL reflect the persisted toggle state

### Requirement 2: Annual Calendar View Layout

**User Story:** As a user, I want to see a full year calendar in one view, so that I can visualize my entire year at a glance.

#### Acceptance Criteria

1. WHEN the Annual tab is selected, THE Annual_Calendar_View SHALL display all 12 months in a grid layout
2. THE Annual_Calendar_View SHALL display months in columns (January through December left to right)
3. THE Day_Cell SHALL display the day number and day-of-week abbreviation
4. THE Annual_Calendar_View SHALL use the CyberpunkTheme color palette for backgrounds and text
5. WHEN the view loads, THE Annual_Calendar_View SHALL default to displaying the year 2026
6. THE Annual_Calendar_View SHALL display a year selector dropdown at the top of the view
7. WHEN a user selects a different year from the dropdown, THE Annual_Calendar_View SHALL update to display that year
8. THE Year_Selector SHALL allow selection of years from 2025 to 2035

### Requirement 3: Event Categories Management

**User Story:** As a user, I want to manage event categories with preset colors, so that I can organize different types of events visually.

#### Acceptance Criteria

1. THE Category_Manager SHALL provide exactly 10 preset color combinations in cyberpunk style
2. WHEN a user accesses category settings, THE Category_Editor SHALL display all 10 categories with their colors
3. THE Category_Editor SHALL allow users to edit the name of each category
4. THE Category_Manager SHALL persist category names between application sessions
5. WHEN the application first launches, THE Category_Manager SHALL provide default names for all categories (e.g., "Category 1", "Category 2", etc.)
6. THE Category colors SHALL be visually distinct and follow the cyberpunk aesthetic

### Requirement 4: Event Block Creation and Editing

**User Story:** As a user, I want to create colored event blocks on the calendar, so that I can mark periods for holidays, travel, and other activities.

#### Acceptance Criteria

1. WHEN a user clicks and drags across multiple Day_Cells, THE Annual_Calendar_View SHALL initiate event block creation
2. WHEN event creation is initiated, THE Event_Editor SHALL display a popup with category selection and text input
3. THE Event_Block SHALL span from the start date to the end date selected by the user
4. THE Event_Block SHALL display with solid fill color matching the selected category
5. THE Event_Block SHALL display the user-entered text label within the block
6. WHEN a user clicks an existing Event_Block, THE Event_Editor SHALL allow editing the category, text, and date range
7. THE Event_Editor SHALL provide a delete option to remove an Event_Block
8. THE Event_Manager SHALL persist all Event_Blocks between application sessions

### Requirement 5: Event Block Visual Display

**User Story:** As a user, I want event blocks to be clearly visible on the calendar, so that I can quickly identify different periods and activities.

#### Acceptance Criteria

1. THE Event_Block SHALL render as a colored rectangle overlaying the Day_Cells it spans
2. WHEN multiple Event_Blocks overlap on the same days, THE Annual_Calendar_View SHALL stack them vertically within the day column
3. THE Event_Block text label SHALL be readable against the category background color
4. THE Event_Block SHALL have subtle rounded corners consistent with CyberpunkTheme
5. WHEN an Event_Block spans across month boundaries, THE Annual_Calendar_View SHALL render it continuously across the months

### Requirement 6: Task Activity Indicators

**User Story:** As a user, I want to see task activity indicators on each day, so that I can gamify my productivity and track my task management habits.

#### Acceptance Criteria

1. THE Day_Cell SHALL display a task-added indicator showing the count of tasks created on that date
2. THE Day_Cell SHALL display a task-completed indicator showing the count of tasks completed on that date
3. THE task-added indicator SHALL display an up arrow (↑) followed by the count number
4. THE task-completed indicator SHALL display a down arrow (↓) followed by the count number
5. THE Task_Indicator SHALL be positioned in the corner of the Day_Cell without obscuring the date number
6. WHEN the count is zero, THE Task_Indicator SHALL still display with "0" to maintain visual consistency
7. THE Task_Indicator SHALL use contrasting colors (green for completed, cyan for added) following CyberpunkTheme

### Requirement 7: Data Persistence

**User Story:** As a user, I want my calendar events and settings to be saved, so that I don't lose my planning work.

#### Acceptance Criteria

1. THE Event_Manager SHALL store Event_Blocks in a persistent data store
2. THE Category_Manager SHALL store category names in a persistent data store
3. WHEN the application launches, THE Annual_Calendar_View SHALL load all persisted Event_Blocks
4. THE Event_Block data model SHALL include: id, category_id, start_date, end_date, and text_label
5. THE persistence layer SHALL use the same storage mechanism as existing TaskFlow data (SQLite)

### Requirement 8: Calendar Navigation and Interaction

**User Story:** As a user, I want smooth navigation and interaction with the calendar, so that I can efficiently manage my annual planning.

#### Acceptance Criteria

1. WHEN hovering over a Day_Cell, THE Annual_Calendar_View SHALL provide subtle visual feedback
2. WHEN hovering over an Event_Block, THE Annual_Calendar_View SHALL highlight the block with a glow effect
3. THE Annual_Calendar_View SHALL support keyboard navigation for accessibility (arrow keys, Enter, Escape)
4. WHEN the user presses Escape during event creation, THE Event_Editor SHALL cancel the operation
5. THE Annual_Calendar_View SHALL render smoothly without performance degradation when displaying a full year with multiple events

### Requirement 9: Event Drag-to-Move

**User Story:** As a user, I want to drag events to different dates, so that I can quickly reschedule without opening the editor.

#### Acceptance Criteria

1. WHEN a user drags an Event_Block vertically, THE Annual_Calendar_View SHALL move the event to the new date
2. WHEN an event is moved, THE Event_Manager SHALL preserve the event's duration (end date moves proportionally)
3. THE Event_Block SHALL provide visual feedback during drag operations (opacity change, cursor change)
4. WHEN the drag is released, THE Event_Manager SHALL persist the new dates immediately

### Requirement 10: Event Drag-to-Resize

**User Story:** As a user, I want to drag the edge of events to change their duration, so that I can quickly extend or shorten events.

#### Acceptance Criteria

1. THE Event_Block SHALL display a resize handle on the right edge
2. WHEN a user drags the resize handle vertically, THE Annual_Calendar_View SHALL adjust the event's end date
3. THE resize operation SHALL NOT allow the end date to be before the start date
4. WHEN resizing, THE Event_Block SHALL display the updated duration indicator
5. THE cursor SHALL change to a resize cursor when hovering over the resize handle

### Requirement 11: Responsive Tab Bar

**User Story:** As a user, I want the tab bar to remain readable at any window size, so that I can always navigate the app.

#### Acceptance Criteria

1. WHEN the window width is above 700px, THE Navigation_Tab_Bar SHALL display both icons and text labels
2. WHEN the window width is below 700px, THE Navigation_Tab_Bar SHALL display only icons
3. THE tab labels SHALL never wrap or truncate
4. WHEN icons-only mode is active, THE tabs SHALL display tooltips on hover showing the tab name
5. THE Navigation_Tab_Bar SHALL hide the search bar when window width is below 600px
6. THE Navigation_Tab_Bar SHALL hide the model selector when window width is below 800px

### Requirement 12: Responsive Kanban Board

**User Story:** As a user, I want all Kanban columns to remain visible at any window size, so that I can always see my full workflow.

#### Acceptance Criteria

1. THE Kanban_Board SHALL display all columns (Backlog, To Do, In Progress, Done, Deleted) with equal widths
2. THE columns SHALL resize proportionally as the window width changes
3. THE columns SHALL have a minimum width of 140px to remain readable
4. THE Kanban_Board SHALL NOT hide or center columns at any window size

### Requirement 13: Calendar Events in Backups

**User Story:** As a user, I want my calendar events included in backups, so that I don't lose my planning data when restoring.

#### Acceptance Criteria

1. WHEN a backup is created, THE Backup_Manager SHALL include all calendar events from the database
2. WHEN a backup is created, THE Backup_Manager SHALL include custom category names from UserDefaults
3. WHEN a backup is restored, THE Backup_Manager SHALL restore all calendar events to the database
4. WHEN a backup is restored, THE Backup_Manager SHALL restore custom category names to UserDefaults
5. THE backup format SHALL remain backward compatible with backups that don't contain calendar events

### Requirement 14: Multi-Event Day View

**User Story:** As a user, I want to access all events on a day with many events, so that I can see and edit events beyond the visible limit.

#### Acceptance Criteria

1. WHEN a day has more than 2 events, THE Day_Cell SHALL display a "+N" indicator showing additional event count
2. WHEN a user clicks the "+N" indicator, THE Day_Cell SHALL display a popover listing all events for that day
3. THE popover SHALL display each event with its category color, name/label, and duration
4. WHEN a user clicks an event in the popover, THE Event_Editor SHALL open for that event
5. THE popover SHALL close when an event is selected or when clicking outside

### Requirement 15: Event Editor Reliability

**User Story:** As a user, I want the event editor to open reliably, so that I can always edit my calendar events.

#### Acceptance Criteria

1. WHEN a user clicks an Event_Block, THE Event_Editor SHALL open with the event data populated
2. THE Event_Editor SHALL NOT display blank or empty on first click after app launch
3. THE Event_Editor SHALL use item-based sheet presentation to ensure data availability
