import XCTest
@testable import TaskFlowLib

/// Navigation Tab Tests
/// Feature: annual-calendar
final class NavigationTabTests: XCTestCase {
    
    // MARK: - Property 1: Settings Toggle Controls Tab Visibility
    // For any boolean value of showAnnual, visibleTabs(showAnnual:) should
    // include .annual if and only if showAnnual is true.
    // **Validates: Requirements 1.2, 1.3**
    
    func testTabVisibilityProperty() throws {
        // Property test: run 100 iterations
        for _ in 0..<100 {
            // Generate random boolean
            let showAnnual = Bool.random()
            
            // Get visible tabs
            let visibleTabs = NavigationTab.visibleTabs(showAnnual: showAnnual)
            
            // Verify .annual is included iff showAnnual is true
            let containsAnnual = visibleTabs.contains(.annual)
            XCTAssertEqual(containsAnnual, showAnnual,
                "Annual tab should be visible iff showAnnual is true: showAnnual=\(showAnnual), containsAnnual=\(containsAnnual)")
            
            // Verify other tabs are always present
            XCTAssertTrue(visibleTabs.contains(.tasks), "Tasks tab should always be visible")
            XCTAssertTrue(visibleTabs.contains(.pomodoro), "Pomodoro tab should always be visible")
            XCTAssertTrue(visibleTabs.contains(.kanban), "Kanban tab should always be visible")
            XCTAssertTrue(visibleTabs.contains(.settings), "Settings tab should always be visible")
        }
    }
    
    // MARK: - Unit Tests
    
    func testVisibleTabsWithAnnualEnabled() throws {
        let tabs = NavigationTab.visibleTabs(showAnnual: true)
        
        XCTAssertEqual(tabs.count, 5)
        XCTAssertTrue(tabs.contains(.tasks))
        XCTAssertTrue(tabs.contains(.pomodoro))
        XCTAssertTrue(tabs.contains(.kanban))
        XCTAssertTrue(tabs.contains(.annual))
        XCTAssertTrue(tabs.contains(.settings))
    }
    
    func testVisibleTabsWithAnnualDisabled() throws {
        let tabs = NavigationTab.visibleTabs(showAnnual: false)
        
        XCTAssertEqual(tabs.count, 4)
        XCTAssertTrue(tabs.contains(.tasks))
        XCTAssertTrue(tabs.contains(.pomodoro))
        XCTAssertTrue(tabs.contains(.kanban))
        XCTAssertFalse(tabs.contains(.annual))
        XCTAssertTrue(tabs.contains(.settings))
    }
    
    func testAnnualTabProperties() throws {
        XCTAssertEqual(NavigationTab.annual.rawValue, "Annual")
        XCTAssertEqual(NavigationTab.annual.icon, "calendar")
    }
}
