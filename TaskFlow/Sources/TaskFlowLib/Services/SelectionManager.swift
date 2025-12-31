import Foundation
import Combine

/// Manages multi-selection state for Kanban cards
/// Per Requirements 1.1-1.7, 2.1-2.6
public class SelectionManager: ObservableObject {
    
    /// Shared singleton instance
    public static let shared = SelectionManager()
    
    /// Currently selected task IDs
    @Published public private(set) var selectedTaskIds: Set<UUID> = []
    
    /// Whether any cards are selected
    public var hasSelection: Bool {
        !selectedTaskIds.isEmpty
    }
    
    /// Number of selected cards
    public var selectionCount: Int {
        selectedTaskIds.count
    }
    
    /// Private initializer for singleton
    private init() {}
    
    /// Add a task to selection (Command+click behavior)
    /// Per Requirement 1.1
    public func addToSelection(_ taskId: UUID) {
        selectedTaskIds.insert(taskId)
    }
    
    /// Remove a task from selection
    public func removeFromSelection(_ taskId: UUID) {
        selectedTaskIds.remove(taskId)
    }
    
    /// Toggle selection state of a task
    public func toggleSelection(_ taskId: UUID) {
        if selectedTaskIds.contains(taskId) {
            selectedTaskIds.remove(taskId)
        } else {
            selectedTaskIds.insert(taskId)
        }
    }
    
    /// Replace selection with single task (regular click behavior)
    /// Per Requirement 1.2
    public func selectOnly(_ taskId: UUID) {
        selectedTaskIds = [taskId]
    }
    
    /// Clear all selections
    /// Per Requirements 1.5, 1.7
    public func clearSelection() {
        selectedTaskIds.removeAll()
    }
    
    /// Check if a task is selected
    public func isSelected(_ taskId: UUID) -> Bool {
        selectedTaskIds.contains(taskId)
    }
    
    /// Handle click on a card with modifier keys
    /// Per Requirements 1.1, 1.2
    /// - Parameters:
    ///   - taskId: The ID of the clicked task
    ///   - commandKeyPressed: Whether the Command key was held during click
    public func handleCardClick(_ taskId: UUID, commandKeyPressed: Bool) {
        if commandKeyPressed {
            // Command+click: add to or remove from selection
            toggleSelection(taskId)
        } else {
            // Regular click: replace selection with this card
            selectOnly(taskId)
        }
    }
    
    /// Get all selected task IDs as an array (useful for iteration)
    public func getSelectedTaskIds() -> [UUID] {
        Array(selectedTaskIds)
    }
}
