import Foundation

/// Result of LLM summarization
public struct TFMLLMSummaryResult {
    public let title: String
    public let wasGenerated: Bool  // true if LLM generated, false if fallback
    
    public init(title: String, wasGenerated: Bool) {
        self.title = title
        self.wasGenerated = wasGenerated
    }
}

/// Protocol for LLM summarization operations
public protocol TFMLLMSummarizerProtocol {
    var isAvailable: Bool { get async }
    func summarizeForTitle(text: String) async -> TFMLLMSummaryResult
    func warmup() async
}

/// LLM-powered task title generation using local Ollama
/// Per Requirements 2B.1, 2B.2, 2B.3
public final class TFMLLMSummarizer: TFMLLMSummarizerProtocol {
    
    private let client: TFMOllamaClient
    private let settingsManager: TFMSettingsManager
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
    
    public init(client: TFMOllamaClient = TFMOllamaClient(), settingsManager: TFMSettingsManager = .shared) {
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
        print("TFMLLMSummarizer: Available models: \(availableModels)")
        
        guard let model = selectModel() else { return }
        
        print("TFMLLMSummarizer: Warming up model \(model)...")
        let success = await client.warmupModel(model)
        isWarmedUp = success
        print("TFMLLMSummarizer: Warmup \(success ? "complete" : "failed")")
    }
    
    /// Refresh the list of available models from Ollama
    public func refreshModels() async -> [String] {
        availableModels = await client.listModels()
        settingsManager.updateAvailableModels(availableModels)
        return availableModels
    }
    
    /// Summarize text into a task title
    /// Falls back to first line of text if Ollama unavailable
    public func summarizeForTitle(text: String) async -> TFMLLMSummaryResult {
        let startTime = Date()
        
        // Check availability
        guard await isAvailable else {
            print("TFMLLMSummarizer: Ollama not available, using fallback")
            return fallbackTitle(from: text)
        }
        
        // Get available models if not cached
        if availableModels.isEmpty {
            availableModels = await client.listModels()
            print("TFMLLMSummarizer: Available models: \(availableModels)")
        }
        
        // Find best available model
        guard let model = selectModel() else {
            print("TFMLLMSummarizer: No suitable model found, using fallback")
            return fallbackTitle(from: text)
        }
        
        print("TFMLLMSummarizer: Using model \(model)")
        
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
            print("TFMLLMSummarizer: Generated title in \(String(format: "%.2f", elapsed))s")
            
            if title.isEmpty {
                return fallbackTitle(from: text)
            }
            
            return TFMLLMSummaryResult(title: title, wasGenerated: true)
        } catch {
            print("TFMLLMSummarizer: Generation error - \(error)")
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
            print("TFMLLMSummarizer: Description generation error - \(error)")
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
    private func fallbackTitle(from text: String) -> TFMLLMSummaryResult {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var title = lines.first ?? "New Task"
        
        // Limit length
        if title.count > 60 {
            title = String(title.prefix(57)) + "..."
        }
        
        return TFMLLMSummaryResult(title: title, wasGenerated: false)
    }
    
    // MARK: - Email Summarization
    // Feature: multi-select-outlook-integration
    // Per Requirements 5.3, 5.4, 6.2, 6.3, 6.4
    
    /// Summarize email for task title
    /// Focuses on action items and key requests
    public func summarizeEmailForTitle(_ email: TFMProcessedEmail) async -> TFMLLMSummaryResult {
        let startTime = Date()
        
        // Check availability
        guard await isAvailable else {
            print("TFMLLMSummarizer: Ollama not available, using email subject as fallback")
            return TFMLLMSummaryResult(title: email.metadata.subject, wasGenerated: false)
        }
        
        // Get available models if not cached
        if availableModels.isEmpty {
            availableModels = await client.listModels()
        }
        
        guard let model = selectModel() else {
            return TFMLLMSummaryResult(title: email.metadata.subject, wasGenerated: false)
        }
        
        // Prepare email content with truncation for long threads
        let content = prepareEmailContentForLLM(email)
        
        let prompt = """
        Create a brief, action-oriented task title (5-8 words) from this email.
        Focus on what action the recipient needs to take.
        Start with an action verb (e.g., "Review", "Reply to", "Follow up on", "Schedule", "Complete").
        
        Email Subject: \(email.metadata.subject)
        From: \(email.metadata.sender)
        
        Email Content:
        \(content)
        
        Return ONLY the task title, nothing else.
        
        Title:
        """
        
        do {
            let response = try await client.generate(
                prompt: prompt,
                model: model,
                options: Self.fastOptions
            )
            let title = cleanTitle(response)
            
            let elapsed = Date().timeIntervalSince(startTime)
            print("TFMLLMSummarizer: Generated email title in \(String(format: "%.2f", elapsed))s")
            
            if title.isEmpty {
                return TFMLLMSummaryResult(title: email.metadata.subject, wasGenerated: false)
            }
            
            return TFMLLMSummaryResult(title: title, wasGenerated: true)
        } catch {
            print("TFMLLMSummarizer: Email title generation error - \(error)")
            return TFMLLMSummaryResult(title: email.metadata.subject, wasGenerated: false)
        }
    }
    
    /// Summarize email for task description
    /// Extracts key points and action items
    public func summarizeEmailForDescription(_ email: TFMProcessedEmail) async -> String {
        // Check availability
        guard await isAvailable else {
            return generateFallbackEmailDescription(email)
        }
        
        // Get available models if not cached
        if availableModels.isEmpty {
            availableModels = await client.listModels()
        }
        
        guard let model = selectModel() else {
            return generateFallbackEmailDescription(email)
        }
        
        // Prepare email content with truncation
        let content = prepareEmailContentForLLM(email)
        
        let prompt = """
        Summarize this email thread in 2-3 sentences, focusing on:
        1. The main topic or request
        2. Any action items or deadlines mentioned
        3. Key context the recipient needs
        
        Email Subject: \(email.metadata.subject)
        From: \(email.metadata.sender)
        Thread contains \(email.metadata.messageCount) message(s)
        
        Email Content:
        \(content)
        
        Return ONLY the summary, nothing else.
        
        Summary:
        """
        
        do {
            let response = try await client.generate(
                prompt: prompt,
                model: model,
                options: [
                    "num_predict": 150,
                    "temperature": 0.4,
                    "top_p": 0.9
                ]
            )
            
            let description = response
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "Summary:", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            return description.isEmpty ? generateFallbackEmailDescription(email) : description
        } catch {
            print("TFMLLMSummarizer: Email description generation error - \(error)")
            return generateFallbackEmailDescription(email)
        }
    }
    
    /// Prepare email content for LLM with truncation for long threads
    /// Per Requirement 6.5 - truncates oldest messages when exceeding limit
    private func prepareEmailContentForLLM(_ email: TFMProcessedEmail) -> String {
        let maxTokenEstimate = 1500  // Approximate token limit for context
        let avgCharsPerToken = 4
        let maxChars = maxTokenEstimate * avgCharsPerToken
        
        var content = ""
        var totalChars = 0
        var truncatedCount = 0
        
        // Process messages from most recent to oldest
        for (index, message) in email.messages.enumerated() {
            let messageContent: String
            if let sender = message.sender {
                messageContent = "From: \(sender)\n\(message.body)\n\n"
            } else {
                messageContent = message.body + "\n\n"
            }
            
            // Check if adding this message would exceed limit
            if totalChars + messageContent.count > maxChars && index > 0 {
                truncatedCount = email.messages.count - index
                break
            }
            
            content += messageContent
            totalChars += messageContent.count
        }
        
        // Add truncation indicator if needed
        if truncatedCount > 0 {
            content += "[... \(truncatedCount) older message(s) truncated for brevity ...]"
        }
        
        return content
    }
    
    /// Generate fallback description for email
    private func generateFallbackEmailDescription(_ email: TFMProcessedEmail) -> String {
        var description = "Email from \(email.metadata.sender)"
        
        if !email.metadata.recipients.isEmpty {
            description += " to \(email.metadata.recipients.joined(separator: ", "))"
        }
        
        description += ".\n\n"
        
        // Add first paragraph of primary message
        let primaryBody = email.primaryBody
        let firstParagraph = primaryBody.components(separatedBy: "\n\n").first ?? primaryBody
        
        if firstParagraph.count > 200 {
            description += String(firstParagraph.prefix(197)) + "..."
        } else {
            description += firstParagraph
        }
        
        return description
    }
}


// MARK: - Backward Compatibility

@available(*, deprecated, renamed: "TFMLLMSummaryResult")
public typealias LLMSummaryResult = TFMLLMSummaryResult

@available(*, deprecated, renamed: "TFMLLMSummarizerProtocol")
public typealias LLMSummarizerProtocol = TFMLLMSummarizerProtocol

@available(*, deprecated, renamed: "TFMLLMSummarizer")
public typealias LLMSummarizer = TFMLLMSummarizer
