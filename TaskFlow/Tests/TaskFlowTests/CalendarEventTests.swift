import XCTest
@testable import TaskFlowLib

/// Calendar Event Tests
/// Feature: annual-calendar
final class CalendarEventTests: XCTestCase {
    
    // MARK: - Property 7: Event Date Containment
    // For any calendar event with start date S and end date E, and any date D,
    // the event's contains(date:) method should return true iff S ≤ D ≤ E
    // **Validates: Requirements 4.3**
    
    func testContainsDateProperty() {
        // Property test: run 100 iterations with random dates
        let calendar = Calendar.current
        
        for _ in 0..<100 {
            // Generate random start date within 2025-2035
            let randomYear = Int.random(in: 2025...2035)
            let randomMonth = Int.random(in: 1...12)
            let randomDay = Int.random(in: 1...28) // Safe for all months
            
            guard let startDate = calendar.date(from: DateComponents(
                year: randomYear, month: randomMonth, day: randomDay
            )) else {
                continue
            }
            
            // Generate end date 0-30 days after start
            let daysToAdd = Int.random(in: 0...30)
            guard let endDate = calendar.date(byAdding: .day, value: daysToAdd, to: startDate) else {
                continue
            }
            
            let event = CalendarEvent(
                categoryId: 1,
                startDate: startDate,
                endDate: endDate,
                label: "Test Event"
            )
            
            // Test date before start (should be false)
            if let beforeStart = calendar.date(byAdding: .day, value: -1, to: startDate) {
                XCTAssertFalse(
                    event.contains(date: beforeStart),
                    "Date before start should not be contained"
                )
            }
            
            // Test start date (should be true)
            XCTAssertTrue(
                event.contains(date: startDate),
                "Start date should be contained"
            )
            
            // Test end date (should be true)
            XCTAssertTrue(
                event.contains(date: endDate),
                "End date should be contained"
            )
            
            // Test date after end (should be false)
            if let afterEnd = calendar.date(byAdding: .day, value: 1, to: endDate) {
                XCTAssertFalse(
                    event.contains(date: afterEnd),
                    "Date after end should not be contained"
                )
            }
            
            // Test random date in middle (if range > 1, so there's actually a middle)
            if daysToAdd > 1 {
                let middleOffset = Int.random(in: 1..<daysToAdd)
                if let middleDate = calendar.date(byAdding: .day, value: middleOffset, to: startDate) {
                    XCTAssertTrue(
                        event.contains(date: middleDate),
                        "Date in middle of range should be contained"
                    )
                }
            }
        }
    }
    
    // MARK: - Duration Days Tests
    
    func testDurationDaysSingleDay() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        
        let event = CalendarEvent(
            categoryId: 1,
            startDate: date,
            endDate: date,
            label: "Single Day"
        )
        
        XCTAssertEqual(event.durationDays, 1)
    }
    
    func testDurationDaysMultipleDays() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 6, day: 20))!
        
        let event = CalendarEvent(
            categoryId: 1,
            startDate: start,
            endDate: end,
            label: "Multi Day"
        )
        
        XCTAssertEqual(event.durationDays, 6) // 15, 16, 17, 18, 19, 20
    }
    
    func testDurationDaysAcrossMonths() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 6, day: 28))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 7, day: 3))!
        
        let event = CalendarEvent(
            categoryId: 1,
            startDate: start,
            endDate: end,
            label: "Cross Month"
        )
        
        XCTAssertEqual(event.durationDays, 6) // Jun 28, 29, 30, Jul 1, 2, 3
    }
    
    // MARK: - Year Overlap Tests
    
    func testOverlapsYearFullyContained() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        
        let event = CalendarEvent(
            categoryId: 1,
            startDate: start,
            endDate: end,
            label: "Test"
        )
        
        XCTAssertTrue(event.overlaps(year: 2026))
        XCTAssertFalse(event.overlaps(year: 2025))
        XCTAssertFalse(event.overlaps(year: 2027))
    }
    
    func testOverlapsYearSpanningYears() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2025, month: 12, day: 20))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 1, day: 10))!
        
        let event = CalendarEvent(
            categoryId: 1,
            startDate: start,
            endDate: end,
            label: "New Year"
        )
        
        XCTAssertTrue(event.overlaps(year: 2025))
        XCTAssertTrue(event.overlaps(year: 2026))
        XCTAssertFalse(event.overlaps(year: 2024))
        XCTAssertFalse(event.overlaps(year: 2027))
    }
    
    // MARK: - Edge Cases
    
    func testContainsDateWithDifferentTimeComponents() {
        let calendar = Calendar.current
        
        // Create event for June 15, 2026
        var startComponents = DateComponents(year: 2026, month: 6, day: 15)
        startComponents.hour = 9
        startComponents.minute = 0
        let startDate = calendar.date(from: startComponents)!
        
        var endComponents = DateComponents(year: 2026, month: 6, day: 15)
        endComponents.hour = 17
        endComponents.minute = 0
        let endDate = calendar.date(from: endComponents)!
        
        let event = CalendarEvent(
            categoryId: 1,
            startDate: startDate,
            endDate: endDate,
            label: "Same Day Different Times"
        )
        
        // Test with a date at midnight - should still be contained
        let midnightDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        XCTAssertTrue(event.contains(date: midnightDate))
        
        // Test with a date at 23:59 - should still be contained
        var lateComponents = DateComponents(year: 2026, month: 6, day: 15)
        lateComponents.hour = 23
        lateComponents.minute = 59
        let lateDate = calendar.date(from: lateComponents)!
        XCTAssertTrue(event.contains(date: lateDate))
    }
}
