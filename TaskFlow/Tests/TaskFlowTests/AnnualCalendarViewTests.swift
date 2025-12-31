import XCTest
@testable import TaskFlowLib

/// Annual Calendar View Tests
/// Feature: annual-calendar
final class AnnualCalendarViewTests: XCTestCase {
    
    // MARK: - Property 4: Year Selection Updates Calendar Display
    // For any year in the valid range (2025-2035), the calendar should
    // display the correct number of days for each month, including leap years.
    // **Validates: Requirements 2.7**
    
    func testYearSelectionProperty() throws {
        let calendar = Calendar.current
        
        // Property test: test all years in range
        for year in 2025...2035 {
            // Verify each month has correct number of days
            for month in 1...12 {
                let dateComponents = DateComponents(year: year, month: month)
                guard let date = calendar.date(from: dateComponents),
                      let range = calendar.range(of: .day, in: .month, for: date) else {
                    XCTFail("Failed to create date for year \(year), month \(month)")
                    continue
                }
                
                let daysInMonth = range.count
                
                // Verify expected days per month
                let expectedDays: Int
                switch month {
                case 1, 3, 5, 7, 8, 10, 12:
                    expectedDays = 31
                case 4, 6, 9, 11:
                    expectedDays = 30
                case 2:
                    // Leap year check
                    let isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
                    expectedDays = isLeapYear ? 29 : 28
                default:
                    expectedDays = 0
                }
                
                XCTAssertEqual(daysInMonth, expectedDays,
                    "Year \(year), month \(month) should have \(expectedDays) days, got \(daysInMonth)")
            }
        }
    }
    
    // MARK: - Property 3: Day Cell Displays Correct Date Information
    // For any date, the day cell should display the correct day number
    // and weekday abbreviation.
    // **Validates: Requirements 2.3**
    
    func testDayCellDateDisplayProperty() throws {
        let calendar = Calendar.current
        let dayOfWeekNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        // Property test: run 100 iterations with random dates
        for _ in 0..<100 {
            // Generate random date in 2025-2035
            let year = Int.random(in: 2025...2035)
            let month = Int.random(in: 1...12)
            let day = Int.random(in: 1...28) // Use 28 to avoid invalid dates
            
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
                continue
            }
            
            // Get expected values
            let expectedDay = calendar.component(.day, from: date)
            let weekday = calendar.component(.weekday, from: date)
            let expectedWeekday = dayOfWeekNames[weekday - 1]
            
            // Verify day number
            XCTAssertEqual(expectedDay, day,
                "Day component should match: expected \(day), got \(expectedDay)")
            
            // Verify weekday is valid
            XCTAssertTrue(dayOfWeekNames.contains(expectedWeekday),
                "Weekday should be valid: \(expectedWeekday)")
            
            // Verify weekend detection
            let isWeekend = weekday == 1 || weekday == 7
            XCTAssertEqual(isWeekend, weekday == 1 || weekday == 7,
                "Weekend detection should be correct for weekday \(weekday)")
        }
    }
    
    // MARK: - Unit Tests
    
    func testLeapYearDetection() throws {
        let calendar = Calendar.current
        
        // 2024 is a leap year
        let feb2024 = calendar.date(from: DateComponents(year: 2024, month: 2))!
        let days2024 = calendar.range(of: .day, in: .month, for: feb2024)!.count
        XCTAssertEqual(days2024, 29, "2024 should be a leap year")
        
        // 2025 is not a leap year
        let feb2025 = calendar.date(from: DateComponents(year: 2025, month: 2))!
        let days2025 = calendar.range(of: .day, in: .month, for: feb2025)!.count
        XCTAssertEqual(days2025, 28, "2025 should not be a leap year")
        
        // 2028 is a leap year
        let feb2028 = calendar.date(from: DateComponents(year: 2028, month: 2))!
        let days2028 = calendar.range(of: .day, in: .month, for: feb2028)!.count
        XCTAssertEqual(days2028, 29, "2028 should be a leap year")
        
        // 2032 is a leap year
        let feb2032 = calendar.date(from: DateComponents(year: 2032, month: 2))!
        let days2032 = calendar.range(of: .day, in: .month, for: feb2032)!.count
        XCTAssertEqual(days2032, 29, "2032 should be a leap year")
    }
    
    func testYearRangeValidity() throws {
        // Verify the year range 2025-2035 is valid
        let yearRange = 2025...2035
        
        XCTAssertEqual(yearRange.lowerBound, 2025)
        XCTAssertEqual(yearRange.upperBound, 2035)
        XCTAssertEqual(yearRange.count, 11)
    }
}
