import Foundation
import SwiftUI

/// Manages event categories for the Annual Calendar
/// Per Requirements 3.1, 3.2, 3.3, 3.4, 3.5
public final class TFMEventCategoryManager: ObservableObject {
    
    /// Shared singleton instance
    public static let shared = TFMEventCategoryManager()
    
    /// All 10 categories with their current names
    @Published public private(set) var categories: [TFMEventCategory] = []
    
    private let defaults = UserDefaults.standard
    private let categoriesKey = "TFM_eventCategoryNames"
    
    private init() {
        migrateFromLegacyKeys()
        loadCategories()
    }
    
    /// Migrate from legacy UserDefaults keys
    private func migrateFromLegacyKeys() {
        let legacyKey = "eventCategoryNames"
        if let legacyData = defaults.dictionary(forKey: legacyKey) as? [String: String],
           defaults.dictionary(forKey: categoriesKey) == nil {
            defaults.set(legacyData, forKey: categoriesKey)
            defaults.removeObject(forKey: legacyKey)
        }
    }
    
    /// Load categories with persisted names or defaults
    /// Per Requirements 3.4, 3.5
    public func loadCategories() {
        let savedNames = defaults.dictionary(forKey: categoriesKey) as? [String: String] ?? [:]
        
        categories = TFMCategoryColor.allCases.map { color in
            let defaultName = "Category \(color.rawValue)"
            let name = savedNames[String(color.rawValue)] ?? defaultName
            return TFMEventCategory(id: color.rawValue, name: name, color: color)
        }
    }
    
    /// Update the name of a category
    /// Per Requirement 3.3
    public func updateCategoryName(id: Int, name: String) {
        guard let index = categories.firstIndex(where: { $0.id == id }) else { return }
        
        var updatedCategory = categories[index]
        updatedCategory.name = name
        categories[index] = updatedCategory
        
        saveCategoryNames()
    }
    
    /// Get a category by its ID
    public func category(for id: Int) -> TFMEventCategory? {
        categories.first { $0.id == id }
    }
    
    /// Get the color for a category ID
    public func color(for categoryId: Int) -> Color {
        category(for: categoryId)?.color.color ?? CyberpunkTheme.textSecondary
    }
    
    /// Get the text color for a category ID (for readability)
    public func textColor(for categoryId: Int) -> Color {
        category(for: categoryId)?.color.textColor ?? CyberpunkTheme.textPrimary
    }
    
    /// Reset all category names to defaults
    public func resetToDefaults() {
        defaults.removeObject(forKey: categoriesKey)
        loadCategories()
    }
    
    /// Save category names to UserDefaults
    private func saveCategoryNames() {
        var names: [String: String] = [:]
        for category in categories {
            names[String(category.id)] = category.name
        }
        defaults.set(names, forKey: categoriesKey)
    }
}

// MARK: - Backward Compatibility

@available(*, deprecated, renamed: "TFMEventCategoryManager")
public typealias EventCategoryManager = TFMEventCategoryManager
