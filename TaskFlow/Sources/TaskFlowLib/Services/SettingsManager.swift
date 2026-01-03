import Foundation

/// Manages app settings persistence
/// Per Requirements 2B - LLM model selection
public final class TFMSettingsManager: ObservableObject {
    
    public static let shared = TFMSettingsManager()
    
    private let defaults = UserDefaults.standard
    
    // Keys - prefixed with TFM_ for namespace isolation
    private enum Keys {
        static let selectedModel = "TFM_selectedOllamaModel"
        static let availableModels = "TFM_availableOllamaModels"
        static let savedAssignees = "TFM_savedAssigneeNames"
        static let outlookIntegrationEnabled = "TFM_outlookIntegrationEnabled"
        static let emailDropEnabled = "TFM_emailDropEnabled"
        static let emailAutoCreateTasks = "TFM_emailAutoCreateTasks"
        static let showAnnualCalendar = "TFM_showAnnualCalendar"
        
        // Legacy keys for migration
        static let legacySelectedModel = "selectedOllamaModel"
        static let legacyAvailableModels = "availableOllamaModels"
        static let legacySavedAssignees = "savedAssigneeNames"
        static let legacyOutlookIntegrationEnabled = "outlookIntegrationEnabled"
        static let legacyEmailDropEnabled = "emailDropEnabled"
        static let legacyEmailAutoCreateTasks = "emailAutoCreateTasks"
        static let legacyShowAnnualCalendar = "showAnnualCalendar"
    }
    
    /// Currently selected Ollama model
    @Published public var selectedModel: String? {
        didSet {
            if let model = selectedModel {
                defaults.set(model, forKey: Keys.selectedModel)
                print("TFMSettingsManager: Saved selected model: \(model)")
            } else {
                defaults.removeObject(forKey: Keys.selectedModel)
            }
        }
    }
    
    /// Cached list of available models
    @Published public var availableModels: [String] = []
    
    /// Whether Outlook integration is enabled (legacy, kept for compatibility)
    /// Feature: multi-select-outlook-integration
    @Published public var outlookIntegrationEnabled: Bool {
        didSet {
            defaults.set(outlookIntegrationEnabled, forKey: Keys.outlookIntegrationEnabled)
            print("TFMSettingsManager: Outlook integration \(outlookIntegrationEnabled ? "enabled" : "disabled")")
        }
    }
    
    /// Whether email drag-and-drop is enabled
    /// Feature: email-drag-drop
    /// Per Requirement 7.2
    @Published public var emailDropEnabled: Bool {
        didSet {
            defaults.set(emailDropEnabled, forKey: Keys.emailDropEnabled)
            print("TFMSettingsManager: Email drop \(emailDropEnabled ? "enabled" : "disabled")")
        }
    }
    
    /// Whether to auto-create tasks without showing creation dialog
    /// Feature: email-drag-drop
    /// Per Requirement 7.3
    @Published public var emailAutoCreateTasks: Bool {
        didSet {
            defaults.set(emailAutoCreateTasks, forKey: Keys.emailAutoCreateTasks)
            print("TFMSettingsManager: Email auto-create tasks \(emailAutoCreateTasks ? "enabled" : "disabled")")
        }
    }
    
    /// Whether to show the Annual Calendar tab
    /// Feature: annual-calendar
    /// Per Requirement 1.4
    @Published public var showAnnualCalendar: Bool {
        didSet {
            defaults.set(showAnnualCalendar, forKey: Keys.showAnnualCalendar)
            print("TFMSettingsManager: Annual Calendar \(showAnnualCalendar ? "enabled" : "disabled")")
        }
    }
    
    private init() {
        // Initialize all stored properties first with defaults
        outlookIntegrationEnabled = false
        emailDropEnabled = true
        emailAutoCreateTasks = false
        showAnnualCalendar = false
        
        // Migrate legacy keys if needed (now safe to call)
        migrateFromLegacyKeys()
        
        // Load Outlook integration setting
        outlookIntegrationEnabled = defaults.bool(forKey: Keys.outlookIntegrationEnabled)
        
        // Load email drop settings (default: enabled)
        // Use object(forKey:) to check if key exists, default to true for new installs
        if defaults.object(forKey: Keys.emailDropEnabled) != nil {
            emailDropEnabled = defaults.bool(forKey: Keys.emailDropEnabled)
        } else {
            emailDropEnabled = true
        }
        
        // Auto-create defaults to false (show dialog for review)
        emailAutoCreateTasks = defaults.bool(forKey: Keys.emailAutoCreateTasks)
        
        // Annual Calendar defaults to false (hidden initially)
        showAnnualCalendar = defaults.bool(forKey: Keys.showAnnualCalendar)
        
        // Load saved model
        selectedModel = defaults.string(forKey: Keys.selectedModel)
        print("TFMSettingsManager: Loaded selected model: \(selectedModel ?? "none")")
        print("TFMSettingsManager: Email drop enabled: \(emailDropEnabled)")
        print("TFMSettingsManager: Email auto-create: \(emailAutoCreateTasks)")
        print("TFMSettingsManager: Annual Calendar: \(showAnnualCalendar)")
    }
    
    /// Migrate settings from legacy (unprefixed) keys to TFM_ prefixed keys
    private func migrateFromLegacyKeys() {
        // Only migrate if new keys don't exist yet
        if defaults.object(forKey: Keys.selectedModel) == nil,
           let legacyValue = defaults.string(forKey: Keys.legacySelectedModel) {
            defaults.set(legacyValue, forKey: Keys.selectedModel)
            print("TFMSettingsManager: Migrated selectedModel from legacy key")
        }
        
        if defaults.object(forKey: Keys.outlookIntegrationEnabled) == nil,
           defaults.object(forKey: Keys.legacyOutlookIntegrationEnabled) != nil {
            defaults.set(defaults.bool(forKey: Keys.legacyOutlookIntegrationEnabled), forKey: Keys.outlookIntegrationEnabled)
            print("TFMSettingsManager: Migrated outlookIntegrationEnabled from legacy key")
        }
        
        if defaults.object(forKey: Keys.emailDropEnabled) == nil,
           defaults.object(forKey: Keys.legacyEmailDropEnabled) != nil {
            defaults.set(defaults.bool(forKey: Keys.legacyEmailDropEnabled), forKey: Keys.emailDropEnabled)
            print("TFMSettingsManager: Migrated emailDropEnabled from legacy key")
        }
        
        if defaults.object(forKey: Keys.emailAutoCreateTasks) == nil,
           defaults.object(forKey: Keys.legacyEmailAutoCreateTasks) != nil {
            defaults.set(defaults.bool(forKey: Keys.legacyEmailAutoCreateTasks), forKey: Keys.emailAutoCreateTasks)
            print("TFMSettingsManager: Migrated emailAutoCreateTasks from legacy key")
        }
        
        if defaults.object(forKey: Keys.showAnnualCalendar) == nil,
           defaults.object(forKey: Keys.legacyShowAnnualCalendar) != nil {
            defaults.set(defaults.bool(forKey: Keys.legacyShowAnnualCalendar), forKey: Keys.showAnnualCalendar)
            print("TFMSettingsManager: Migrated showAnnualCalendar from legacy key")
        }
    }
    
    /// Update available models list
    public func updateAvailableModels(_ models: [String]) {
        DispatchQueue.main.async {
            self.availableModels = models
            
            // If selected model is no longer available, clear it
            if let selected = self.selectedModel, !models.contains(selected) {
                print("TFMSettingsManager: Selected model \(selected) no longer available")
                self.selectedModel = nil
            }
        }
    }
    
    /// Get the model to use (selected or default)
    public func getActiveModel(defaultModel: String = "qwen3-vl:2b") -> String {
        return selectedModel ?? defaultModel
    }
}

// MARK: - Backward Compatibility

@available(*, deprecated, renamed: "TFMSettingsManager")
public typealias SettingsManager = TFMSettingsManager
