// ═══════════════════════════════════════════════════════════════════════════════
// TaskFlow - Intelligent Task Management for macOS
// © 2025 Pezz. All rights reserved.
// ═══════════════════════════════════════════════════════════════════════════════

import Foundation

/// Handles incoming URL scheme requests for TaskFlow
/// Feature: multi-select-outlook-integration
/// Per Requirements 4.4, 9.1, 9.2
public final class URLSchemeHandler: ObservableObject {
    
    public static let shared = URLSchemeHandler()
    
    /// URL scheme for TaskFlow
    public static let scheme = "taskflow"
    
    /// Callback when email capture is received
    public var onEmailCaptureReceived: ((EmailCapture) -> Void)?
    
    /// Published property to trigger UI updates when email is received
    @Published public var pendingEmailCapture: EmailCapture?
    
    private init() {}
    
    // MARK: - URL Handling
    
    /// Handle an incoming URL
    /// - Parameter url: The URL to handle
    /// - Returns: True if the URL was handled successfully
    @discardableResult
    public func handleURL(_ url: URL) -> Bool {
        guard url.scheme == Self.scheme else {
            print("URLSchemeHandler: Unknown scheme: \(url.scheme ?? "nil")")
            return false
        }
        
        guard let host = url.host else {
            print("URLSchemeHandler: No host in URL")
            return false
        }
        
        switch host {
        case "capture-email":
            return handleCaptureEmail(url)
        default:
            print("URLSchemeHandler: Unknown action: \(host)")
            return false
        }
    }
    
    // MARK: - Email Capture
    
    /// Handle capture-email URL
    private func handleCaptureEmail(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let dataItem = queryItems.first(where: { $0.name == "data" }),
              let base64Data = dataItem.value else {
            print("URLSchemeHandler: Missing data parameter")
            return false
        }
        
        // Decode base64 data
        guard let decodedData = Data(base64Encoded: base64Data) else {
            // Try URL-decoded base64
            guard let urlDecoded = base64Data.removingPercentEncoding,
                  let decodedData = Data(base64Encoded: urlDecoded) else {
                print("URLSchemeHandler: Failed to decode base64 data")
                return false
            }
            return parseEmailData(decodedData)
        }
        
        return parseEmailData(decodedData)
    }
    
    /// Parse email JSON data
    private func parseEmailData(_ data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let emailData = try decoder.decode(EmailCaptureData.self, from: data)
            
            // Convert to EmailCapture
            let capture = EmailCapture(
                subject: emailData.subject,
                sender: emailData.sender,
                recipients: emailData.recipients,
                body: emailData.body,
                receivedDate: emailData.receivedDate ?? Date(),
                conversationId: emailData.conversationId
            )
            
            print("URLSchemeHandler: Received email capture - Subject: \(capture.subject)")
            
            // Notify listeners
            DispatchQueue.main.async {
                self.pendingEmailCapture = capture
                self.onEmailCaptureReceived?(capture)
            }
            
            return true
        } catch {
            print("URLSchemeHandler: Failed to parse email data: \(error)")
            return false
        }
    }
}

// MARK: - Data Models

/// Raw email data from Outlook add-in
private struct EmailCaptureData: Codable {
    let subject: String
    let sender: String
    let recipients: [String]
    let body: String
    let receivedDate: Date?
    let conversationId: String?
}

/// Processed email capture for task creation
/// Feature: multi-select-outlook-integration
public struct EmailCapture: Identifiable, Equatable {
    public let id = UUID()
    public let subject: String
    public let sender: String
    public let recipients: [String]
    public let body: String
    public let receivedDate: Date
    public let conversationId: String?
    
    public init(
        subject: String,
        sender: String,
        recipients: [String],
        body: String,
        receivedDate: Date,
        conversationId: String?
    ) {
        self.subject = subject
        self.sender = sender
        self.recipients = recipients
        self.body = body
        self.receivedDate = receivedDate
        self.conversationId = conversationId
    }
    
    /// Get a preview of the email body (first 200 characters)
    public var bodyPreview: String {
        if body.count <= 200 {
            return body
        }
        return String(body.prefix(200)) + "..."
    }
    
    /// Get formatted recipients string
    public var recipientsString: String {
        recipients.joined(separator: ", ")
    }
}
