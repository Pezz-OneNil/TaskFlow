import Foundation

/// Manages assignee names with persistence and autocomplete
public final class TFMAssigneeManager: ObservableObject {
    
    public static let shared = TFMAssigneeManager()
    
    private let defaults = UserDefaults.standard
    private let key = "savedAssigneeNames"
    
    /// List of saved assignee names for autocomplete
    @Published public private(set) var savedAssignees: [String] = []
    
    private init() {
        loadAssignees()
    }
    
    /// Add a new assignee name (if not already saved)
    public func addAssignee(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if !savedAssignees.contains(where: { $0.lowercased() == trimmed.lowercased() }) {
            savedAssignees.append(trimmed)
            savedAssignees.sort()
            saveAssignees()
        }
    }
    
    /// Get autocomplete suggestions for a partial name
    public func suggestions(for query: String) -> [String] {
        guard !query.isEmpty else { return savedAssignees }
        let lowercased = query.lowercased()
        return savedAssignees.filter { $0.lowercased().contains(lowercased) }
    }
    
    /// Remove an assignee from saved list
    public func removeAssignee(_ name: String) {
        savedAssignees.removeAll { $0 == name }
        saveAssignees()
    }
    
    private func loadAssignees() {
        if let saved = defaults.stringArray(forKey: key) {
            savedAssignees = saved.sorted()
        }
    }
    
    private func saveAssignees() {
        defaults.set(savedAssignees, forKey: key)
    }
}

// MARK: - Backward Compatibility

@available(*, deprecated, renamed: "TFMAssigneeManager")
public typealias AssigneeManager = TFMAssigneeManager
