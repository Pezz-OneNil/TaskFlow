# Design Document: Annual Calendar

## Overview

The Annual Calendar feature adds a full year-at-a-glance view to TaskFlow, enabling users to visualize their entire year with colored event blocks for holidays, travel, and other activities. The feature integrates with the existing task system to display daily task activity indicators, gamifying productivity tracking.

The design follows existing TaskFlow patterns:
- SwiftUI views with CyberpunkTheme styling
- GRDB/SQLite persistence via DatabaseManager
- UserDefaults for settings via SettingsManager
- ObservableObject managers for state management

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        MainWindowView                            │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ NavigationTab (Tasks | Pomodoro | Kanban | Annual | Settings)││
│  └─────────────────────────────────────────────────────────────┘│
│                              │                                   │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                   AnnualCalendarView                         ││
│  │  ┌─────────────┐  ┌────────────────────────────────────────┐││
│  │  │YearSelector │  │         CalendarGridView               │││
│  │  └─────────────┘  │  ┌─────┐ ┌─────┐ ┌─────┐ ... ┌─────┐  │││
│  │                   │  │ Jan │ │ Feb │ │ Mar │     │ Dec │  │││
│  │  ┌─────────────┐  │  │     │ │     │ │     │     │     │  │││
│  │  │CategoryPanel│  │  │DayCell│DayCell│DayCell    │DayCell│││
│  │  └─────────────┘  │  └─────┘ └─────┘ └─────┘     └─────┘  │││
│  │                   │         EventBlock overlays            │││
│  │                   └────────────────────────────────────────┘││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         Data Layer                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ CalendarEvent   │  │ EventCategory   │  │ TaskManager     │  │
│  │ Manager         │  │ Manager         │  │ (existing)      │  │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘  │
│           │                    │                    │           │
│           ▼                    ▼                    ▼           │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    DatabaseManager                           ││
│  │  calendar_events table  │  event_categories table            ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. SettingsManager Extension

Extend existing SettingsManager to include Annual Calendar toggle:

```swift
// Add to SettingsManager.swift
private enum Keys {
    // ... existing keys
    static let showAnnualCalendar = "showAnnualCalendar"
}

@Published public var showAnnualCalendar: Bool {
    didSet {
        defaults.set(showAnnualCalendar, forKey: Keys.showAnnualCalendar)
    }
}
```

### 2. NavigationTab Extension

Extend NavigationTab enum to conditionally include Annual:

```swift
public enum NavigationTab: String, CaseIterable {
    case tasks = "Tasks"
    case pomodoro = "Pomodoro"
    case kanban = "Kanban"
    case annual = "Annual"  // New
    case settings = "Settings"
    
    var icon: String {
        switch self {
        // ... existing cases
        case .annual: return "calendar"
        }
    }
    
    var color: Color {
        switch self {
        // ... existing cases
        case .annual: return CyberpunkTheme.accentYellow
        }
    }
    
    /// Returns tabs to display based on settings
    static func visibleTabs(showAnnual: Bool) -> [NavigationTab] {
        var tabs: [NavigationTab] = [.tasks, .pomodoro, .kanban]
        if showAnnual {
            tabs.append(.annual)
        }
        tabs.append(.settings)
        return tabs
    }
}
```

### 3. EventCategory Model

```swift
public struct EventCategory: Identifiable, Codable, Equatable {
    public let id: Int  // 1-10, fixed
    public var name: String
    public let color: CategoryColor
    
    public init(id: Int, name: String, color: CategoryColor) {
        self.id = id
        self.name = name
        self.color = color
    }
}

public enum CategoryColor: Int, Codable, CaseIterable {
    case neonPink = 1      // #FF006E
    case electricBlue = 2  // #00F5FF
    case acidGreen = 3     // #39FF14
    case hotOrange = 4     // #FF6B35
    case deepPurple = 5    // #9D4EDD
    case goldenYellow = 6  // #FFE66D
    case crimsonRed = 7    // #DC143C
    case mintGreen = 8     // #00FF7F
    case skyBlue = 9       // #87CEEB
    case lavender = 10     // #E6E6FA
    
    var color: Color {
        switch self {
        case .neonPink: return Color(hex: "FF006E")
        case .electricBlue: return Color(hex: "00F5FF")
        case .acidGreen: return Color(hex: "39FF14")
        case .hotOrange: return Color(hex: "FF6B35")
        case .deepPurple: return Color(hex: "9D4EDD")
        case .goldenYellow: return Color(hex: "FFE66D")
        case .crimsonRed: return Color(hex: "DC143C")
        case .mintGreen: return Color(hex: "00FF7F")
        case .skyBlue: return Color(hex: "87CEEB")
        case .lavender: return Color(hex: "E6E6FA")
        }
    }
    
    var textColor: Color {
        // Return white or black based on luminance for readability
        switch self {
        case .goldenYellow, .mintGreen, .skyBlue, .lavender:
            return Color.black
        default:
            return Color.white
        }
    }
}
```

### 4. CalendarEvent Model

```swift
public struct CalendarEvent: Identifiable, Codable, Equatable {
    public let id: UUID
    public var categoryId: Int
    public var startDate: Date
    public var endDate: Date
    public var label: String
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        categoryId: Int,
        startDate: Date,
        endDate: Date,
        label: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.categoryId = categoryId
        self.startDate = startDate
        self.endDate = endDate
        self.label = label
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Returns true if event spans the given date
    public func contains(date: Date) -> Bool {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let target = calendar.startOfDay(for: date)
        return target >= start && target <= end
    }
    
    /// Duration in days (inclusive)
    public var durationDays: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        return calendar.dateComponents([.day], from: start, to: end).day! + 1
    }
}
```

### 5. TaskActivityStats

```swift
public struct TaskActivityStats {
    public let date: Date
    public let tasksAdded: Int
    public let tasksCompleted: Int
    
    public init(date: Date, tasksAdded: Int, tasksCompleted: Int) {
        self.date = date
        self.tasksAdded = tasksAdded
        self.tasksCompleted = tasksCompleted
    }
}
```

### 6. EventCategoryManager

```swift
public final class EventCategoryManager: ObservableObject {
    public static let shared = EventCategoryManager()
    
    @Published public private(set) var categories: [EventCategory] = []
    
    private let defaults = UserDefaults.standard
    private let categoriesKey = "eventCategoryNames"
    
    private init() {
        loadCategories()
    }
    
    /// Load categories with persisted names
    public func loadCategories() {
        let savedNames = defaults.dictionary(forKey: categoriesKey) as? [String: String] ?? [:]
        
        categories = CategoryColor.allCases.map { color in
            let defaultName = "Category \(color.rawValue)"
            let name = savedNames[String(color.rawValue)] ?? defaultName
            return EventCategory(id: color.rawValue, name: name, color: color)
        }
    }
    
    /// Update category name
    public func updateCategoryName(id: Int, name: String) {
        guard let index = categories.firstIndex(where: { $0.id == id }) else { return }
        categories[index].name = name
        saveCategoryNames()
    }
    
    /// Get category by ID
    public func category(for id: Int) -> EventCategory? {
        categories.first { $0.id == id }
    }
    
    private func saveCategoryNames() {
        var names: [String: String] = [:]
        for category in categories {
            names[String(category.id)] = category.name
        }
        defaults.set(names, forKey: categoriesKey)
    }
}
```

### 7. CalendarEventManager

```swift
public final class CalendarEventManager: ObservableObject {
    public static let shared = CalendarEventManager()
    
    @Published public private(set) var events: [CalendarEvent] = []
    
    private init() {
        loadEvents()
    }
    
    /// Load all events from database
    public func loadEvents() {
        do {
            let pool = try DatabaseManager.shared.getPool()
            events = try pool.read { db in
                try CalendarEventRecord.fetchAll(db).compactMap { $0.toCalendarEvent() }
            }
        } catch {
            print("Failed to load calendar events: \(error)")
            events = []
        }
    }
    
    /// Create a new event
    @discardableResult
    public func createEvent(categoryId: Int, startDate: Date, endDate: Date, label: String) -> CalendarEvent {
        let event = CalendarEvent(
            categoryId: categoryId,
            startDate: startDate,
            endDate: endDate,
            label: label
        )
        saveEvent(event)
        return event
    }
    
    /// Update an existing event
    public func updateEvent(_ event: CalendarEvent) {
        var updated = event
        updated.updatedAt = Date()
        saveEvent(updated)
    }
    
    /// Delete an event
    public func deleteEvent(id: UUID) {
        do {
            let pool = try DatabaseManager.shared.getPool()
            try pool.write { db in
                try db.execute(sql: "DELETE FROM calendar_events WHERE id = ?", arguments: [id.uuidString])
            }
            loadEvents()
        } catch {
            print("Failed to delete calendar event: \(error)")
        }
    }
    
    /// Get events for a specific year
    public func events(forYear year: Int) -> [CalendarEvent] {
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endOfYear = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!
        
        return events.filter { event in
            // Event overlaps with year if it starts before year ends AND ends after year starts
            event.startDate <= endOfYear && event.endDate >= startOfYear
        }
    }
    
    /// Get events that contain a specific date
    public func events(containing date: Date) -> [CalendarEvent] {
        events.filter { $0.contains(date: date) }
    }
    
    private func saveEvent(_ event: CalendarEvent) {
        do {
            let pool = try DatabaseManager.shared.getPool()
            let record = CalendarEventRecord(from: event)
            try pool.write { db in
                try record.save(db)
            }
            loadEvents()
        } catch {
            print("Failed to save calendar event: \(error)")
        }
    }
}
```

### 8. TaskManager Extension for Activity Stats

```swift
extension TaskManager {
    /// Get task activity stats for a date range
    public func getActivityStats(for year: Int) -> [Date: TaskActivityStats] {
        let calendar = Calendar.current
        var stats: [Date: TaskActivityStats] = [:]
        
        for task in tasks {
            // Count tasks added
            let createdDay = calendar.startOfDay(for: task.createdAt)
            if calendar.component(.year, from: createdDay) == year {
                let existing = stats[createdDay] ?? TaskActivityStats(date: createdDay, tasksAdded: 0, tasksCompleted: 0)
                stats[createdDay] = TaskActivityStats(
                    date: createdDay,
                    tasksAdded: existing.tasksAdded + 1,
                    tasksCompleted: existing.tasksCompleted
                )
            }
            
            // Count tasks completed (using updatedAt when status is completed)
            if task.status == .completed {
                let completedDay = calendar.startOfDay(for: task.updatedAt)
                if calendar.component(.year, from: completedDay) == year {
                    let existing = stats[completedDay] ?? TaskActivityStats(date: completedDay, tasksAdded: 0, tasksCompleted: 0)
                    stats[completedDay] = TaskActivityStats(
                        date: completedDay,
                        tasksAdded: existing.tasksAdded,
                        tasksCompleted: existing.tasksCompleted + 1
                    )
                }
            }
        }
        
        return stats
    }
}
```

## Data Models

### Database Schema Extension

Add to DatabaseManager migrations:

```swift
// calendar_events table
try db.create(table: "calendar_events", ifNotExists: true) { t in
    t.column("id", .text).primaryKey()
    t.column("category_id", .integer).notNull()
    t.column("start_date", .text).notNull()
    t.column("end_date", .text).notNull()
    t.column("label", .text).notNull()
    t.column("created_at", .text).notNull()
    t.column("updated_at", .text).notNull()
}

// Create index for efficient year queries
try db.create(index: "idx_calendar_events_dates", on: "calendar_events", columns: ["start_date", "end_date"], ifNotExists: true)
```

### CalendarEventRecord (GRDB)

```swift
struct CalendarEventRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "calendar_events"
    
    var id: String
    var categoryId: Int
    var startDate: String
    var endDate: String
    var label: String
    var createdAt: String
    var updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case label
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from event: CalendarEvent) {
        let formatter = ISO8601DateFormatter()
        self.id = event.id.uuidString
        self.categoryId = event.categoryId
        self.startDate = formatter.string(from: event.startDate)
        self.endDate = formatter.string(from: event.endDate)
        self.label = event.label
        self.createdAt = formatter.string(from: event.createdAt)
        self.updatedAt = formatter.string(from: event.updatedAt)
    }
    
    func toCalendarEvent() -> CalendarEvent? {
        let formatter = ISO8601DateFormatter()
        guard let uuid = UUID(uuidString: id),
              let start = formatter.date(from: startDate),
              let end = formatter.date(from: endDate),
              let created = formatter.date(from: createdAt),
              let updated = formatter.date(from: updatedAt) else {
            return nil
        }
        
        return CalendarEvent(
            id: uuid,
            categoryId: categoryId,
            startDate: start,
            endDate: end,
            label: label,
            createdAt: created,
            updatedAt: updated
        )
    }
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*



### Property 1: Settings Toggle Controls Tab Visibility

*For any* boolean value of the showAnnualCalendar setting, the Annual tab should be visible in the navigation bar if and only if the setting is true.

**Validates: Requirements 1.2, 1.3**

### Property 2: Settings Toggle Persistence Round-Trip

*For any* boolean value written to the showAnnualCalendar setting, reading the setting after a simulated app restart should return the same value.

**Validates: Requirements 1.4, 1.5**

### Property 3: Day Cell Displays Correct Date Information

*For any* valid date in a calendar year, the day cell should display the correct day number (1-31) and the correct day-of-week abbreviation (Mon, Tue, etc.).

**Validates: Requirements 2.3**

### Property 4: Year Selection Updates Calendar Display

*For any* year in the range 2025-2035, selecting that year should result in the calendar displaying exactly 12 months with the correct number of days for each month in that year (accounting for leap years).

**Validates: Requirements 2.7**

### Property 5: Category Name Editing

*For any* category ID (1-10) and any non-empty string name, updating the category name should result in the category having that name when retrieved.

**Validates: Requirements 3.3**

### Property 6: Category Name Persistence Round-Trip

*For any* category ID and name, saving the category name and then reloading categories should return the same name for that category.

**Validates: Requirements 3.4**

### Property 7: Event Date Containment

*For any* calendar event with start date S and end date E, and any date D, the event's `contains(date:)` method should return true if and only if S ≤ D ≤ E (comparing at day granularity).

**Validates: Requirements 4.3**

### Property 8: Event Label Accessibility

*For any* calendar event created with a label string, the event's label property should equal the original label string.

**Validates: Requirements 4.5**

### Property 9: Event Persistence Round-Trip

*For any* valid calendar event (with category ID 1-10, valid start/end dates where start ≤ end, and non-empty label), creating the event, reloading from persistence, and retrieving by ID should return an event with identical categoryId, startDate, endDate, and label.

**Validates: Requirements 4.8, 7.1, 7.3**

### Property 10: Task Activity Stats Accuracy

*For any* set of tasks with various createdAt and updatedAt dates, the activity stats for a given date should correctly count:
- tasksAdded: number of tasks where createdAt falls on that date
- tasksCompleted: number of tasks where status is .completed AND updatedAt falls on that date

**Validates: Requirements 6.1, 6.2**

## Error Handling

### Database Errors

- **Event save failure**: Log error, display user-friendly message via StatusBarManager, do not update local state
- **Event load failure**: Log error, initialize with empty events array, display warning to user
- **Category load failure**: Fall back to default category names, log warning

### Input Validation

- **Empty event label**: Prevent creation, show validation message in Event_Editor
- **Invalid date range (end < start)**: Swap dates automatically or show validation error
- **Category ID out of range**: Default to category 1

### Edge Cases

- **Leap year handling**: Use Calendar API for accurate day counts
- **Events spanning year boundaries**: Filter correctly using overlap logic (event.startDate ≤ yearEnd AND event.endDate ≥ yearStart)
- **Zero task counts**: Display "↑0" and "↓0" as specified

## UI Responsiveness

### Responsive Tab Bar

The tab bar adapts to window width using GeometryReader:

```swift
GeometryReader { geometry in
    let showTabText = geometry.size.width > 700
    
    HStack(spacing: showTabText ? CyberpunkTheme.spacingL : CyberpunkTheme.spacingM) {
        ForEach(NavigationTab.visibleTabs(showAnnual: settingsManager.showAnnualCalendar), id: \.self) { tab in
            TabButton(
                tab: tab,
                isSelected: selectedTab == tab,
                showText: showTabText
            ) { ... }
        }
        
        // Search bar - hide when very narrow
        if geometry.size.width > 600 {
            searchBar
        }
        
        // Model selector - hide when narrow
        if geometry.size.width > 800 {
            ModelSelectorView(llmSummarizer: llmSummarizer)
        }
    }
}
```

### Responsive Kanban Board

The Kanban board uses GeometryReader to calculate equal column widths:

```swift
GeometryReader { geometry in
    let columnCount = CGFloat(KanbanColumn.allCases.count)
    let totalSpacing = CyberpunkTheme.spacingM * (columnCount - 1) + CyberpunkTheme.spacingM * 2
    let availableWidth = geometry.size.width - totalSpacing
    let columnWidth = max(140, availableWidth / columnCount)
    
    HStack(alignment: .top, spacing: CyberpunkTheme.spacingM) {
        ForEach(KanbanColumn.allCases, id: \.self) { column in
            KanbanColumnView(...)
                .frame(width: columnWidth)
        }
    }
}
```

## Event Drag and Resize

### Event Block with Drag-to-Move and Drag-to-Resize

```swift
public struct EventBlockView: View {
    let event: CalendarEvent
    let category: EventCategory?
    var onMove: ((CalendarEvent, Date) -> Void)?
    var onResize: ((CalendarEvent, Date) -> Void)?
    
    @State private var isDragging = false
    @State private var isResizing = false
    @State private var dragOffset: CGSize = .zero
    @State private var resizeDelta: Int = 0
    
    private let dayCellHeight: CGFloat = DayCellView.cellHeight
    
    var body: some View {
        HStack(spacing: 0) {
            // Main event block - draggable to move
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(categoryColor.opacity(0.85))
                // ... event label and duration indicator
            }
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        isDragging = false
                        let daysMoved = Int(round(value.translation.height / dayCellHeight))
                        if daysMoved != 0, let onMove = onMove {
                            let calendar = Calendar.current
                            if let newStartDate = calendar.date(byAdding: .day, value: daysMoved, to: event.startDate) {
                                onMove(event, newStartDate)
                            }
                        }
                        dragOffset = .zero
                    }
            )
            
            // Resize handle on the right edge
            ResizeHandleCompact(
                color: categoryColor,
                isActive: isResizing,
                onDrag: { delta in
                    isResizing = true
                    resizeDelta = Int(round(delta / dayCellHeight))
                },
                onDragEnd: { delta in
                    isResizing = false
                    let daysChange = Int(round(delta / dayCellHeight))
                    if daysChange != 0, let onResize = onResize {
                        let calendar = Calendar.current
                        if let newEndDate = calendar.date(byAdding: .day, value: daysChange, to: event.endDate) {
                            if newEndDate >= event.startDate {
                                onResize(event, newEndDate)
                            }
                        }
                    }
                    resizeDelta = 0
                }
            )
        }
    }
}
```

### Move Event Handler (preserves duration)

```swift
private func moveEvent(_ event: CalendarEvent, to newStartDate: Date) {
    let duration = calendar.dateComponents([.day], from: event.startDate, to: event.endDate).day ?? 0
    guard let newEndDate = calendar.date(byAdding: .day, value: duration, to: newStartDate) else { return }
    
    let updatedEvent = CalendarEvent(
        id: event.id,
        categoryId: event.categoryId,
        startDate: newStartDate,
        endDate: newEndDate,
        label: event.label,
        createdAt: event.createdAt,
        updatedAt: Date()
    )
    eventManager.updateEvent(updatedEvent)
}
```

### Resize Event Handler

```swift
private func resizeEvent(_ event: CalendarEvent, to newEndDate: Date) {
    let finalEndDate = newEndDate >= event.startDate ? newEndDate : event.startDate
    
    let updatedEvent = CalendarEvent(
        id: event.id,
        categoryId: event.categoryId,
        startDate: event.startDate,
        endDate: finalEndDate,
        label: event.label,
        createdAt: event.createdAt,
        updatedAt: Date()
    )
    eventManager.updateEvent(updatedEvent)
}
```

## Testing Strategy

### Unit Tests

Unit tests verify specific examples and edge cases:

1. **Calendar date calculations**
   - Verify correct number of days per month for regular and leap years
   - Test month boundary calculations
   - Test year boundary handling

2. **Event model**
   - Test `contains(date:)` with boundary dates
   - Test `durationDays` calculation
   - Test event spanning month/year boundaries

3. **Category defaults**
   - Verify exactly 10 categories exist
   - Verify default names are "Category 1" through "Category 10"
   - Verify all colors are distinct

4. **Task activity edge cases**
   - Zero tasks on a date
   - Multiple tasks created/completed same day
   - Task created and completed on different days

### Property-Based Tests

Property-based tests verify universal properties across many generated inputs. Each test should run minimum 100 iterations.

**Testing Framework**: Swift's built-in XCTest with custom property testing helpers or SwiftCheck library.

1. **Property 1 Test**: Generate random boolean values, set showAnnualCalendar, verify NavigationTab.visibleTabs output
   - Tag: **Feature: annual-calendar, Property 1: Settings toggle controls tab visibility**

2. **Property 2 Test**: Generate random booleans, write to UserDefaults, clear cache, read back
   - Tag: **Feature: annual-calendar, Property 2: Settings toggle persistence round-trip**

3. **Property 3 Test**: Generate random dates in 2025-2035 range, verify day number and weekday
   - Tag: **Feature: annual-calendar, Property 3: Day cell displays correct date information**

4. **Property 4 Test**: Generate random years 2025-2035, verify month/day counts
   - Tag: **Feature: annual-calendar, Property 4: Year selection updates calendar display**

5. **Property 5 Test**: Generate random category IDs (1-10) and non-empty strings, update and verify
   - Tag: **Feature: annual-calendar, Property 5: Category name editing**

6. **Property 6 Test**: Generate category ID and name, save, reload manager, verify name
   - Tag: **Feature: annual-calendar, Property 6: Category name persistence round-trip**

7. **Property 7 Test**: Generate random start/end dates and test dates, verify contains() logic
   - Tag: **Feature: annual-calendar, Property 7: Event date containment**

8. **Property 8 Test**: Generate random label strings, create events, verify label preserved
   - Tag: **Feature: annual-calendar, Property 8: Event label accessibility**

9. **Property 9 Test**: Generate valid events, save to DB, reload, verify equality
   - Tag: **Feature: annual-calendar, Property 9: Event persistence round-trip**

10. **Property 10 Test**: Generate random tasks with dates, compute stats, verify counts
    - Tag: **Feature: annual-calendar, Property 10: Task activity stats accuracy**

### Integration Tests

- Test full flow: enable Annual tab → create event → verify persistence → reload app → verify event exists
- Test category rename flow with event display update
- Test task activity indicators update when tasks are created/completed
