import SwiftUI
import AppKit

/// Annual Calendar View - Main view for the Annual Calendar feature
/// Per Requirements 2.1, 2.2, 2.4, 4.1, 5.2, 5.5, 8.3
/// Feature: annual-calendar
public struct AnnualCalendarView: View {
    @ObservedObject var taskManager: TaskManager
    @ObservedObject private var eventManager = CalendarEventManager.shared
    @ObservedObject private var categoryManager = EventCategoryManager.shared
    
    @State private var selectedYear: Int = 2026
    @State private var showingEventEditor = false
    @State private var showingCategoryEditor = false
    @State private var editingEvent: CalendarEvent?
    @State private var newEventStartDate: Date?
    @State private var newEventEndDate: Date?
    @State private var selectedDate: Date?  // For keyboard navigation
    @State private var keyboardMonitor: Any?
    
    private let calendar = Calendar.current
    private let yearRange = 2025...2035
    
    public init(taskManager: TaskManager) {
        self.taskManager = taskManager
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header with year selector
            headerView
            
            Divider()
                .background(CyberpunkTheme.accentYellow.opacity(0.3))
            
            // Calendar grid
            ScrollView([.horizontal, .vertical]) {
                calendarGrid
                    .padding(CyberpunkTheme.spacingM)
            }
        }
        .background(CyberpunkTheme.backgroundPrimary)
        .onAppear {
            setupKeyboardMonitor()
        }
        .onDisappear {
            removeKeyboardMonitor()
        }
        .sheet(isPresented: $showingEventEditor) {
            if let event = editingEvent {
                EventEditorSheet(
                    event: event,
                    categoryManager: categoryManager,
                    onSave: { updatedEvent in
                        eventManager.updateEvent(updatedEvent)
                        editingEvent = nil
                        showingEventEditor = false
                    },
                    onDelete: {
                        eventManager.deleteEvent(id: event.id)
                        editingEvent = nil
                        showingEventEditor = false
                    },
                    onCancel: {
                        editingEvent = nil
                        showingEventEditor = false
                    }
                )
            } else if let startDate = newEventStartDate {
                EventEditorSheet(
                    startDate: startDate,
                    endDate: newEventEndDate ?? startDate,
                    categoryManager: categoryManager,
                    onSave: { newEvent in
                        _ = eventManager.createEvent(
                            categoryId: newEvent.categoryId,
                            startDate: newEvent.startDate,
                            endDate: newEvent.endDate,
                            label: newEvent.label
                        )
                        newEventStartDate = nil
                        newEventEndDate = nil
                        showingEventEditor = false
                    },
                    onCancel: {
                        newEventStartDate = nil
                        newEventEndDate = nil
                        showingEventEditor = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingCategoryEditor) {
            CategoryEditorView(
                categoryManager: categoryManager,
                onDismiss: {
                    showingCategoryEditor = false
                }
            )
        }
    }
    
    // MARK: - Keyboard Navigation
    
    /// Set up keyboard event monitor for arrow key navigation
    private func setupKeyboardMonitor() {
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Only handle if no sheet is showing
            guard !showingEventEditor && !showingCategoryEditor else {
                return event
            }
            
            switch event.keyCode {
            case 123: // Left arrow
                navigateDay(by: -1)
                return nil
            case 124: // Right arrow
                navigateDay(by: 1)
                return nil
            case 125: // Down arrow
                navigateDay(by: 7)
                return nil
            case 126: // Up arrow
                navigateDay(by: -7)
                return nil
            case 36: // Return/Enter
                if let date = selectedDate {
                    openEventEditor(for: date)
                }
                return nil
            case 53: // Escape
                selectedDate = nil
                return nil
            default:
                return event
            }
        }
    }
    
    /// Remove keyboard event monitor
    private func removeKeyboardMonitor() {
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardMonitor = nil
        }
    }
    
    /// Navigate by a number of days
    private func navigateDay(by days: Int) {
        let currentDate = selectedDate ?? calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1))!
        if let newDate = calendar.date(byAdding: .day, value: days, to: currentDate) {
            // Check if new date is within the year range
            let newYear = calendar.component(.year, from: newDate)
            if yearRange.contains(newYear) {
                selectedDate = newDate
                // Update selected year if navigating to a different year
                if newYear != selectedYear {
                    selectedYear = newYear
                }
            }
        }
    }
    
    /// Open event editor for a date
    private func openEventEditor(for date: Date) {
        newEventStartDate = date
        newEventEndDate = date
        editingEvent = nil
        showingEventEditor = true
    }
    
    // MARK: - Event Drag & Drop
    
    /// Move an event to a new start date (preserving duration)
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
    
    /// Resize an event by changing its end date
    private func resizeEvent(_ event: CalendarEvent, to newEndDate: Date) {
        // Ensure end date is not before start date
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
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Text("Annual Calendar")
                .font(CyberpunkTheme.fontTitle)
                .foregroundColor(CyberpunkTheme.accentYellow)
            
            Spacer()
            
            // Year selector
            YearSelectorView(
                selectedYear: $selectedYear,
                yearRange: yearRange
            )
            
            Spacer()
            
            // Help text
            Text("Drag events to move • Drag bottom edge to resize")
                .font(.system(size: 10))
                .foregroundColor(CyberpunkTheme.textTertiary)
            
            Spacer()
            
            // Category legend button
            Button(action: {
                showingCategoryEditor = true
            }) {
                HStack(spacing: CyberpunkTheme.spacingXS) {
                    Image(systemName: "paintpalette")
                    Text("Categories")
                }
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(CyberpunkTheme.textSecondary)
                .padding(.horizontal, CyberpunkTheme.spacingS)
                .padding(.vertical, CyberpunkTheme.spacingXS)
                .background(
                    RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                        .stroke(CyberpunkTheme.textTertiary.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(CyberpunkTheme.spacingM)
        .background(CyberpunkTheme.backgroundSecondary)
    }
    
    // MARK: - Calendar Grid
    
    private var calendarGrid: some View {
        HStack(alignment: .top, spacing: CyberpunkTheme.spacingS) {
            ForEach(1...12, id: \.self) { month in
                MonthColumnView(
                    year: selectedYear,
                    month: month,
                    events: eventsForMonth(month),
                    activityStats: taskManager.getActivityStats(for: selectedYear),
                    categoryManager: categoryManager,
                    selectedDate: selectedDate,
                    onDayTap: { date in
                        selectedDate = date
                        newEventStartDate = date
                        newEventEndDate = date
                        editingEvent = nil
                        showingEventEditor = true
                    },
                    onEventTap: { event in
                        editingEvent = event
                        showingEventEditor = true
                    },
                    onEventMove: moveEvent,
                    onEventResize: resizeEvent
                )
            }
        }
    }
    
    // MARK: - Helpers
    
    private func eventsForMonth(_ month: Int) -> [CalendarEvent] {
        let yearEvents = eventManager.events(forYear: selectedYear)
        return yearEvents.filter { event in
            let startMonth = calendar.component(.month, from: event.startDate)
            let endMonth = calendar.component(.month, from: event.endDate)
            let startYear = calendar.component(.year, from: event.startDate)
            let endYear = calendar.component(.year, from: event.endDate)
            
            // Event overlaps with this month if:
            // - Starts in this month, or
            // - Ends in this month, or
            // - Spans across this month
            if startYear == selectedYear && endYear == selectedYear {
                return startMonth <= month && endMonth >= month
            } else if startYear < selectedYear && endYear == selectedYear {
                return endMonth >= month
            } else if startYear == selectedYear && endYear > selectedYear {
                return startMonth <= month
            }
            return false
        }
    }
}
