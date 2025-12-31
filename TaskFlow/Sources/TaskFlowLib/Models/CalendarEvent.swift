import Foundation

/// A calendar event spanning one or more days
/// Per Requirements 4.3, 7.4
public struct CalendarEvent: Identifiable, Codable, Equatable {
    /// Unique identifier for the event
    public let id: UUID
    
    /// Category ID (1-10) for color coding
    public var categoryId: Int
    
    /// Start date of the event (inclusive)
    public var startDate: Date
    
    /// End date of the event (inclusive)
    public var endDate: Date
    
    /// User-entered text label for the event
    public var label: String
    
    /// When the event was created
    public let createdAt: Date
    
    /// When the event was last updated
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
    
    /// Returns true if the event spans the given date (at day granularity)
    /// Per Requirement 4.3
    public func contains(date: Date) -> Bool {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let target = calendar.startOfDay(for: date)
        return target >= start && target <= end
    }
    
    /// Duration in days (inclusive of both start and end)
    public var durationDays: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return days + 1  // +1 because both start and end are inclusive
    }
    
    /// Returns true if the event overlaps with the given year
    public func overlaps(year: Int) -> Bool {
        let calendar = Calendar.current
        guard let yearStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let yearEnd = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) else {
            return false
        }
        // Event overlaps if it starts before year ends AND ends after year starts
        return startDate <= yearEnd && endDate >= yearStart
    }
}
