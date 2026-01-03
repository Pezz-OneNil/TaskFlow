import Foundation
import AppKit
import Vision

/// Protocol for text extraction from images
public protocol TFMTextExtractorProtocol {
    func extractText(from image: NSImage) async throws -> TFMTextExtraction
    func extractText(from cgImage: CGImage) async throws -> TFMTextExtraction
}

/// Errors that can occur during text extraction
public enum TFMTextExtractionError: Error, LocalizedError {
    case imageConversionFailed
    case ocrFailed(String)
    case noTextFound
    
    public var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image for text extraction."
        case .ocrFailed(let message):
            return "OCR failed: \(message)"
        case .noTextFound:
            return "No text found in the image."
        }
    }
}

/// Extracts text from images using Vision framework OCR
/// Parses extracted text to identify sender, recipient, subject patterns
/// Per Requirements 2.2, 2.3, 2.5
public final class TFMTextExtractor: TFMTextExtractorProtocol {
    
    public init() {}
    
    // MARK: - Text Extraction
    
    /// Extract text from NSImage
    /// Per Requirement 2.2
    public func extractText(from image: NSImage) async throws -> TFMTextExtraction {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw TFMTextExtractionError.imageConversionFailed
        }
        return try await extractText(from: cgImage)
    }
    
    /// Extract text from CGImage using Vision framework
    /// Per Requirement 2.2
    public func extractText(from cgImage: CGImage) async throws -> TFMTextExtraction {
        let rawText = try await performOCR(on: cgImage)
        
        if rawText.isEmpty {
            throw TFMTextExtractionError.noTextFound
        }
        
        // Parse the extracted text
        let sender = extractSender(from: rawText)
        let recipient = extractRecipient(from: rawText)
        let subject = extractSubject(from: rawText)
        let bodyContent = extractBodyContent(from: rawText)
        let detectedApp = detectSourceApp(from: rawText)
        let keywords = extractKeywords(from: rawText)
        
        return TFMTextExtraction(
            rawText: rawText,
            sender: sender,
            recipient: recipient,
            subject: subject,
            bodyContent: bodyContent,
            detectedApp: detectedApp,
            keywords: keywords
        )
    }
    
    // MARK: - OCR
    
    private func performOCR(on cgImage: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: TFMTextExtractionError.ocrFailed(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                // Combine all recognized text
                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: text)
            }
            
            // Configure for accurate recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: TFMTextExtractionError.ocrFailed(error.localizedDescription))
            }
        }
    }
    
    // MARK: - Text Parsing
    
    /// Extract sender from text (looks for From:, Sender:, etc.)
    private func extractSender(from text: String) -> String? {
        let patterns = [
            "From:\\s*(.+?)(?:\\n|$)",
            "Sender:\\s*(.+?)(?:\\n|$)",
            "Von:\\s*(.+?)(?:\\n|$)"
        ]
        
        for pattern in patterns {
            if let match = text.firstMatch(pattern: pattern) {
                return match.trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
    
    /// Extract recipient from text (looks for To:, Recipient:, etc.)
    private func extractRecipient(from text: String) -> String? {
        let patterns = [
            "To:\\s*(.+?)(?:\\n|$)",
            "Recipient:\\s*(.+?)(?:\\n|$)",
            "An:\\s*(.+?)(?:\\n|$)"
        ]
        
        for pattern in patterns {
            if let match = text.firstMatch(pattern: pattern) {
                return match.trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
    
    /// Extract subject from text (looks for Subject:, Re:, etc.)
    private func extractSubject(from text: String) -> String? {
        let patterns = [
            "Subject:\\s*(.+?)(?:\\n|$)",
            "Re:\\s*(.+?)(?:\\n|$)",
            "Betreff:\\s*(.+?)(?:\\n|$)"
        ]
        
        for pattern in patterns {
            if let match = text.firstMatch(pattern: pattern) {
                return match.trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
    
    /// Extract body content (text after headers)
    private func extractBodyContent(from text: String) -> String {
        // Remove common header lines
        let lines = text.components(separatedBy: "\n")
        var bodyStartIndex = 0
        
        for (index, line) in lines.enumerated() {
            let lowercased = line.lowercased()
            if lowercased.hasPrefix("from:") ||
               lowercased.hasPrefix("to:") ||
               lowercased.hasPrefix("subject:") ||
               lowercased.hasPrefix("date:") ||
               lowercased.hasPrefix("cc:") ||
               lowercased.hasPrefix("bcc:") {
                bodyStartIndex = index + 1
            }
        }
        
        if bodyStartIndex < lines.count {
            return lines[bodyStartIndex...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return text
    }
    
    /// Detect source application from text patterns
    private func detectSourceApp(from text: String) -> String? {
        let lowercased = text.lowercased()
        
        // Check for app-specific patterns
        if lowercased.contains("microsoft teams") || lowercased.contains("teams meeting") {
            return "Teams"
        }
        if lowercased.contains("slack") || lowercased.contains("#channel") {
            return "Slack"
        }
        if lowercased.contains("outlook") || lowercased.contains("microsoft outlook") {
            return "Outlook"
        }
        if lowercased.contains("calendar") || lowercased.contains("meeting invite") {
            return "Calendar"
        }
        if lowercased.contains("mail") || lowercased.contains("inbox") {
            return "Mail"
        }
        
        return nil
    }
    
    /// Extract keywords using frequency analysis
    /// Per Requirement 2.5
    private func extractKeywords(from text: String) -> [String] {
        // Common stop words to exclude
        let stopWords: Set<String> = [
            "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
            "of", "with", "by", "from", "as", "is", "was", "are", "were", "been",
            "be", "have", "has", "had", "do", "does", "did", "will", "would",
            "could", "should", "may", "might", "must", "shall", "can", "need",
            "this", "that", "these", "those", "i", "you", "he", "she", "it",
            "we", "they", "what", "which", "who", "whom", "when", "where", "why",
            "how", "all", "each", "every", "both", "few", "more", "most", "other",
            "some", "such", "no", "nor", "not", "only", "own", "same", "so",
            "than", "too", "very", "just", "also", "now", "here", "there"
        ]
        
        // Tokenize and clean
        let words = text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { word in
                word.count >= 3 &&
                !stopWords.contains(word) &&
                !word.allSatisfy { $0.isNumber }
            }
        
        // Count frequency
        var frequency: [String: Int] = [:]
        for word in words {
            frequency[word, default: 0] += 1
        }
        
        // Sort by frequency and take top keywords
        let sortedKeywords = frequency
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key }
        
        return Array(sortedKeywords)
    }
}

// MARK: - String Extension for Regex

extension String {
    func firstMatch(pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(self.startIndex..., in: self)
        guard let match = regex.firstMatch(in: self, options: [], range: range),
              match.numberOfRanges > 1,
              let captureRange = Range(match.range(at: 1), in: self) else {
            return nil
        }
        
        return String(self[captureRange])
    }
}


// MARK: - Backward Compatibility

@available(*, deprecated, renamed: "TFMTextExtractorProtocol")
public typealias TextExtractorProtocol = TFMTextExtractorProtocol

@available(*, deprecated, renamed: "TFMTextExtractionError")
public typealias TextExtractionError = TFMTextExtractionError

@available(*, deprecated, renamed: "TFMTextExtractor")
public typealias TextExtractor = TFMTextExtractor
