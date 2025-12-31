// ═══════════════════════════════════════════════════════════════════════════════
// TaskFlow - Intelligent Task Management for macOS
// © 2025 Pezz. All rights reserved.
// ═══════════════════════════════════════════════════════════════════════════════

import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// State of the drop handler
/// Per Requirements 1.1, 1.2
public enum DropState: Equatable {
    case idle
    case hovering(isValid: Bool)
    case processing
    case error(String)
    
    public static func == (lhs: DropState, rhs: DropState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.hovering(let a), .hovering(let b)): return a == b
        case (.processing, .processing): return true
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

/// Result of processing a dropped email file
public struct EmailDropResult {
    public let fileURL: URL
    public let parsedEmail: ParsedEmail?
    public let suggestedTitle: String?
    public let suggestedDescription: String?
    public let error: Error?
    
    public var isSuccess: Bool { error == nil && parsedEmail != nil }
}

/// Handles drag and drop events for email files
/// Per Requirements 1.1-1.7
public class EmailDropHandler: ObservableObject {
    
    /// Current drop state for UI feedback
    @Published public var dropState: DropState = .idle
    
    /// Files currently being processed
    @Published public var processingQueue: [URL] = []
    
    /// Current processing progress (0.0 to 1.0)
    @Published public var progress: Double = 0.0
    
    /// Results from the last drop operation
    @Published public var lastResults: [EmailDropResult] = []
    
    /// Settings manager for checking if email drop is enabled
    private let settingsManager: SettingsManager
    
    /// EML parser instance
    private let emlParser: EMLParser
    
    /// LLM summarizer for generating task titles/descriptions
    private let llmSummarizer: LLMSummarizer?
    
    public init(
        settingsManager: SettingsManager = .shared,
        emlParser: EMLParser = EMLParser(),
        llmSummarizer: LLMSummarizer? = nil
    ) {
        self.settingsManager = settingsManager
        self.emlParser = emlParser
        self.llmSummarizer = llmSummarizer
    }
    
    /// Supported file types for drop
    public static let supportedTypes: [UTType] = [
        UTType(filenameExtension: "eml") ?? .data,
        .emailMessage
    ]
    
    /// Check if email drop is enabled in settings
    public var isEnabled: Bool {
        settingsManager.emailDropEnabled
    }
    
    // MARK: - Drop Validation
    
    /// Validate if dropped items are supported
    /// Per Requirement 1.4
    public func validateDrop(providers: [NSItemProvider]) -> Bool {
        guard isEnabled else { return false }
        
        for provider in providers {
            // Check for file URL
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                return true
            }
            // Check for .eml type
            if provider.hasItemConformingToTypeIdentifier("com.apple.mail.email") {
                return true
            }
        }
        
        return false
    }
    
    /// Update drop state when hovering
    public func updateHoverState(providers: [NSItemProvider]) {
        guard isEnabled else {
            dropState = .idle
            return
        }
        
        let isValid = validateDrop(providers: providers)
        dropState = .hovering(isValid: isValid)
    }
    
    /// Clear hover state when drag exits
    public func clearHoverState() {
        if case .hovering = dropState {
            dropState = .idle
        }
    }
    
    // MARK: - Drop Handling
    
    /// Handle dropped files
    /// Per Requirements 1.5, 1.6, 1.7
    public func handleDrop(providers: [NSItemProvider]) async -> Bool {
        guard isEnabled else { return false }
        
        await MainActor.run {
            dropState = .processing
            progress = 0.0
            lastResults = []
            processingQueue = []
        }
        
        // Extract file URLs from providers
        var fileURLs: [URL] = []
        
        for provider in providers {
            if let url = await extractFileURL(from: provider) {
                // Validate it's an .eml file
                if url.pathExtension.lowercased() == "eml" {
                    fileURLs.append(url)
                }
            }
        }
        
        guard !fileURLs.isEmpty else {
            await MainActor.run {
                dropState = .error("No valid .eml files found")
            }
            
            // Clear error after delay
            try? await _Concurrency.Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                dropState = .idle
            }
            return false
        }
        
        await MainActor.run {
            processingQueue = fileURLs
        }
        
        // Process files
        var results: [EmailDropResult] = []
        
        for (index, url) in fileURLs.enumerated() {
            let result = await processEMLFile(url)
            results.append(result)
            
            await MainActor.run {
                progress = Double(index + 1) / Double(fileURLs.count)
            }
        }
        
        await MainActor.run {
            lastResults = results
            processingQueue = []
            dropState = .idle
        }
        
        return results.contains { $0.isSuccess }
    }
    
    /// Extract file URL from NSItemProvider
    private func extractFileURL(from provider: NSItemProvider) async -> URL? {
        return await withCheckedContinuation { continuation in
            // Try to load as file URL
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        continuation.resume(returning: url)
                    } else if let url = item as? URL {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
    
    // MARK: - File Processing
    
    /// Process a single .eml file
    /// Per Requirements 2.1-2.8
    public func processEMLFile(_ url: URL) async -> EmailDropResult {
        do {
            // Parse the EML file
            let parsedEmail = try emlParser.parse(fileURL: url)
            
            // Generate summary using LLM if available
            var suggestedTitle: String? = nil
            var suggestedDescription: String? = nil
            
            if let summarizer = llmSummarizer {
                let summary = await summarizer.summarizeEmail(parsedEmail)
                suggestedTitle = summary.title
                suggestedDescription = summary.description
            } else {
                // Fallback: use subject as title, first paragraph as description
                suggestedTitle = parsedEmail.subject
                suggestedDescription = extractFirstParagraph(from: parsedEmail.body)
            }
            
            return EmailDropResult(
                fileURL: url,
                parsedEmail: parsedEmail,
                suggestedTitle: suggestedTitle,
                suggestedDescription: suggestedDescription,
                error: nil
            )
        } catch {
            print("EmailDropHandler: Failed to process \(url.lastPathComponent): \(error)")
            return EmailDropResult(
                fileURL: url,
                parsedEmail: nil,
                suggestedTitle: nil,
                suggestedDescription: nil,
                error: error
            )
        }
    }
    
    /// Extract first paragraph from email body for fallback description
    private func extractFirstParagraph(from body: String) -> String {
        let paragraphs = body.components(separatedBy: "\n\n")
        let firstParagraph = paragraphs.first ?? body
        
        // Limit length
        let maxLength = 200
        if firstParagraph.count > maxLength {
            let index = firstParagraph.index(firstParagraph.startIndex, offsetBy: maxLength)
            return String(firstParagraph[..<index]) + "..."
        }
        
        return firstParagraph
    }
}

// MARK: - Email Summarization Extension

extension LLMSummarizer {
    /// Summarize an email for task creation
    /// Per Requirements 4.1, 4.2
    public func summarizeEmail(_ email: ParsedEmail) async -> (title: String?, description: String?) {
        // Build a prompt from the email content
        let emailContent = """
        Subject: \(email.subject)
        From: \(email.sender.displayString)
        
        \(email.body.prefix(1000))
        """
        
        // Use existing summarization
        let result = await summarizeForTitle(text: emailContent)
        
        if result.wasGenerated {
            // Generate description from first paragraph
            let description = extractFirstParagraph(from: email.body)
            return (result.title, description)
        }
        
        // Fallback
        return (email.subject, extractFirstParagraph(from: email.body))
    }
    
    private func extractFirstParagraph(from body: String) -> String {
        let paragraphs = body.components(separatedBy: "\n\n")
        let firstParagraph = paragraphs.first ?? body
        
        let maxLength = 200
        if firstParagraph.count > maxLength {
            let index = firstParagraph.index(firstParagraph.startIndex, offsetBy: maxLength)
            return String(firstParagraph[..<index]) + "..."
        }
        
        return firstParagraph
    }
}
