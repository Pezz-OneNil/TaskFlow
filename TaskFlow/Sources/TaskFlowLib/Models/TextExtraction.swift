import Foundation

/// Result of text extraction from screen capture
public struct TextExtraction: Equatable {
    public let rawText: String
    public let sender: String?
    public let recipient: String?
    public let subject: String?
    public let bodyContent: String
    public let detectedApp: String?
    public let keywords: [String]
    
    public init(
        rawText: String,
        sender: String? = nil,
        recipient: String? = nil,
        subject: String? = nil,
        bodyContent: String = "",
        detectedApp: String? = nil,
        keywords: [String] = []
    ) {
        self.rawText = rawText
        self.sender = sender
        self.recipient = recipient
        self.subject = subject
        self.bodyContent = bodyContent.isEmpty ? rawText : bodyContent
        self.detectedApp = detectedApp
        self.keywords = keywords
    }
    
    /// Creates TaskMetadata from this extraction
    public func toMetadata() -> TaskMetadata {
        TaskMetadata(
            sender: sender,
            recipient: recipient,
            subject: subject,
            sourceApp: detectedApp,
            capturedAt: Date(),
            keywords: keywords
        )
    }
    
    /// Returns true if extraction has meaningful content
    public var hasContent: Bool {
        !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
