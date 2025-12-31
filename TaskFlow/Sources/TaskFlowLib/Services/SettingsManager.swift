import Foundation

/// Manages app settings persistence
/// Per Requirements 2B - LLM model selection
public final class SettingsManager: ObservableObject {
    
    public static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    // Keys
    private enum Keys {
        static let selectedModel = "selectedOllamaModel"
        static let availableModels = "availableOllamaModels"
        static let savedAssignees = "savedAssigneeNames"
        static let outlookIntegrationEnabled = "outlookIntegrationEnabled"
        static let emailDropEnabled = "emailDropEnabled"
        static let emailAutoCreateTasks = "emailAutoCreateTasks"
        static let showAnnualCalendar = "showAnnualCalendar"
    }
    
    /// Currently selected Ollama model
    @Published public var selectedModel: String? {
        didSet {
            if let model = selectedModel {
                defaults.set(model, forKey: Keys.selectedModel)
                print("SettingsManager: Saved selected model: \(model)")
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
            print("SettingsManager: Outlook integration \(outlookIntegrationEnabled ? "enabled" : "disabled")")
        }
    }
    
    /// Whether email drag-and-drop is enabled
    /// Feature: email-drag-drop
    /// Per Requirement 7.2
    @Published public var emailDropEnabled: Bool {
        didSet {
            defaults.set(emailDropEnabled, forKey: Keys.emailDropEnabled)
            print("SettingsManager: Email drop \(emailDropEnabled ? "enabled" : "disabled")")
        }
    }
    
    /// Whether to auto-create tasks without showing creation dialog
    /// Feature: email-drag-drop
    /// Per Requirement 7.3
    @Published public var emailAutoCreateTasks: Bool {
        didSet {
            defaults.set(emailAutoCreateTasks, forKey: Keys.emailAutoCreateTasks)
            print("SettingsManager: Email auto-create tasks \(emailAutoCreateTasks ? "enabled" : "disabled")")
        }
    }
    
    /// Whether to show the Annual Calendar tab
    /// Feature: annual-calendar
    /// Per Requirement 1.4
    @Published public var showAnnualCalendar: Bool {
        didSet {
            defaults.set(showAnnualCalendar, forKey: Keys.showAnnualCalendar)
            print("SettingsManager: Annual Calendar \(showAnnualCalendar ? "enabled" : "disabled")")
        }
    }
    
    private init() {
        // Load Outlook integration setting (legacy)
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
        print("SettingsManager: Loaded selected model: \(selectedModel ?? "none")")
        print("SettingsManager: Email drop enabled: \(emailDropEnabled)")
        print("SettingsManager: Email auto-create: \(emailAutoCreateTasks)")
        print("SettingsManager: Annual Calendar: \(showAnnualCalendar)")
    }
    
    /// Update available models list
    public func updateAvailableModels(_ models: [String]) {
        DispatchQueue.main.async {
            self.availableModels = models
            
            // If selected model is no longer available, clear it
            if let selected = self.selectedModel, !models.contains(selected) {
                print("SettingsManager: Selected model \(selected) no longer available")
                self.selectedModel = nil
            }
        }
    }
    
    /// Get the model to use (selected or default)
    public func getActiveModel(defaultModel: String = "qwen3-vl:2b") -> String {
        return selectedModel ?? defaultModel
    }
}
