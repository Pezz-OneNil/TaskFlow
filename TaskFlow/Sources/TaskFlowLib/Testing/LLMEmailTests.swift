import Foundation

/// Property-based tests for LLM Email Summarization
/// Feature: multi-select-outlook-integration
public struct LLMEmailTests {
    
    /// Generate a random processed email for testing
    static func randomProcessedEmail() -> ProcessedEmail {
        let capture = EmailCaptureEngineTests.randomEmailCapture()
        return EmailCaptureEngine.shared.processCapture(capture)
    }
    
    /// Generate a long email thread for truncation testing
    static func longEmailThread() -> ProcessedEmail {
        // Create a very long email body
        var longBody = "Hi,\n\nThis is the most recent message.\n\n"
        
        // Add multiple quoted messages to simulate a long thread
        for i in 1...10 {
            longBody += "On Jan \(i), 2025, person\(i)@example.com wrote:\n"
            longBody += "> " + String(repeating: "This is message \(i) with lots of content. ", count: 20) + "\n"
            longBody += ">\n"
        }
        
        let capture = EmailCapture(
            subject: "RE: Long Discussion Thread",
            sender: "latest@example.com",
            recipients: ["team@example.com"],
            body: longBody,
            receivedDate: Date(),
            conversationId: UUID().uuidString
        )
        
        return EmailCaptureEngine.shared.processCapture(capture)
    }
    
    // MARK: - Property 9: LLM Email Output Generation
    
    /// Property 9: LLM Email Output Generation
    /// *For any* processed email, summarization SHALL produce a non-empty title
    /// (either LLM-generated or fallback to subject).
    /// **Validates: Requirements 5.3, 5.4**
    public static func testLLMEmailOutputGeneration() -> PropertyTestResult {
        PropertyTest.check("Property 9: LLM Email Output Generation", iterations: 20) {
            let email = randomProcessedEmail()
            let summarizer = LLMSummarizer()
            
            // Run async in sync context for testing
            let semaphore = DispatchSemaphore(value: 0)
            var result: LLMSummaryResult?
            
            _Concurrency.Task {
                result = await summarizer.summarizeEmailForTitle(email)
                semaphore.signal()
            }
            
            _ = semaphore.wait(timeout: .now() + 30)
            
            // Verify we got a result
            guard let titleResult = result else { return false }
            
            // Title should not be empty
            guard !titleResult.title.isEmpty else { return false }
            
            // If LLM wasn't available, should fall back to subject
            if !titleResult.wasGenerated {
                // Fallback should be the email subject
                guard titleResult.title == email.metadata.subject else { return false }
            }
            
            return true
        }
    }
    
    // MARK: - Property 12: Long Email Chain Truncation
    
    /// Property 12: Long Email Chain Truncation
    /// *For any* email thread exceeding the token limit, the LLM input SHALL be
    /// truncated to prioritize most recent messages.
    /// **Validates: Requirements 6.5**
    public static func testLongEmailChainTruncation() -> PropertyTestResult {
        PropertyTest.check("Property 12: Long Email Chain Truncation", iterations: 10) {
            let email = longEmailThread()
            let summarizer = LLMSummarizer()
            
            // Run async in sync context for testing
            let semaphore = DispatchSemaphore(value: 0)
            var description: String?
            
            _Concurrency.Task {
                description = await summarizer.summarizeEmailForDescription(email)
                semaphore.signal()
            }
            
            _ = semaphore.wait(timeout: .now() + 30)
            
            // Verify we got a description
            guard let desc = description else { return false }
            
            // Description should not be empty
            guard !desc.isEmpty else { return false }
            
            // Description should be reasonable length (not the full long email)
            // Even fallback descriptions should be truncated
            guard desc.count < 2000 else { return false }
            
            return true
        }
    }
    
    // MARK: - Run All Tests
    
    /// Run all LLM Email property tests
    public static func runAllTests() {
        PropertyTest.runAll([
            testLLMEmailOutputGeneration,
            testLongEmailChainTruncation
        ])
    }
}
