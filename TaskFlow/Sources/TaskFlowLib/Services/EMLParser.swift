// ═══════════════════════════════════════════════════════════════════════════════
// TaskFlow - Intelligent Task Management for macOS
// © 2025 Pezz. All rights reserved.
// ═══════════════════════════════════════════════════════════════════════════════

import Foundation

/// Represents a parsed email address
/// Per Requirements 2.2, 2.3
public struct TFMEmailAddress: Equatable, Codable {
    public let name: String?
    public let email: String
    
    public init(name: String?, email: String) {
        self.name = name
        self.email = email
    }
    
    public var displayString: String {
        if let name = name, !name.isEmpty {
            return "\(name) <\(email)>"
        }
        return email
    }
}

/// A single message within an email thread
public struct TFMEmailMessage: Equatable {
    public let sender: String?
    public let date: Date?
    public let body: String
    
    public init(sender: String?, date: Date?, body: String) {
        self.sender = sender
        self.date = date
        self.body = body
    }
}

/// Represents a fully parsed email
/// Per Requirements 2.1-2.8
public struct TFMParsedEmail {
    public let subject: String
    public let sender: TFMEmailAddress
    public let recipients: [TFMEmailAddress]
    public let ccRecipients: [TFMEmailAddress]
    public let date: Date
    public let body: String
    public let htmlBody: String?
    public let messages: [TFMEmailMessage]
    public let headers: [String: String]
    
    public init(
        subject: String,
        sender: TFMEmailAddress,
        recipients: [TFMEmailAddress],
        ccRecipients: [TFMEmailAddress],
        date: Date,
        body: String,
        htmlBody: String?,
        messages: [TFMEmailMessage],
        headers: [String: String]
    ) {
        self.subject = subject
        self.sender = sender
        self.recipients = recipients
        self.ccRecipients = ccRecipients
        self.date = date
        self.body = body
        self.htmlBody = htmlBody
        self.messages = messages
        self.headers = headers
    }
}

/// Errors that can occur during EML parsing
public enum TFMEMLParserError: Error, LocalizedError {
    case fileNotFound
    case fileNotReadable
    case invalidFormat
    case missingRequiredHeader(String)
    case encodingError
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "The email file was not found"
        case .fileNotReadable:
            return "The email file could not be read"
        case .invalidFormat:
            return "The file is not a valid email format"
        case .missingRequiredHeader(let header):
            return "Missing required header: \(header)"
        case .encodingError:
            return "Could not decode the email content"
        }
    }
}

/// Parses .eml files to extract email content
/// Per Requirements 2.1-2.8, 3.1-3.4
public class TFMEMLParser {
    
    public init() {}
    
    /// Parse an .eml file and extract all content
    /// Per Requirements 2.1-2.8
    public func parse(fileURL: URL) throws -> TFMParsedEmail {
        // Check file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw TFMEMLParserError.fileNotFound
        }
        
        // Read file content
        let content: String
        do {
            content = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            // Try other encodings
            if let data = FileManager.default.contents(atPath: fileURL.path),
               let decoded = String(data: data, encoding: .isoLatin1) {
                content = decoded
            } else {
                throw TFMEMLParserError.fileNotReadable
            }
        }
        
        return try parseContent(content)
    }
    
    /// Parse email content string
    public func parseContent(_ content: String) throws -> TFMParsedEmail {
        // Split headers and body
        let (headersSection, bodySection) = splitHeadersAndBody(content)
        
        // Parse headers
        let headers = parseHeaders(headersSection)
        
        // Extract required fields
        guard let fromHeader = headers["from"] ?? headers["From"] else {
            throw TFMEMLParserError.missingRequiredHeader("From")
        }
        
        let subject = headers["subject"] ?? headers["Subject"] ?? "(No Subject)"
        let sender = parseEmailAddress(fromHeader)
        
        // Parse recipients
        let toHeader = headers["to"] ?? headers["To"] ?? ""
        let recipients = parseEmailAddresses(toHeader)
        
        let ccHeader = headers["cc"] ?? headers["Cc"] ?? headers["CC"] ?? ""
        let ccRecipients = parseEmailAddresses(ccHeader)
        
        // Parse date
        let dateHeader = headers["date"] ?? headers["Date"] ?? ""
        let date = parseDate(dateHeader) ?? Date()
        
        // Parse body (handle MIME multipart)
        let contentType = headers["content-type"] ?? headers["Content-Type"] ?? "text/plain"
        let (plainBody, htmlBody) = parseBody(bodySection, contentType: contentType)
        
        // Detect thread messages
        let messages = parseThread(body: plainBody)
        
        return TFMParsedEmail(
            subject: subject,
            sender: sender,
            recipients: recipients,
            ccRecipients: ccRecipients,
            date: date,
            body: plainBody,
            htmlBody: htmlBody,
            messages: messages,
            headers: headers
        )
    }

    
    // MARK: - Header Parsing
    
    /// Split content into headers and body sections
    private func splitHeadersAndBody(_ content: String) -> (headers: String, body: String) {
        // Headers and body are separated by a blank line (CRLF CRLF or LF LF)
        if let range = content.range(of: "\r\n\r\n") {
            let headers = String(content[..<range.lowerBound])
            let body = String(content[range.upperBound...])
            return (headers, body)
        } else if let range = content.range(of: "\n\n") {
            let headers = String(content[..<range.lowerBound])
            let body = String(content[range.upperBound...])
            return (headers, body)
        }
        // No body found
        return (content, "")
    }
    
    /// Parse headers into a dictionary
    private func parseHeaders(_ headersSection: String) -> [String: String] {
        var headers: [String: String] = [:]
        var currentKey: String?
        var currentValue: String = ""
        
        let lines = headersSection.components(separatedBy: .newlines)
        
        for line in lines {
            // Check if this is a continuation line (starts with whitespace)
            if line.hasPrefix(" ") || line.hasPrefix("\t") {
                // Continuation of previous header
                currentValue += " " + line.trimmingCharacters(in: .whitespaces)
            } else if let colonIndex = line.firstIndex(of: ":") {
                // Save previous header
                if let key = currentKey {
                    headers[key.lowercased()] = currentValue.trimmingCharacters(in: .whitespaces)
                    headers[key] = currentValue.trimmingCharacters(in: .whitespaces)
                }
                
                // Start new header
                currentKey = String(line[..<colonIndex])
                currentValue = String(line[line.index(after: colonIndex)...])
            }
        }
        
        // Save last header
        if let key = currentKey {
            headers[key.lowercased()] = currentValue.trimmingCharacters(in: .whitespaces)
            headers[key] = currentValue.trimmingCharacters(in: .whitespaces)
        }
        
        return headers
    }
    
    /// Parse a single email address from a header value
    private func parseEmailAddress(_ value: String) -> TFMEmailAddress {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        
        // Format: "Name" <email@example.com> or Name <email@example.com>
        if let angleStart = trimmed.lastIndex(of: "<"),
           let angleEnd = trimmed.lastIndex(of: ">"),
           angleStart < angleEnd {
            let email = String(trimmed[trimmed.index(after: angleStart)..<angleEnd])
            var name = String(trimmed[..<angleStart]).trimmingCharacters(in: .whitespaces)
            // Remove quotes from name
            name = name.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            return TFMEmailAddress(name: name.isEmpty ? nil : name, email: email)
        }
        
        // Just an email address
        return TFMEmailAddress(name: nil, email: trimmed)
    }
    
    /// Parse multiple email addresses from a header value
    private func parseEmailAddresses(_ value: String) -> [TFMEmailAddress] {
        guard !value.isEmpty else { return [] }
        
        // Split by comma, but be careful of commas inside quoted strings
        var addresses: [TFMEmailAddress] = []
        var current = ""
        var inQuotes = false
        var inAngleBrackets = false
        
        for char in value {
            if char == "\"" {
                inQuotes.toggle()
                current.append(char)
            } else if char == "<" {
                inAngleBrackets = true
                current.append(char)
            } else if char == ">" {
                inAngleBrackets = false
                current.append(char)
            } else if char == "," && !inQuotes && !inAngleBrackets {
                let trimmed = current.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    addresses.append(parseEmailAddress(trimmed))
                }
                current = ""
            } else {
                current.append(char)
            }
        }
        
        // Don't forget the last address
        let trimmed = current.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            addresses.append(parseEmailAddress(trimmed))
        }
        
        return addresses
    }
    
    /// Parse date from various email date formats
    private func parseDate(_ dateString: String) -> Date? {
        let formatters: [DateFormatter] = [
            createFormatter("EEE, d MMM yyyy HH:mm:ss Z"),      // RFC 2822
            createFormatter("EEE, d MMM yyyy HH:mm:ss z"),
            createFormatter("d MMM yyyy HH:mm:ss Z"),
            createFormatter("yyyy-MM-dd'T'HH:mm:ssZ"),          // ISO 8601
            createFormatter("yyyy-MM-dd HH:mm:ss Z"),
        ]
        
        let trimmed = dateString.trimmingCharacters(in: .whitespaces)
        
        for formatter in formatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        
        return nil
    }
    
    private func createFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
    
    // MARK: - Body Parsing
    
    /// Parse body content, handling MIME multipart
    /// Per Requirements 2.5, 2.7
    private func parseBody(_ body: String, contentType: String) -> (plain: String, html: String?) {
        // Check if multipart
        if contentType.lowercased().contains("multipart") {
            return parseMultipartBody(body, contentType: contentType)
        }
        
        // Check content type
        if contentType.lowercased().contains("text/html") {
            let plain = htmlToPlainText(body)
            return (plain, body)
        }
        
        // Plain text or unknown - decode if needed
        let decoded = decodeBody(body, contentType: contentType)
        return (decoded, nil)
    }
    
    /// Parse multipart MIME body
    private func parseMultipartBody(_ body: String, contentType: String) -> (plain: String, html: String?) {
        // Extract boundary
        guard let boundary = extractBoundary(from: contentType) else {
            return (body, nil)
        }
        
        let delimiter = "--\(boundary)"
        let parts = body.components(separatedBy: delimiter)
        
        var plainText: String?
        var htmlText: String?
        
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed == "--" { continue }
            
            let (partHeaders, partBody) = splitHeadersAndBody(part)
            let headers = parseHeaders(partHeaders)
            let partContentType = headers["content-type"] ?? headers["Content-Type"] ?? "text/plain"
            
            if partContentType.lowercased().contains("text/plain") && plainText == nil {
                plainText = decodeBody(partBody, contentType: partContentType)
            } else if partContentType.lowercased().contains("text/html") && htmlText == nil {
                htmlText = decodeBody(partBody, contentType: partContentType)
            } else if partContentType.lowercased().contains("multipart") {
                // Nested multipart
                let (nestedPlain, nestedHtml) = parseMultipartBody(partBody, contentType: partContentType)
                if plainText == nil { plainText = nestedPlain }
                if htmlText == nil { htmlText = nestedHtml }
            }
        }
        
        // If we only have HTML, convert to plain text
        if plainText == nil, let html = htmlText {
            plainText = htmlToPlainText(html)
        }
        
        return (plainText ?? "", htmlText)
    }
    
    /// Extract boundary from Content-Type header
    private func extractBoundary(from contentType: String) -> String? {
        let pattern = "boundary\\s*=\\s*\"?([^\"\\s;]+)\"?"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(contentType.startIndex..., in: contentType)
        if let match = regex.firstMatch(in: contentType, options: [], range: range),
           let boundaryRange = Range(match.range(at: 1), in: contentType) {
            return String(contentType[boundaryRange])
        }
        
        return nil
    }
    
    /// Decode body content based on transfer encoding
    private func decodeBody(_ body: String, contentType: String) -> String {
        // Check for quoted-printable or base64 encoding
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Simple quoted-printable decoding
        if trimmed.contains("=\r\n") || trimmed.contains("=\n") {
            return decodeQuotedPrintable(trimmed)
        }
        
        return trimmed
    }
    
    /// Decode quoted-printable encoding
    private func decodeQuotedPrintable(_ text: String) -> String {
        var result = text
        
        // Remove soft line breaks
        result = result.replacingOccurrences(of: "=\r\n", with: "")
        result = result.replacingOccurrences(of: "=\n", with: "")
        
        // Decode hex sequences (=XX)
        let pattern = "=([0-9A-Fa-f]{2})"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return result
        }
        
        var decoded = result
        let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
        
        // Process matches in reverse order to preserve indices
        for match in matches.reversed() {
            if let hexRange = Range(match.range(at: 1), in: result),
               let fullRange = Range(match.range, in: result) {
                let hex = String(result[hexRange])
                if let byte = UInt8(hex, radix: 16) {
                    let char = String(UnicodeScalar(byte))
                    decoded.replaceSubrange(fullRange, with: char)
                }
            }
        }
        
        return decoded
    }

    
    // MARK: - HTML to Plain Text
    
    /// Convert HTML body to plain text
    /// Per Requirement 2.5
    public func htmlToPlainText(_ html: String) -> String {
        var text = html
        
        // Replace common block elements with newlines
        let blockTags = ["</p>", "</div>", "</tr>", "</li>", "<br>", "<br/>", "<br />"]
        for tag in blockTags {
            text = text.replacingOccurrences(of: tag, with: "\n", options: .caseInsensitive)
        }
        
        // Replace list items
        text = text.replacingOccurrences(of: "<li>", with: "• ", options: .caseInsensitive)
        
        // Remove all remaining HTML tags
        let tagPattern = "<[^>]+>"
        if let regex = try? NSRegularExpression(pattern: tagPattern) {
            let range = NSRange(text.startIndex..., in: text)
            text = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
        }
        
        // Decode HTML entities
        text = decodeHTMLEntities(text)
        
        // Clean up whitespace
        text = text.replacingOccurrences(of: "\r\n", with: "\n")
        text = text.replacingOccurrences(of: "\r", with: "\n")
        
        // Collapse multiple newlines
        while text.contains("\n\n\n") {
            text = text.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        
        // Collapse multiple spaces
        while text.contains("  ") {
            text = text.replacingOccurrences(of: "  ", with: " ")
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Decode common HTML entities
    private func decodeHTMLEntities(_ text: String) -> String {
        var result = text
        
        let entities: [(String, String)] = [
            ("&nbsp;", " "),
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&apos;", "'"),
            ("&#39;", "'"),
            ("&ndash;", "–"),
            ("&mdash;", "—"),
            ("&hellip;", "…"),
            ("&copy;", "©"),
            ("&reg;", "®"),
            ("&trade;", "™"),
        ]
        
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Decode numeric entities (&#NNN; or &#xHHH;)
        let numericPattern = "&#(x?)([0-9A-Fa-f]+);"
        if let regex = try? NSRegularExpression(pattern: numericPattern) {
            let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
            
            for match in matches.reversed() {
                if let fullRange = Range(match.range, in: result),
                   let isHexRange = Range(match.range(at: 1), in: result),
                   let valueRange = Range(match.range(at: 2), in: result) {
                    let isHex = !result[isHexRange].isEmpty
                    let valueStr = String(result[valueRange])
                    
                    let codePoint: UInt32?
                    if isHex {
                        codePoint = UInt32(valueStr, radix: 16)
                    } else {
                        codePoint = UInt32(valueStr)
                    }
                    
                    if let cp = codePoint, let scalar = UnicodeScalar(cp) {
                        result.replaceSubrange(fullRange, with: String(Character(scalar)))
                    }
                }
            }
        }
        
        return result
    }
    
    // MARK: - Thread Detection
    
    /// Parse email body to detect thread/quoted content
    /// Per Requirements 3.1, 3.2, 3.3, 3.4
    public func parseThread(body: String) -> [TFMEmailMessage] {
        var messages: [TFMEmailMessage] = []
        let lines = body.components(separatedBy: .newlines)
        
        var currentContent: [String] = []
        var currentSender: String?
        var currentDate: Date?
        
        for line in lines {
            // Check for "On [date], [sender] wrote:" pattern
            if let (sender, date) = detectReplyHeader(line) {
                // Save previous message
                if !currentContent.isEmpty {
                    let content = currentContent.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    if !content.isEmpty {
                        messages.append(TFMEmailMessage(
                            sender: currentSender,
                            date: currentDate,
                            body: content
                        ))
                    }
                }
                
                // Start new quoted section
                currentContent = []
                currentSender = sender
                currentDate = date
                continue
            }
            
            // Check for forwarded email header
            if let (sender, date) = detectForwardHeader(line) {
                // Save previous message
                if !currentContent.isEmpty {
                    let content = currentContent.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    if !content.isEmpty {
                        messages.append(TFMEmailMessage(
                            sender: currentSender,
                            date: currentDate,
                            body: content
                        ))
                    }
                }
                
                currentContent = []
                currentSender = sender
                currentDate = date
                continue
            }
            
            // Check for quoted line prefix (>)
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.hasPrefix(">") {
                // Remove quote prefix and add to current content
                var unquoted = trimmedLine
                while unquoted.hasPrefix(">") {
                    unquoted = String(unquoted.dropFirst()).trimmingCharacters(in: .whitespaces)
                }
                currentContent.append(unquoted)
            } else {
                currentContent.append(line)
            }
        }
        
        // Save final message
        if !currentContent.isEmpty {
            let content = currentContent.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty {
                messages.append(TFMEmailMessage(
                    sender: currentSender,
                    date: currentDate,
                    body: content
                ))
            }
        }
        
        // If no thread structure detected, return single message
        if messages.isEmpty {
            return [TFMEmailMessage(sender: nil, date: nil, body: body)]
        }
        
        return messages
    }
    
    /// Detect "On [date], [sender] wrote:" pattern
    private func detectReplyHeader(_ line: String) -> (sender: String, date: Date?)? {
        // Common patterns:
        // "On Jan 1, 2025, at 10:00 AM, John Doe <john@example.com> wrote:"
        // "On 1/1/2025 10:00 AM, John Doe wrote:"
        // "On Mon, Jan 1, 2025 at 10:00 AM John Doe <john@example.com> wrote:"
        
        let patterns = [
            "^On .+, .+ wrote:$",
            "^On .+ at .+, .+ wrote:$",
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil {
                // Extract sender (text before "wrote:")
                if let wroteRange = line.range(of: " wrote:", options: .caseInsensitive) {
                    let beforeWrote = String(line[..<wroteRange.lowerBound])
                    // Find the last comma to get the sender
                    if let lastComma = beforeWrote.lastIndex(of: ",") {
                        let sender = String(beforeWrote[beforeWrote.index(after: lastComma)...])
                            .trimmingCharacters(in: .whitespaces)
                        return (sender, nil)
                    }
                }
                return ("Unknown", nil)
            }
        }
        
        return nil
    }
    
    /// Detect forwarded email header
    private func detectForwardHeader(_ line: String) -> (sender: String, date: Date?)? {
        // Pattern: "From: John Doe" or "From: john@example.com"
        // Usually followed by "Sent:" or "Date:"
        
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        if trimmed.lowercased().hasPrefix("from:") {
            let sender = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            if !sender.isEmpty {
                return (sender, nil)
            }
        }
        
        // Check for "---------- Forwarded message ---------"
        if trimmed.contains("Forwarded message") || trimmed.contains("Original Message") {
            return ("Forwarded", nil)
        }
        
        return nil
    }
}


// MARK: - Backward Compatibility

@available(*, deprecated, renamed: "TFMEmailAddress")
public typealias EmailAddress = TFMEmailAddress

// Note: EmailMessage typealias is defined in EmailCaptureEngine.swift
// TFMEmailMessage is the EMLParser version for parsed email threads

@available(*, deprecated, renamed: "TFMParsedEmail")
public typealias ParsedEmail = TFMParsedEmail

@available(*, deprecated, renamed: "TFMEMLParserError")
public typealias EMLParserError = TFMEMLParserError

@available(*, deprecated, renamed: "TFMEMLParser")
public typealias EMLParser = TFMEMLParser
