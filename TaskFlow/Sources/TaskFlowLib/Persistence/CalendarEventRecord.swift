import Foundation
import GRDB

/// GRDB record for CalendarEvent persistence
/// Per Requirement 7.1
public struct CalendarEventRecord: Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "calendar_events"
    
    public var id: String
    public var categoryId: Int
    public var startDate: String
    public var endDate: String
    public var label: String
    public var createdAt: String
    public var updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case label
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Convert from domain CalendarEvent model
    public init(from event: CalendarEvent) {
        let formatter = ISO8601DateFormatter()
        self.id = event.id.uuidString
        self.categoryId = event.categoryId
        self.startDate = formatter.string(from: event.startDate)
        self.endDate = formatter.string(from: event.endDate)
        self.label = event.label
        self.createdAt = formatter.string(from: event.createdAt)
        self.updatedAt = formatter.string(from: event.updatedAt)
    }
    
    /// Convert to domain CalendarEvent model
    public func toCalendarEvent() -> CalendarEvent? {
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
