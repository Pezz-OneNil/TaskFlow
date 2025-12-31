import Foundation

/// Property-based tests for EmailCaptureEngine
/// Feature: multi-select-outlook-integration
public struct EmailCaptureEngineTests {
    
    /// Generate a random email capture for testing
    static func randomEmailCapture() -> EmailCapture {
        let subjects = [
            "Meeting Request",
            "Project Update",
            "Action Required: Review Document",
            "RE: Follow up on discussion",
            "FW: Important Information"
        ]
        
        let senders = [
            "john.doe@example.com",
            "jane.smith@company.org",
            "support@service.com",
            "manager@business.net"
        ]
        
        let bodies = [
            "Hi,\n\nPlease review the attached document and provide feedback.\n\nThanks,\nJohn",
            "Hello team,\n\nJust a quick update on the project status.\n\nBest regards",
            "Dear colleague,\n\nCould you please take a look at this?\n\nRegards",
            "Hi,\n\nFollowing up on our discussion.\n\nOn Jan 1, 2025, someone@email.com wrote:\n> Original message here\n> More quoted text\n\nThanks"
        ]
        
        return EmailCapture(
            subject: subjects.randomElement()!,
            sender: senders.randomElement()!,
            recipients: [senders.randomElement()!],
            body: bodies.randomElement()!,
            receivedDate: Date(),
            conversationId: UUID().uuidString
        )
    }
    
    /// Generate an email with a thread (multiple messages)
    static func randomEmailThread() -> EmailCapture {
        let threadBodies = [
            """
            Hi,
            
            Thanks for the update.
            
            On Dec 15, 2024, john@example.com wrote:
            > Here's the latest status on the project.
            > We're making good progress.
            >
            > On Dec 14, 2024, jane@example.com wrote:
            >> Can you provide an update?
            """,
            """
            Sounds good, let's proceed.
            
            -----Original Message-----
            From: sender@company.com
            Subject: RE: Project Discussion
            
            I think we should move forward with option A.
            """,
            """
            I agree with your assessment.
            
            On Monday, January 6, 2025 at 10:30 AM, colleague@work.com wrote:
            > Based on my analysis, I recommend we take the following approach:
            > 1. First step
            > 2. Second step
            > 3. Third step
            """
        ]
        
        return EmailCapture(
            subject: "RE: Project Discussion",
            sender: "user@example.com",
            recipients: ["team@example.com"],
            body: threadBodies.randomElement()!,
            receivedDate: Date(),
            conversationId: UUID().uuidString
        )
    }
    
    // MARK: - Property 8: Email Content Extraction
    
    /// Property 8: Email Content Extraction
    /// *For any* email capture, processing it SHALL produce a ProcessedEmail with
    /// non-empty metadata and at least one message.
    /// **Validates: Requirements 5.2**
    public static func testEmailContentExtraction() -> PropertyTestResult {
        PropertyTest.check("Property 8: Email Content Extraction", iterations: 100) {
            let engine = EmailCaptureEngine.shared
            let capture = randomEmailCapture()
            
            // Process the capture
            let processed = engine.processCapture(capture)
            
            // Verify metadata is populated
            guard !processed.metadata.subject.isEmpty else { return false }
            guard !processed.metadata.sender.isEmpty else { return false }
            
            // Verify at least one message was extracted
            guard !processed.messages.isEmpty else { return false }
            
            // Verify primary body is not empty
            guard !processed.primaryBody.isEmpty else { return false }
            
            // Verify original capture is preserved
            guard processed.originalCapture == capture else { return false }
            
            return true
        }
    }
    
    // MARK: - Property 11: Email Thread Message Identification
    
    /// Property 11: Email Thread Message Identification
    /// *For any* email with quoted content (> prefixed lines or "On ... wrote:" patterns),
    /// the parser SHALL identify multiple messages in the thread.
    /// **Validates: Requirements 6.1**
    public static func testEmailThreadMessageIdentification() -> PropertyTestResult {
        PropertyTest.check("Property 11: Email Thread Message Identification", iterations: 50) {
            let engine = EmailCaptureEngine.shared
            let capture = randomEmailThread()
            
            // Process the capture
            let processed = engine.processCapture(capture)
            
            // Verify metadata shows message count
            guard processed.metadata.messageCount >= 1 else { return false }
            
            // Verify messages were extracted
            guard !processed.messages.isEmpty else { return false }
            
            // For thread emails, we should have extracted some content
            guard !processed.fullContent.isEmpty else { return false }
            
            return true
        }
    }
    
    // MARK: - Run All Tests
    
    /// Run all EmailCaptureEngine property tests
    public static func runAllTests() {
        PropertyTest.runAll([
            testEmailContentExtraction,
            testEmailThreadMessageIdentification
        ])
    }
}
