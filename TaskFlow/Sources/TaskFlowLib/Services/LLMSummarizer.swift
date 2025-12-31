import Foundation

/// Result of LLM summarization
public struct LLMSummaryResult {
    public let title: String
    public let wasGenerated: Bool  // true if LLM generated, false if fallback
    
    public init(title: String, wasGenerated: Bool) {
        self.title = title
        self.wasGenerated = wasGenerated
    }
}

/// Protocol for LLM summarization operations
public protocol LLMSummarizerProtocol {
    var isAvailable: Bool { get async }
    func summarizeForTitle(text: String) async -> LLMSummaryResult
    func warmup() async
}

/// LLM-powered task title generation using local Ollama
/// Per Requirements 2B.1, 2B.2, 2B.3
public final class LLMSummarizer: LLMSummarizerProtocol {
    
    private let client: OllamaClient
    private let settingsManager: SettingsManager
    private var cachedAvailability: Bool?
    private var availableModels: [String] = []
    private var isWarmedUp = false
    
    /// Default model - gemma3:1b is fast and capable
    private static let defaultModel = "gemma3:1b"
    
    /// Fallback models to try in order of preference
    private static let fallbackModels = [
        "gemma3:1b",       // Primary: fast and capable
        "gemma3",          // Alternative gemma3 tag
        "gemma:2b",        // Older gemma if available
    ]
    
    /// Performance options for fast title generation
    private static let fastOptions: [String: Any] = [
        "num_predict": 50,      // Limit output tokens (titles are short)
        "temperature": 0.3,     // Lower temperature for more focused output
        "top_p": 0.9,           // Nucleus sampling
    ]
    
    public init(client: OllamaClient = OllamaClient(), settingsManager: SettingsManager = .shared) {
        self.client = client
        self.settingsManager = settingsManager
    }
    
    /// Check if Ollama is available
    public var isAvailable: Bool {
        get async {
            if let cached = cachedAvailability {
                return cached
            }
            let available = await client.checkConnection()
            cachedAvailability = available
            return available
        }
    }
    
    /// Pre-warm the model to reduce first-request latency
    /// Call this at app startup
    public func warmup() async {
        guard !isWarmedUp else { return }
        
        // Check availability and get models
        guard await isAvailable else { return }
        
        // Refresh available models list
        availableModels = await client.listModels()
        settingsManager.updateAvailableModels(availableModels)
        print("LLMSummarizer: Available models: \(availableModels)")
        
        guard let model = selectModel() else { return }
        
        print("LLMSummarizer: Warming up model \(model)...")
        let success = await client.warmupModel(model)
        isWarmedUp = success
        print("LLMSummarizer: Warmup \(success ? "complete" : "failed")")
    }
    
    /// Refresh the list of available models from Ollama
    public func refreshModels() async -> [String] {
        availableModels = await client.listModels()
        settingsManager.updateAvailableModels(availableModels)
        return availableModels
    }
    
    /// Summarize text into a task title
    /// Falls back to first line of text if Ollama unavailable
    public func summarizeForTitle(text: String) async -> LLMSummaryResult {
        let startTime = Date()
        
        // Check availability
        guard await isAvailable else {
            print("LLMSummarizer: Ollama not available, using fallback")
            return fallbackTitle(from: text)
        }
        
        // Get available models if not cached
        if availableModels.isEmpty {
            availableModels = await client.listModels()
            print("LLMSummarizer: Available models: \(availableModels)")
        }
        
        // Find best available model
        guard let model = selectModel() else {
            print("LLMSummarizer: No suitable model found, using fallback")
            return fallbackTitle(from: text)
        }
        
        print("LLMSummarizer: Using model \(model)")
        
        // Generate title using LLM with performance options
        let prompt = buildPrompt(for: text)
        
        do {
            let response = try await client.generate(
                prompt: prompt, 
                model: model,
                options: Self.fastOptions
            )
            let title = cleanTitle(response)
            
            let elapsed = Date().timeIntervalSince(startTime)
            print("LLMSummarizer: Generated title in \(String(format: "%.2f", elapsed))s")
            
            if title.isEmpty {
                return fallbackTitle(from: text)
            }
            
            return LLMSummaryResult(title: title, wasGenerated: true)
        } catch {
            print("LLMSummarizer: Generation error - \(error)")
            return fallbackTitle(from: text)
        }
    }
    
    /// Clear cached availability (for testing or reconnection)
    public func clearCache() {
        cachedAvailability = nil
        availableModels = []
        isWarmedUp = false
    }
    
    // MARK: - Private Helpers
    
    /// Select best available model
    private func selectModel() -> String? {
        // First check if user has selected a model
        if let userSelected = settingsManager.selectedModel,
           availableModels.contains(userSelected) {
            return userSelected
        }
        
        // Try fallback models in order
        for model in Self.fallbackModels {
            if let match = availableModels.first(where: { $0 == model || $0.hasPrefix(model + ":") || model.hasPrefix($0) }) {
                return match
            }
        }
        
        // Use first available model as last resort
        return availableModels.first
    }
    
    /// Build prompt for title generation (optimized for speed)
    /// Focuses on verbs and action words per Requirement 2B.1
    private func buildPrompt(for text: String) -> String {
        // Truncate to reduce processing time
        let maxLength = 500  // Reduced from 2000 for faster processing
        let truncatedText = text.count > maxLength 
            ? String(text.prefix(maxLength)) + "..." 
            : text
        
        // Prompt focused on action-oriented titles
        return """
        Create a brief, action-oriented task title (5-8 words) from this text.
        Focus on verbs and action words that describe what needs to be done.
        Start with an action verb when possible (e.g., "Review", "Complete", "Send", "Follow up", "Schedule").
        Return ONLY the title, nothing else.
        
        Text: \(truncatedText)
        
        Title:
        """
    }
    
    /// Generate a contextual description/summary from OCR text
    /// Per Requirement 19.2 - interprets context and suggests action
    public func generateDescription(from text: String) async -> String {
        // Check availability
        guard await isAvailable else {
            return generateFallbackDescription(from: text)
        }
        
        // Get available models if not cached
        if availableModels.isEmpty {
            availableModels = await client.listModels()
        }
        
        guard let model = selectModel() else {
            return generateFallbackDescription(from: text)
        }
        
        let maxLength = 800
        let truncatedText = text.count > maxLength 
            ? String(text.prefix(maxLength)) + "..." 
            : text
        
        let prompt = """
        Analyze this text and provide a brief 2-3 sentence summary that:
        1. Identifies the context (what this is about)
        2. Suggests what action the user might need to take
        
        Be concise and actionable. Return ONLY the summary.
        
        Text: \(truncatedText)
        
        Summary:
        """
        
        do {
            let response = try await client.generate(
                prompt: prompt,
                model: model,
                options: [
                    "num_predict": 100,
                    "temperature": 0.4,
                    "top_p": 0.9
                ]
            )
            
            let description = response
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "Summary:", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            return description.isEmpty ? generateFallbackDescription(from: text) : description
        } catch {
            print("LLMSummarizer: Description generation error - \(error)")
            return generateFallbackDescription(from: text)
        }
    }
    
    /// Generate fallback description from text
    private func generateFallbackDescription(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // Take first few meaningful lines as description
        let meaningfulLines = lines.prefix(3).joined(separator: " ")
        
        if meaningfulLines.count > 200 {
            return String(meaningfulLines.prefix(197)) + "..."
        }
        
        return meaningfulLines.isEmpty ? "Task captured from screenshot" : meaningfulLines
    }
    
    /// Clean up LLM response to extract title
    private func cleanTitle(_ response: String) -> String {
        var title = response
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "")
        
        // Remove common prefixes
        let prefixes = ["Task:", "Title:", "Task title:", "Here's", "Here is", "Sure,", "Sure!"]
        for prefix in prefixes {
            if title.lowercased().hasPrefix(prefix.lowercased()) {
                title = String(title.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Take only first line if multiple
        if let firstLine = title.components(separatedBy: .newlines).first {
            title = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Limit length
        if title.count > 80 {
            title = String(title.prefix(77)) + "..."
        }
        
        return title
    }
    
    /// Generate fallback title from text
    private func fallbackTitle(from text: String) -> LLMSummaryResult {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var title = lines.first ?? "New Task"
        
        // Limit length
        if title.count > 60 {
            title = String(title.prefix(57)) + "..."
        }
        
        return LLMSummaryResult(title: title, wasGenerated: false)
    }
}
