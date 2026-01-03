import Foundation

/// Manages calendar events for the Annual Calendar
/// Per Requirements 4.3, 4.8, 7.1, 7.3
public final class TFMCalendarEventManager: ObservableObject {
    
    /// Shared singleton instance
    public static let shared = TFMCalendarEventManager()
    
    /// All calendar events
    @Published public private(set) var events: [CalendarEvent] = []
    
    private init() {
        loadEvents()
    }
    
    // MARK: - CRUD Operations
    
    /// Load all events from database
    /// Per Requirement 7.3
    public func loadEvents() {
        do {
            let pool = try DatabaseManager.shared.getPool()
            events = try pool.read { db in
                try CalendarEventRecord.fetchAll(db).compactMap { $0.toCalendarEvent() }
            }
        } catch {
            print("TFMCalendarEventManager: Failed to load events: \(error)")
            events = []
        }
    }
    
    /// Create a new calendar event
    /// Per Requirement 4.8
    @discardableResult
    public func createEvent(
        categoryId: Int,
        startDate: Date,
        endDate: Date,
        label: String
    ) -> CalendarEvent {
        // Ensure start <= end
        let (start, end) = startDate <= endDate ? (startDate, endDate) : (endDate, startDate)
        
        let event = CalendarEvent(
            categoryId: categoryId,
            startDate: start,
            endDate: end,
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
    
    /// Delete an event by ID
    public func deleteEvent(id: UUID) {
        do {
            let pool = try DatabaseManager.shared.getPool()
            try pool.write { db in
                try db.execute(
                    sql: "DELETE FROM calendar_events WHERE id = ?",
                    arguments: [id.uuidString]
                )
            }
            loadEvents()
        } catch {
            print("TFMCalendarEventManager: Failed to delete event: \(error)")
        }
    }
    
    // MARK: - Query Methods
    
    /// Get events for a specific year
    public func events(forYear year: Int) -> [CalendarEvent] {
        events.filter { $0.overlaps(year: year) }
    }
    
    /// Get events that contain a specific date
    public func events(containing date: Date) -> [CalendarEvent] {
        events.filter { $0.contains(date: date) }
    }
    
    /// Get event by ID
    public func event(for id: UUID) -> CalendarEvent? {
        events.first { $0.id == id }
    }
    
    /// Get events for a specific category
    public func events(forCategory categoryId: Int) -> [CalendarEvent] {
        events.filter { $0.categoryId == categoryId }
    }
    
    /// Get events within a date range
    public func events(from startDate: Date, to endDate: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        
        return events.filter { event in
            let eventStart = calendar.startOfDay(for: event.startDate)
            let eventEnd = calendar.startOfDay(for: event.endDate)
            // Event overlaps range if it starts before range ends AND ends after range starts
            return eventStart <= end && eventEnd >= start
        }
    }
    
    // MARK: - Private Helpers
    
    /// Save an event to the database
    private func saveEvent(_ event: CalendarEvent) {
        do {
            let pool = try DatabaseManager.shared.getPool()
            let record = CalendarEventRecord(from: event)
            try pool.write { db in
                try record.save(db)
            }
            loadEvents()
        } catch {
            print("TFMCalendarEventManager: Failed to save event: \(error)")
        }
    }
}

// MARK: - Backward Compatibility

@available(*, deprecated, renamed: "TFMCalendarEventManager")
public typealias CalendarEventManager = TFMCalendarEventManager
