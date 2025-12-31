import XCTest
@testable import TaskFlowLib

/// Event Category Manager Tests
/// Feature: annual-calendar
final class EventCategoryManagerTests: XCTestCase {
    
    // MARK: - Setup/Teardown
    
    override func setUp() {
        super.setUp()
        // Clear any persisted category names before each test
        UserDefaults.standard.removeObject(forKey: "eventCategoryNames")
    }
    
    override func tearDown() {
        // Clean up after tests
        UserDefaults.standard.removeObject(forKey: "eventCategoryNames")
        super.tearDown()
    }
    
    // MARK: - Property 5: Category Name Editing
    // For any category ID (1-10) and any non-empty string name,
    // updating the category name should result in the category having that name when retrieved.
    // **Validates: Requirements 3.3**
    
    func testCategoryNameEditingProperty() {
        let manager = EventCategoryManager.shared
        manager.resetToDefaults()
        
        // Property test: run 100 iterations with random category IDs and names
        for _ in 0..<100 {
            // Generate random category ID (1-10)
            let categoryId = Int.random(in: 1...10)
            
            // Generate random non-empty name
            let nameLength = Int.random(in: 1...50)
            let randomName = String((0..<nameLength).map { _ in
                "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_".randomElement()!
            })
            
            // Update the category name
            manager.updateCategoryName(id: categoryId, name: randomName)
            
            // Verify the name was updated
            let retrievedCategory = manager.category(for: categoryId)
            XCTAssertNotNil(retrievedCategory, "Category \(categoryId) should exist")
            XCTAssertEqual(
                retrievedCategory?.name,
                randomName,
                "Category name should match the updated name"
            )
        }
    }
    
    // MARK: - Property 6: Category Name Persistence Round-Trip
    // For any category ID and name, saving the category name and then reloading
    // categories should return the same name for that category.
    // **Validates: Requirements 3.4**
    
    func testCategoryNamePersistenceProperty() {
        // Property test: run 100 iterations
        for _ in 0..<100 {
            // Generate random category ID (1-10)
            let categoryId = Int.random(in: 1...10)
            
            // Generate random non-empty name
            let nameLength = Int.random(in: 1...30)
            let randomName = String((0..<nameLength).map { _ in
                "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()!
            })
            
            // Update the category name
            let manager = EventCategoryManager.shared
            manager.updateCategoryName(id: categoryId, name: randomName)
            
            // Simulate app restart by reloading categories
            manager.loadCategories()
            
            // Verify the name persisted
            let retrievedCategory = manager.category(for: categoryId)
            XCTAssertNotNil(retrievedCategory, "Category \(categoryId) should exist after reload")
            XCTAssertEqual(
                retrievedCategory?.name,
                randomName,
                "Category name should persist after reload"
            )
        }
    }
    
    // MARK: - Unit Tests
    
    func testExactly10CategoriesExist() {
        let manager = EventCategoryManager.shared
        manager.resetToDefaults()
        
        XCTAssertEqual(manager.categories.count, 10, "Should have exactly 10 categories")
    }
    
    func testDefaultCategoryNames() {
        let manager = EventCategoryManager.shared
        manager.resetToDefaults()
        
        for i in 1...10 {
            let category = manager.category(for: i)
            XCTAssertNotNil(category, "Category \(i) should exist")
            XCTAssertEqual(category?.name, "Category \(i)", "Default name should be 'Category \(i)'")
        }
    }
    
    func testCategoryColorsAreDistinct() {
        let manager = EventCategoryManager.shared
        manager.resetToDefaults()
        
        var colorRawValues = Set<Int>()
        for category in manager.categories {
            colorRawValues.insert(category.color.rawValue)
        }
        
        XCTAssertEqual(colorRawValues.count, 10, "All 10 categories should have distinct colors")
    }
    
    func testInvalidCategoryIdReturnsNil() {
        let manager = EventCategoryManager.shared
        
        XCTAssertNil(manager.category(for: 0), "Category 0 should not exist")
        XCTAssertNil(manager.category(for: 11), "Category 11 should not exist")
        XCTAssertNil(manager.category(for: -1), "Category -1 should not exist")
    }
    
    func testResetToDefaultsRestoresNames() {
        let manager = EventCategoryManager.shared
        
        // Change some names
        manager.updateCategoryName(id: 1, name: "Custom Name 1")
        manager.updateCategoryName(id: 5, name: "Custom Name 5")
        
        // Reset
        manager.resetToDefaults()
        
        // Verify defaults restored
        XCTAssertEqual(manager.category(for: 1)?.name, "Category 1")
        XCTAssertEqual(manager.category(for: 5)?.name, "Category 5")
    }
}
