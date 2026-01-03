// ═══════════════════════════════════════════════════════════════════════════════
// TaskFlow - Intelligent Task Management for macOS
// © 2025 Pezz. All rights reserved.
// ═══════════════════════════════════════════════════════════════════════════════

import Foundation

/// Handles incoming URL scheme requests for TaskFlow
/// Feature: multi-select-outlook-integration
/// Per Requirements 4.4, 9.1, 9.2
public final class TFMURLSchemeHandler: ObservableObject {
    
    public static let shared = TFMURLSchemeHandler()
    
    /// URL scheme for TaskFlow
    public static let scheme = "taskflow"

    private static let maxEncodedDataLength = 1_500_000
    private static let maxDecodedDataLength = 1_000_000
    private static let maxSubjectLength = 500
    private static let maxBodyLength = 200_000
    private static let maxRecipientLength = 320
    private static let maxRecipients = 200
    
    /// Callback when email capture is received
    public var onEmailCaptureReceived: ((TFMEmailCapture) -> Void)?
    
    /// Published property to trigger UI updates when email is received
    @Published public var pendingEmailCapture: TFMEmailCapture?
    
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

        guard base64Data.count <= Self.maxEncodedDataLength else {
            print("URLSchemeHandler: data parameter too large")
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
            guard decodedData.count <= Self.maxDecodedDataLength else {
                print("URLSchemeHandler: decoded data too large")
                return false
            }
            return parseEmailData(decodedData)
        }
        
        guard decodedData.count <= Self.maxDecodedDataLength else {
            print("URLSchemeHandler: decoded data too large")
            return false
        }
        return parseEmailData(decodedData)
    }
    
    /// Parse email JSON data
    private func parseEmailData(_ data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let emailData = try decoder.decode(TFMEmailCaptureData.self, from: data)
            guard validateEmailData(emailData) else {
                print("URLSchemeHandler: Email data failed validation")
                return false
            }
            
            // Convert to TFMEmailCapture
            let capture = TFMEmailCapture(
                subject: emailData.subject,
                sender: emailData.sender,
                recipients: emailData.recipients,
                body: emailData.body,
                receivedDate: emailData.receivedDate ?? Date(),
                conversationId: emailData.conversationId
            )
            
            print("URLSchemeHandler: Received email capture")
            
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

    private func validateEmailData(_ data: TFMEmailCaptureData) -> Bool {
        let subject = data.subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let sender = data.sender.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !subject.isEmpty,
              !sender.isEmpty,
              !data.recipients.isEmpty else {
            return false
        }

        if subject.count > Self.maxSubjectLength {
            return false
        }

        if data.body.count > Self.maxBodyLength {
            return false
        }

        if data.recipients.count > Self.maxRecipients {
            return false
        }

        if data.recipients.contains(where: { recipient in
            recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || recipient.count > Self.maxRecipientLength
        }) {
            return false
        }

        return true
    }
}

// MARK: - Data Models

/// Raw email data from Outlook add-in
private struct TFMEmailCaptureData: Codable {
    let subject: String
    let sender: String
    let recipients: [String]
    let body: String
    let receivedDate: Date?
    let conversationId: String?
}

/// Processed email capture for task creation
/// Feature: multi-select-outlook-integration
public struct TFMEmailCapture: Identifiable, Equatable {
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

// MARK: - Backward Compatibility

@available(*, deprecated, renamed: "TFMEmailCapture")
public typealias EmailCapture = TFMEmailCapture

@available(*, deprecated, renamed: "TFMURLSchemeHandler")
public typealias URLSchemeHandler = TFMURLSchemeHandler
