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
    
    private init() {
        // Load saved model
        selectedModel = defaults.string(forKey: Keys.selectedModel)
        print("SettingsManager: Loaded selected model: \(selectedModel ?? "none")")
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
