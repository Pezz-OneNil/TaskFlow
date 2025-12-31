import Foundation
import AppKit

/// Protocol for search term generation
public protocol SearchTermGeneratorProtocol {
    func generateSearchTerms(for task: Task) -> [String]
    func copyToClipboard(_ terms: [String]) -> Bool
}

/// Generates search terms from task metadata for quick lookup
/// Prioritizes rare keywords, sender/recipient, subject lines
/// Per Requirements 6.1, 6.2, 6.3, 6.4, 6.5
public final class SearchTermGenerator: SearchTermGeneratorProtocol {
    
    public init() {}
    
    // MARK: - Search Term Generation
    
    /// Generate search terms for a task
    /// Per Requirements 6.1, 6.2, 6.4
    public func generateSearchTerms(for task: Task) -> [String] {
        var terms: [String] = []
        
        // Priority 1: Subject line (most specific)
        if let subject = task.metadata.subject, !subject.isEmpty {
            terms.append(formatForSearch(subject))
        }
        
        // Priority 2: Sender/recipient names
        if let sender = task.metadata.sender, !sender.isEmpty {
            terms.append(formatForSearch(sender))
        }
        if let recipient = task.metadata.recipient, !recipient.isEmpty {
            terms.append(formatForSearch(recipient))
        }
        
        // Priority 3: Unique identifiers (ticket numbers, IDs)
        let identifiers = extractIdentifiers(from: task.sourceContent)
        terms.append(contentsOf: identifiers)
        
        // Priority 4: Rare keywords from metadata
        let rareKeywords = extractRareKeywords(from: task)
        terms.append(contentsOf: rareKeywords)
        
        // Priority 5: Title keywords
        let titleKeywords = extractTitleKeywords(from: task.title)
        terms.append(contentsOf: titleKeywords)
        
        // Remove duplicates while preserving order
        return removeDuplicates(from: terms)
    }
    
    // MARK: - Clipboard Integration
    
    /// Copy search terms to clipboard
    /// Per Requirements 6.3, 6.5
    public func copyToClipboard(_ terms: [String]) -> Bool {
        guard !terms.isEmpty else {
            return false
        }
        
        // Format terms with appropriate separators
        let formattedTerms = terms.joined(separator: " OR ")
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.setString(formattedTerms, forType: .string)
    }
    
    /// Copy a single search term to clipboard
    public func copySingleTerm(_ term: String) -> Bool {
        guard !term.isEmpty else {
            return false
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.setString(term, forType: .string)
    }
    
    // MARK: - Private Helpers
    
    /// Format a term for search (quote phrases, escape special chars)
    private func formatForSearch(_ term: String) -> String {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If contains spaces, wrap in quotes
        if trimmed.contains(" ") {
            let escaped = trimmed.replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escaped)\""
        }
        
        // Escape special characters
        let specialChars = CharacterSet(charactersIn: "()[]{}*?+^$|\\")
        var result = trimmed
        for scalar in trimmed.unicodeScalars {
            if specialChars.contains(scalar) {
                result = result.replacingOccurrences(of: String(scalar), with: "\\\(scalar)")
            }
        }
        
        return result
    }
    
    /// Extract unique identifiers (ticket numbers, IDs, etc.)
    private func extractIdentifiers(from text: String) -> [String] {
        var identifiers: [String] = []
        
        // Common patterns for identifiers
        let patterns = [
            // Ticket numbers: JIRA-123, ABC-1234
            "[A-Z]{2,10}-\\d{1,6}",
            // Issue numbers: #123, #1234
            "#\\d{3,6}",
            // Reference numbers: REF123456
            "REF\\d{4,10}",
            // Case numbers: CASE-123456
            "CASE-?\\d{4,10}",
            // Invoice numbers: INV-123456
            "INV-?\\d{4,10}"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                let matches = regex.matches(in: text, options: [], range: range)
                
                for match in matches {
                    if let matchRange = Range(match.range, in: text) {
                        identifiers.append(String(text[matchRange]))
                    }
                }
            }
        }
        
        return identifiers
    }
    
    /// Extract rare keywords from task metadata
    private func extractRareKeywords(from task: Task) -> [String] {
        // Use keywords from metadata if available
        let keywords = task.metadata.keywords
        
        // Filter to rare/specific keywords (longer words, proper nouns)
        return keywords.filter { keyword in
            // Keep keywords that are:
            // - At least 5 characters
            // - Or start with uppercase (proper nouns)
            keyword.count >= 5 || keyword.first?.isUppercase == true
        }.prefix(5).map { $0 }
    }
    
    /// Extract keywords from task title
    private func extractTitleKeywords(from title: String) -> [String] {
        let stopWords: Set<String> = [
            "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
            "of", "with", "by", "from", "as", "is", "was", "are", "were", "been",
            "be", "have", "has", "had", "do", "does", "did", "will", "would",
            "this", "that", "these", "those", "i", "you", "he", "she", "it",
            "we", "they", "what", "which", "who", "when", "where", "why", "how",
            "re", "fw", "fwd", "reply", "meeting", "call", "email", "message"
        ]
        
        let words = title
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { word in
                word.count >= 3 && !stopWords.contains(word)
            }
        
        return Array(words.prefix(3))
    }
    
    /// Remove duplicates while preserving order
    private func removeDuplicates(from terms: [String]) -> [String] {
        var seen = Set<String>()
        return terms.filter { term in
            let lowercased = term.lowercased()
            if seen.contains(lowercased) {
                return false
            }
            seen.insert(lowercased)
            return true
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Generate and copy search terms in one step
    public func generateAndCopy(for task: Task) -> Bool {
        let terms = generateSearchTerms(for: task)
        return copyToClipboard(terms)
    }
    
    /// Get formatted search string for display
    public func getFormattedSearchString(for task: Task) -> String {
        let terms = generateSearchTerms(for: task)
        return terms.joined(separator: " OR ")
    }
}
