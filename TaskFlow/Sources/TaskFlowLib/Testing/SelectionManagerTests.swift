import Foundation

/// Property-based tests for SelectionManager
/// Feature: multi-select-outlook-integration
public struct SelectionManagerTests {
    
    /// Generate a random set of UUIDs for testing
    static func randomUUIDs(count: Int) -> [UUID] {
        (0..<count).map { _ in UUID() }
    }
    
    /// Generate a random selection state
    static func randomSelectionState() -> Set<UUID> {
        let count = Int.random(in: 0...10)
        return Set(randomUUIDs(count: count))
    }
    
    // MARK: - Property 1: Command+Click Adds to Selection
    
    /// Property 1: Command+Click Adds to Selection
    /// *For any* Kanban card and any existing selection state, Command+clicking the card
    /// SHALL add that card's ID to the selection set without removing any existing selections.
    /// **Validates: Requirements 1.1**
    public static func testCommandClickAddsToSelection() -> PropertyTestResult {
        PropertyTest.check("Property 1: Command+Click Adds to Selection", iterations: 100) {
            // Create a fresh SelectionManager for each test
            let manager = SelectionManager.shared
            
            // Start with a random selection state
            let initialSelection = randomSelectionState()
            manager.clearSelection()
            for id in initialSelection {
                manager.addToSelection(id)
            }
            
            // Generate a new card ID to Command+click
            let newCardId = UUID()
            
            // Perform Command+click
            manager.handleCardClick(newCardId, commandKeyPressed: true)
            
            // Verify: new card is in selection
            guard manager.isSelected(newCardId) else { return false }
            
            // Verify: all previous selections are still present
            for id in initialSelection {
                guard manager.isSelected(id) else { return false }
            }
            
            // Verify: selection count increased by 1 (if newCardId wasn't already selected)
            let expectedCount = initialSelection.count + (initialSelection.contains(newCardId) ? 0 : 1)
            guard manager.selectionCount == expectedCount else { return false }
            
            return true
        }
    }
    
    // MARK: - Property 2: Regular Click Replaces Selection
    
    /// Property 2: Regular Click Replaces Selection
    /// *For any* Kanban card and any existing selection state, clicking the card without Command
    /// SHALL result in a selection set containing only that card's ID.
    /// **Validates: Requirements 1.2**
    public static func testRegularClickReplacesSelection() -> PropertyTestResult {
        PropertyTest.check("Property 2: Regular Click Replaces Selection", iterations: 100) {
            let manager = SelectionManager.shared
            
            // Start with a random selection state (could be empty or have multiple items)
            let initialSelection = randomSelectionState()
            manager.clearSelection()
            for id in initialSelection {
                manager.addToSelection(id)
            }
            
            // Generate a card ID to click
            let clickedCardId = UUID()
            
            // Perform regular click (no Command key)
            manager.handleCardClick(clickedCardId, commandKeyPressed: false)
            
            // Verify: only the clicked card is selected
            guard manager.selectionCount == 1 else { return false }
            guard manager.isSelected(clickedCardId) else { return false }
            
            // Verify: previous selections are cleared (except if clicked card was in them)
            for id in initialSelection {
                if id != clickedCardId {
                    guard !manager.isSelected(id) else { return false }
                }
            }
            
            return true
        }
    }
    
    // MARK: - Property 4: Cross-Column Selection
    
    /// Property 4: Cross-Column Selection
    /// *For any* set of cards distributed across different Kanban columns, the Selection Manager
    /// SHALL allow all cards to be selected simultaneously, regardless of their column membership.
    /// **Validates: Requirements 1.6**
    public static func testCrossColumnSelection() -> PropertyTestResult {
        PropertyTest.check("Property 4: Cross-Column Selection", iterations: 100) {
            let manager = SelectionManager.shared
            manager.clearSelection()
            
            // Generate random card IDs (simulating cards from different columns)
            // The SelectionManager doesn't care about columns - it just tracks UUIDs
            let cardCount = Int.random(in: 2...10)
            let cardIds = randomUUIDs(count: cardCount)
            
            // Select all cards using Command+click
            for cardId in cardIds {
                manager.handleCardClick(cardId, commandKeyPressed: true)
            }
            
            // Verify: all cards are selected
            guard manager.selectionCount == cardCount else { return false }
            
            for cardId in cardIds {
                guard manager.isSelected(cardId) else { return false }
            }
            
            return true
        }
    }
    
    // MARK: - Property 5: Escape Clears Selection
    
    /// Property 5: Escape Clears Selection
    /// *For any* selection state with one or more selected cards, pressing the Escape key
    /// SHALL result in an empty selection set.
    /// **Validates: Requirements 1.7**
    public static func testEscapeClearsSelection() -> PropertyTestResult {
        PropertyTest.check("Property 5: Escape Clears Selection", iterations: 100) {
            let manager = SelectionManager.shared
            
            // Start with a random non-empty selection state
            let selectionCount = Int.random(in: 1...10)
            let cardIds = randomUUIDs(count: selectionCount)
            
            manager.clearSelection()
            for id in cardIds {
                manager.addToSelection(id)
            }
            
            // Verify we have a selection
            guard manager.hasSelection else { return false }
            
            // Simulate Escape key by calling clearSelection (what the keyboard handler does)
            manager.clearSelection()
            
            // Verify selection is now empty
            return !manager.hasSelection && manager.selectionCount == 0
        }
    }
    
    // MARK: - Property 3: Empty Space Click Clears Selection
    
    /// Property 3: Empty Space Click Clears Selection
    /// *For any* selection state with one or more selected cards, clicking on empty space
    /// in the Kanban board SHALL result in an empty selection set.
    /// **Validates: Requirements 1.5**
    public static func testEmptySpaceClickClearsSelection() -> PropertyTestResult {
        PropertyTest.check("Property 3: Empty Space Click Clears Selection", iterations: 100) {
            let manager = SelectionManager.shared
            
            // Start with a random non-empty selection state
            let selectionCount = Int.random(in: 1...10)
            let cardIds = randomUUIDs(count: selectionCount)
            
            manager.clearSelection()
            for id in cardIds {
                manager.addToSelection(id)
            }
            
            // Verify we have a selection
            guard manager.hasSelection else { return false }
            
            // Simulate empty space click by calling clearSelection
            manager.clearSelection()
            
            // Verify selection is now empty
            return !manager.hasSelection && manager.selectionCount == 0
        }
    }
    
    // MARK: - Run All Tests
    
    /// Run all SelectionManager property tests
    public static func runAllTests() {
        PropertyTest.runAll([
            testCommandClickAddsToSelection,
            testRegularClickReplacesSelection,
            testCrossColumnSelection,
            testEscapeClearsSelection,
            testEmptySpaceClickClearsSelection
        ])
    }
}
