// ═══════════════════════════════════════════════════════════════════════════════
// TaskFlow - Intelligent Task Management for macOS
// © 2025 Pezz. All rights reserved.
// ═══════════════════════════════════════════════════════════════════════════════

import Foundation
import Combine

/// Service for managing Outlook integration and email capture
/// Feature: multi-select-outlook-integration
/// Per Requirements 3.1, 3.3, 4.4, 5.1
public final class OutlookIntegrationService: ObservableObject {
    
    public static let shared = OutlookIntegrationService()
    
    // Dependencies
    private let settingsManager: SettingsManager
    private let urlSchemeHandler: URLSchemeHandler
    private let emailCaptureEngine: EmailCaptureEngine
    private let llmSummarizer: LLMSummarizer
    
    // Published state
    @Published public var isProcessing = false
    @Published public var lastError: String?
    @Published public var pendingEmailTask: EmailTaskData?
    
    // Callback for when email task is ready
    public var onEmailTaskReady: ((EmailTaskData) -> Void)?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init(
        settingsManager: SettingsManager = .shared,
        urlSchemeHandler: URLSchemeHandler = .shared,
        emailCaptureEngine: EmailCaptureEngine = .shared,
        llmSummarizer: LLMSummarizer = LLMSummarizer()
    ) {
        self.settingsManager = settingsManager
        self.urlSchemeHandler = urlSchemeHandler
        self.emailCaptureEngine = emailCaptureEngine
        self.llmSummarizer = llmSummarizer
        
        setupURLHandler()
    }
    
    // MARK: - Setup
    
    private func setupURLHandler() {
        // Listen for incoming email captures
        urlSchemeHandler.$pendingEmailCapture
            .compactMap { $0 }
            .sink { [weak self] capture in
                self?.handleIncomingEmail(capture)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public API
    
    /// Check if Outlook integration is enabled
    public var isEnabled: Bool {
        settingsManager.outlookIntegrationEnabled
    }
    
    /// Enable Outlook integration
    public func enable() {
        settingsManager.outlookIntegrationEnabled = true
        print("OutlookIntegrationService: Integration enabled")
    }
    
    /// Disable Outlook integration
    public func disable() {
        settingsManager.outlookIntegrationEnabled = false
        print("OutlookIntegrationService: Integration disabled")
    }
    
    /// Handle an incoming URL (called from app delegate or SwiftUI onOpenURL)
    @discardableResult
    public func handleIncomingURL(_ url: URL) -> Bool {
        guard isEnabled else {
            print("OutlookIntegrationService: Integration disabled, ignoring URL")
            lastError = "Outlook integration is disabled. Enable it in Settings."
            return false
        }
        
        return urlSchemeHandler.handleURL(url)
    }
    
    // MARK: - Email Processing
    
    /// Handle incoming email capture from URL scheme
    private func handleIncomingEmail(_ capture: EmailCapture) {
        guard isEnabled else {
            print("OutlookIntegrationService: Integration disabled, ignoring email")
            lastError = "Outlook integration is disabled"
            return
        }
        
        print("OutlookIntegrationService: Processing email - \(capture.subject)")
        
        isProcessing = true
        lastError = nil
        
        // Process asynchronously
        _Concurrency.Task {
            await processEmailCapture(capture)
        }
    }
    
    /// Process email capture and generate task data
    private func processEmailCapture(_ capture: EmailCapture) async {
        do {
            // Process the email
            let processedEmail = emailCaptureEngine.processCapture(capture)
            
            // Generate title using LLM
            let titleResult = await llmSummarizer.summarizeEmailForTitle(processedEmail)
            
            // Generate description using LLM
            let description = await llmSummarizer.summarizeEmailForDescription(processedEmail)
            
            // Create task data
            let taskData = EmailTaskData(
                title: titleResult.title,
                description: description,
                processedEmail: processedEmail,
                wasLLMGenerated: titleResult.wasGenerated
            )
            
            // Update UI on main thread
            await MainActor.run {
                self.isProcessing = false
                self.pendingEmailTask = taskData
                self.onEmailTaskReady?(taskData)
            }
            
            print("OutlookIntegrationService: Email processed successfully")
            
        } catch {
            await MainActor.run {
                self.isProcessing = false
                self.lastError = "Failed to process email: \(error.localizedDescription)"
            }
            print("OutlookIntegrationService: Error processing email - \(error)")
        }
    }
    
    /// Clear pending email task
    public func clearPendingTask() {
        pendingEmailTask = nil
    }
}

// MARK: - Data Models

/// Data for creating a task from an email
public struct EmailTaskData: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let processedEmail: ProcessedEmail
    public let wasLLMGenerated: Bool
    
    public init(
        title: String,
        description: String,
        processedEmail: ProcessedEmail,
        wasLLMGenerated: Bool
    ) {
        self.title = title
        self.description = description
        self.processedEmail = processedEmail
        self.wasLLMGenerated = wasLLMGenerated
    }
    
    /// Get email metadata for task creation
    public var metadata: EmailMetadata {
        processedEmail.metadata
    }
    
    /// Get original email body
    public var originalBody: String {
        processedEmail.originalCapture.body
    }
}
