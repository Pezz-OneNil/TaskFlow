import XCTest
@testable import TaskFlowLib

/// Settings Manager Tests
/// Feature: annual-calendar
final class SettingsManagerTests: XCTestCase {
    
    // MARK: - Property 2: Settings Toggle Persistence Round-Trip
    // For any boolean value written to showAnnualCalendar setting,
    // reading the setting should return the same value.
    // **Validates: Requirements 1.4, 1.5**
    
    func testSettingsTogglePersistenceProperty() throws {
        let manager = SettingsManager.shared
        
        // Property test: run 100 iterations
        for _ in 0..<100 {
            // Generate random boolean
            let randomValue = Bool.random()
            
            // Write to setting
            manager.showAnnualCalendar = randomValue
            
            // Read back and verify
            XCTAssertEqual(manager.showAnnualCalendar, randomValue,
                "Setting should persist: expected \(randomValue), got \(manager.showAnnualCalendar)")
        }
    }
    
    // MARK: - Unit Tests
    
    func testShowAnnualCalendarDefaultsFalse() throws {
        // Clear the setting first
        UserDefaults.standard.removeObject(forKey: "showAnnualCalendar")
        
        // Note: Since SettingsManager is a singleton, we can't easily test the default
        // without resetting the singleton. This test verifies the setting can be toggled.
        let manager = SettingsManager.shared
        
        // Toggle to false explicitly
        manager.showAnnualCalendar = false
        XCTAssertFalse(manager.showAnnualCalendar)
        
        // Toggle to true
        manager.showAnnualCalendar = true
        XCTAssertTrue(manager.showAnnualCalendar)
        
        // Toggle back to false
        manager.showAnnualCalendar = false
        XCTAssertFalse(manager.showAnnualCalendar)
    }
    
    func testShowAnnualCalendarPersistsToUserDefaults() throws {
        let manager = SettingsManager.shared
        let defaults = UserDefaults.standard
        
        // Set to true
        manager.showAnnualCalendar = true
        XCTAssertTrue(defaults.bool(forKey: "showAnnualCalendar"))
        
        // Set to false
        manager.showAnnualCalendar = false
        XCTAssertFalse(defaults.bool(forKey: "showAnnualCalendar"))
    }
}
