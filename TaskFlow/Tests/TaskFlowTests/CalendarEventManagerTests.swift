import XCTest
@testable import TaskFlowLib

/// Calendar Event Manager Tests
/// Feature: annual-calendar
final class CalendarEventManagerTests: XCTestCase {
    
    // MARK: - Property 9: Event Persistence Round-Trip
    // For any valid calendar event, creating the event, reloading from persistence,
    // and retrieving by ID should return an event with identical properties.
    // **Validates: Requirements 4.8, 7.1, 7.3**
    
    func testEventPersistenceRoundTripProperty() throws {
        // Initialize test database
        try DatabaseManager.shared.initializeInMemory()
        
        let manager = CalendarEventManager.shared
        let calendar = Calendar.current
        
        // Property test: run 100 iterations
        for _ in 0..<100 {
            // Generate random valid event data
            let categoryId = Int.random(in: 1...10)
            
            // Random start date in 2025-2035
            let year = Int.random(in: 2025...2035)
            let month = Int.random(in: 1...12)
            let day = Int.random(in: 1...28)
            guard let startDate = calendar.date(from: DateComponents(
                year: year, month: month, day: day
            )) else { continue }
            
            // End date 0-30 days after start
            let daysToAdd = Int.random(in: 0...30)
            guard let endDate = calendar.date(byAdding: .day, value: daysToAdd, to: startDate) else {
                continue
            }
            
            // Random non-empty label
            let labelLength = Int.random(in: 1...50)
            let label = String((0..<labelLength).map { _ in
                "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ".randomElement()!
            })
            
            // Create event
            let createdEvent = manager.createEvent(
                categoryId: categoryId,
                startDate: startDate,
                endDate: endDate,
                label: label
            )
            
            // Reload from persistence
            manager.loadEvents()
            
            // Retrieve by ID
            let retrievedEvent = manager.event(for: createdEvent.id)
            
            // Verify round-trip
            XCTAssertNotNil(retrievedEvent, "Event should exist after reload")
            XCTAssertEqual(retrievedEvent?.categoryId, categoryId, "Category ID should match")
            XCTAssertEqual(retrievedEvent?.label, label, "Label should match")
            
            // Compare dates at day granularity
            if let retrieved = retrievedEvent {
                let startMatch = calendar.isDate(retrieved.startDate, inSameDayAs: startDate)
                let endMatch = calendar.isDate(retrieved.endDate, inSameDayAs: endDate)
                XCTAssertTrue(startMatch, "Start date should match")
                XCTAssertTrue(endMatch, "End date should match")
            }
            
            // Clean up
            manager.deleteEvent(id: createdEvent.id)
        }
    }
    
    // MARK: - Property 8: Event Label Accessibility
    // For any calendar event created with a label string,
    // the event's label property should equal the original label string.
    // **Validates: Requirements 4.5**
    
    func testEventLabelAccessibilityProperty() throws {
        try DatabaseManager.shared.initializeInMemory()
        
        let manager = CalendarEventManager.shared
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        
        // Property test: run 100 iterations
        for _ in 0..<100 {
            // Generate random label with various characters
            let labelLength = Int.random(in: 1...100)
            let label = String((0..<labelLength).map { _ in
                "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_.,!?".randomElement()!
            })
            
            // Create event
            let event = manager.createEvent(
                categoryId: 1,
                startDate: baseDate,
                endDate: baseDate,
                label: label
            )
            
            // Verify label is accessible and matches
            XCTAssertEqual(event.label, label, "Event label should match original")
            
            // Verify after retrieval
            let retrieved = manager.event(for: event.id)
            XCTAssertEqual(retrieved?.label, label, "Retrieved event label should match")
            
            // Clean up
            manager.deleteEvent(id: event.id)
        }
    }
    
    // MARK: - Unit Tests
    
    func testCreateEvent() throws {
        try DatabaseManager.shared.initializeInMemory()
        
        let manager = CalendarEventManager.shared
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2026, month: 7, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: 2026, month: 7, day: 15))!
        
        let event = manager.createEvent(
            categoryId: 3,
            startDate: startDate,
            endDate: endDate,
            label: "Summer Holiday"
        )
        
        XCTAssertEqual(event.categoryId, 3)
        XCTAssertEqual(event.label, "Summer Holiday")
        XCTAssertTrue(calendar.isDate(event.startDate, inSameDayAs: startDate))
        XCTAssertTrue(calendar.isDate(event.endDate, inSameDayAs: endDate))
        
        // Clean up
        manager.deleteEvent(id: event.id)
    }
    
    func testCreateEventSwapsDatesIfNeeded() throws {
        try DatabaseManager.shared.initializeInMemory()
        
        let manager = CalendarEventManager.shared
        let calendar = Calendar.current
        let laterDate = calendar.date(from: DateComponents(year: 2026, month: 7, day: 15))!
        let earlierDate = calendar.date(from: DateComponents(year: 2026, month: 7, day: 1))!
        
        // Pass dates in wrong order
        let event = manager.createEvent(
            categoryId: 1,
            startDate: laterDate,
            endDate: earlierDate,
            label: "Test"
        )
        
        // Should swap to correct order
        XCTAssertTrue(event.startDate <= event.endDate, "Start should be before or equal to end")
        
        // Clean up
        manager.deleteEvent(id: event.id)
    }
    
    func testDeleteEvent() throws {
        try DatabaseManager.shared.initializeInMemory()
        
        let manager = CalendarEventManager.shared
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        
        let event = manager.createEvent(
            categoryId: 1,
            startDate: date,
            endDate: date,
            label: "To Delete"
        )
        
        let eventId = event.id
        XCTAssertNotNil(manager.event(for: eventId))
        
        manager.deleteEvent(id: eventId)
        
        XCTAssertNil(manager.event(for: eventId), "Event should be deleted")
    }
    
    func testEventsForYear() throws {
        try DatabaseManager.shared.initializeInMemory()
        
        let manager = CalendarEventManager.shared
        let calendar = Calendar.current
        
        // Create events in different years
        let event2025 = manager.createEvent(
            categoryId: 1,
            startDate: calendar.date(from: DateComponents(year: 2025, month: 6, day: 1))!,
            endDate: calendar.date(from: DateComponents(year: 2025, month: 6, day: 15))!,
            label: "2025 Event"
        )
        
        let event2026 = manager.createEvent(
            categoryId: 2,
            startDate: calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!,
            endDate: calendar.date(from: DateComponents(year: 2026, month: 3, day: 10))!,
            label: "2026 Event"
        )
        
        let events2025 = manager.events(forYear: 2025)
        let events2026 = manager.events(forYear: 2026)
        
        XCTAssertTrue(events2025.contains { $0.id == event2025.id })
        XCTAssertFalse(events2025.contains { $0.id == event2026.id })
        
        XCTAssertTrue(events2026.contains { $0.id == event2026.id })
        XCTAssertFalse(events2026.contains { $0.id == event2025.id })
        
        // Clean up
        manager.deleteEvent(id: event2025.id)
        manager.deleteEvent(id: event2026.id)
    }
    
    func testEventsContainingDate() throws {
        try DatabaseManager.shared.initializeInMemory()
        
        let manager = CalendarEventManager.shared
        let calendar = Calendar.current
        
        let event = manager.createEvent(
            categoryId: 1,
            startDate: calendar.date(from: DateComponents(year: 2026, month: 6, day: 10))!,
            endDate: calendar.date(from: DateComponents(year: 2026, month: 6, day: 20))!,
            label: "Test Event"
        )
        
        let june15 = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        let june5 = calendar.date(from: DateComponents(year: 2026, month: 6, day: 5))!
        let june25 = calendar.date(from: DateComponents(year: 2026, month: 6, day: 25))!
        
        XCTAssertTrue(manager.events(containing: june15).contains { $0.id == event.id })
        XCTAssertFalse(manager.events(containing: june5).contains { $0.id == event.id })
        XCTAssertFalse(manager.events(containing: june25).contains { $0.id == event.id })
        
        // Clean up
        manager.deleteEvent(id: event.id)
    }
}
