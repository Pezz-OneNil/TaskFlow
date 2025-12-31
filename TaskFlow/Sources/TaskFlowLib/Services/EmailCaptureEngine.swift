// ═══════════════════════════════════════════════════════════════════════════════
// TaskFlow - Intelligent Task Management for macOS
// © 2025 Pezz. All rights reserved.
// ═══════════════════════════════════════════════════════════════════════════════

import Foundation

/// Engine for processing captured emails and extracting structured data
/// Feature: multi-select-outlook-integration
/// Per Requirements 5.1, 5.2, 6.1
public final class EmailCaptureEngine {
    
    public static let shared = EmailCaptureEngine()
    
    private init() {}
    
    // MARK: - Email Processing
    
    /// Process an email capture and extract structured data
    /// - Parameter capture: The raw email capture from Outlook
    /// - Returns: Processed email with parsed thread and metadata
    public func processCapture(_ capture: EmailCapture) -> ProcessedEmail {
        // Parse email thread
        let messages = parseEmailThread(capture.body, sender: capture.sender, receivedDate: capture.receivedDate)
        
        // Extract metadata
        let metadata = EmailMetadata(
            sender: capture.sender,
            recipients: capture.recipients,
            subject: capture.subject,
            receivedDate: capture.receivedDate,
            messageCount: messages.count,
            hasAttachments: detectAttachments(capture.body),
            conversationId: capture.conversationId
        )
        
        return ProcessedEmail(
            originalCapture: capture,
            messages: messages,
            metadata: metadata
        )
    }
    
    // MARK: - Thread Parsing
    
    /// Parse email body into individual messages in the thread
    /// Per Requirement 6.1
    private func parseEmailThread(_ body: String, sender: String, receivedDate: Date) -> [EmailMessage] {
        var messages: [EmailMessage] = []
        
        // Common email thread delimiters
        let delimiters = [
            // "On [date], [sender] wrote:"
            "(?m)^On .+? wrote:$",
            // "From: [sender]" header
            "(?m)^From: .+$",
            // "-----Original Message-----"
            "(?m)^-{3,}\\s*Original Message\\s*-{3,}$",
            // "> " quoted text blocks
            "(?m)^>+\\s*"
        ]
        
        // Try to split by common patterns
        var remainingBody = body
        var currentMessageBody = ""
        var currentSender: String?
        var currentDate: Date?
        
        // First, try to identify "On ... wrote:" patterns
        let onWrotePattern = try? NSRegularExpression(
            pattern: "On (.+?) wrote:",
            options: [.caseInsensitive]
        )
        
        let lines = body.components(separatedBy: .newlines)
        var inQuotedSection = false
        var quotedLines: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Check for "On ... wrote:" pattern
            if let match = onWrotePattern?.firstMatch(
                in: trimmedLine,
                options: [],
                range: NSRange(trimmedLine.startIndex..., in: trimmedLine)
            ) {
                // Save current message if we have content
                if !currentMessageBody.isEmpty {
                    messages.append(EmailMessage(
                        sender: currentSender,
                        date: currentDate,
                        body: currentMessageBody.trimmingCharacters(in: .whitespacesAndNewlines)
                    ))
                }
                
                // Extract sender and date from the "On ... wrote:" line
                if let range = Range(match.range(at: 1), in: trimmedLine) {
                    let dateAndSender = String(trimmedLine[range])
                    (currentDate, currentSender) = parseDateAndSender(dateAndSender)
                }
                
                currentMessageBody = ""
                continue
            }
            
            // Check for quoted lines (starting with >)
            if trimmedLine.hasPrefix(">") {
                let unquotedLine = trimmedLine.replacingOccurrences(
                    of: "^>+\\s*",
                    with: "",
                    options: .regularExpression
                )
                quotedLines.append(unquotedLine)
                inQuotedSection = true
            } else {
                // If we were in a quoted section and now we're not, save it
                if inQuotedSection && !quotedLines.isEmpty {
                    messages.append(EmailMessage(
                        sender: nil,
                        date: nil,
                        body: quotedLines.joined(separator: "\n")
                    ))
                    quotedLines = []
                    inQuotedSection = false
                }
                
                currentMessageBody += line + "\n"
            }
        }
        
        // Add final message
        if !currentMessageBody.isEmpty {
            messages.insert(EmailMessage(
                sender: currentSender ?? sender,
                date: currentDate ?? receivedDate,
                body: currentMessageBody.trimmingCharacters(in: .whitespacesAndNewlines)
            ), at: 0)
        }
        
        // Add any remaining quoted content
        if !quotedLines.isEmpty {
            messages.append(EmailMessage(
                sender: nil,
                date: nil,
                body: quotedLines.joined(separator: "\n")
            ))
        }
        
        // If no messages were parsed, treat entire body as single message
        if messages.isEmpty {
            messages.append(EmailMessage(
                sender: sender,
                date: receivedDate,
                body: body
            ))
        }
        
        return messages
    }
    
    /// Parse date and sender from "On [date], [sender]" string
    private func parseDateAndSender(_ text: String) -> (Date?, String?) {
        // Try to find a comma separating date from sender
        let parts = text.components(separatedBy: ",")
        
        var dateString: String?
        var sender: String?
        
        if parts.count >= 2 {
            // Last part is usually the sender
            sender = parts.last?.trimmingCharacters(in: .whitespaces)
            // Everything before is the date
            dateString = parts.dropLast().joined(separator: ",").trimmingCharacters(in: .whitespaces)
        } else {
            // Try to extract email address as sender
            let emailPattern = try? NSRegularExpression(
                pattern: "<([^>]+)>",
                options: []
            )
            if let match = emailPattern?.firstMatch(
                in: text,
                options: [],
                range: NSRange(text.startIndex..., in: text)
            ), let range = Range(match.range(at: 1), in: text) {
                sender = String(text[range])
            }
        }
        
        // Try to parse date
        var date: Date?
        if let ds = dateString {
            let dateFormatter = DateFormatter()
            let formats = [
                "MMM d, yyyy 'at' h:mm a",
                "MMM d, yyyy, h:mm a",
                "MMMM d, yyyy 'at' h:mm a",
                "d MMM yyyy 'at' HH:mm",
                "yyyy-MM-dd HH:mm:ss"
            ]
            for format in formats {
                dateFormatter.dateFormat = format
                if let parsed = dateFormatter.date(from: ds) {
                    date = parsed
                    break
                }
            }
        }
        
        return (date, sender)
    }
    
    // MARK: - Attachment Detection
    
    /// Detect if email mentions attachments
    private func detectAttachments(_ body: String) -> Bool {
        let attachmentIndicators = [
            "attached",
            "attachment",
            "see attached",
            "please find attached",
            "enclosed",
            "[image:",
            "[cid:",
            "inline image"
        ]
        
        let lowercaseBody = body.lowercased()
        return attachmentIndicators.contains { lowercaseBody.contains($0) }
    }
    
    // MARK: - Content Extraction
    
    /// Extract the most relevant content for task creation
    /// - Parameter email: Processed email
    /// - Returns: Extracted content suitable for LLM summarization
    public func extractRelevantContent(_ email: ProcessedEmail) -> String {
        var content = "Subject: \(email.metadata.subject)\n"
        content += "From: \(email.metadata.sender)\n"
        
        if !email.metadata.recipients.isEmpty {
            content += "To: \(email.metadata.recipients.joined(separator: ", "))\n"
        }
        
        content += "\n--- Email Content ---\n"
        
        // Include messages, prioritizing most recent
        for (index, message) in email.messages.enumerated() {
            if index > 0 {
                content += "\n--- Previous Message ---\n"
            }
            
            if let sender = message.sender {
                content += "From: \(sender)\n"
            }
            
            content += message.body + "\n"
        }
        
        return content
    }
}

// MARK: - Data Models

/// A single message within an email thread
public struct EmailMessage: Equatable {
    public let sender: String?
    public let date: Date?
    public let body: String
    
    public init(sender: String?, date: Date?, body: String) {
        self.sender = sender
        self.date = date
        self.body = body
    }
}

/// Metadata extracted from an email
public struct EmailMetadata: Equatable {
    public let sender: String
    public let recipients: [String]
    public let subject: String
    public let receivedDate: Date
    public let messageCount: Int
    public let hasAttachments: Bool
    public let conversationId: String?
    
    public init(
        sender: String,
        recipients: [String],
        subject: String,
        receivedDate: Date,
        messageCount: Int,
        hasAttachments: Bool,
        conversationId: String?
    ) {
        self.sender = sender
        self.recipients = recipients
        self.subject = subject
        self.receivedDate = receivedDate
        self.messageCount = messageCount
        self.hasAttachments = hasAttachments
        self.conversationId = conversationId
    }
}

/// Fully processed email ready for task creation
public struct ProcessedEmail: Equatable {
    public let originalCapture: EmailCapture
    public let messages: [EmailMessage]
    public let metadata: EmailMetadata
    
    public init(
        originalCapture: EmailCapture,
        messages: [EmailMessage],
        metadata: EmailMetadata
    ) {
        self.originalCapture = originalCapture
        self.messages = messages
        self.metadata = metadata
    }
    
    /// Get the primary message body (most recent message)
    public var primaryBody: String {
        messages.first?.body ?? originalCapture.body
    }
    
    /// Get all message bodies concatenated
    public var fullContent: String {
        messages.map { $0.body }.joined(separator: "\n\n---\n\n")
    }
}

// MARK: - EmailCapture Extension

extension EmailCapture {
    /// Convenience property for accessing sender
    public var capture: EmailCapture { self }
}
