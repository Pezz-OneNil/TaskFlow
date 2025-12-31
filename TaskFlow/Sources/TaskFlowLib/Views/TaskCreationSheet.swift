import SwiftUI
import AppKit

/// Data for creating a task with all new Phase 2 features
public struct TaskCreationData {
    public var title: String
    public var description: String
    public var furtherDetails: String
    public var timeEstimate: TimeEstimate
    public var priority: Priority
    public var screenshotId: UUID?
    public var llmGeneratedTitle: Bool
    
    public init(
        title: String = "",
        description: String = "",
        furtherDetails: String = "",
        timeEstimate: TimeEstimate = .twenty,
        priority: Priority = .medium,
        screenshotId: UUID? = nil,
        llmGeneratedTitle: Bool = false
    ) {
        self.title = title
        self.description = description
        self.furtherDetails = furtherDetails
        self.timeEstimate = timeEstimate
        self.priority = priority
        self.screenshotId = screenshotId
        self.llmGeneratedTitle = llmGeneratedTitle
    }
}

/// Processing state for async OCR and LLM operations
public enum ProcessingState {
    case idle
    case processing
    case complete
    case error(String)
}

/// Sheet for creating a new task from extracted content
/// Per Requirements 3.1, 3.2, 3.4, 3.5, 2.6, 2B.2, 2B.5, 19.1, 19.2, 19.3
public struct TaskCreationSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let screenshot: NSImage?
    let screenshotId: UUID?
    let screenshotManager: ScreenshotManager?
    let textExtractor: TextExtractor?
    let llmSummarizer: LLMSummarizer?
    let onCreate: (String, String, TimeEstimate, Priority) -> Void
    let onCreateWithData: ((TaskCreationData) -> Void)?
    
    // Pre-populated data (for backward compatibility)
    let initialExtraction: TextExtraction?
    let initialLLMTitle: String?
    let initialLLMGenerated: Bool
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var furtherDetails: String = ""
    @State private var selectedTimeEstimate: TimeEstimate = .twenty
    @State private var selectedPriority: Priority = .medium
    @State private var showingScreenshotViewer = false
    
    // Processing states for parallel operations
    @State private var ocrState: ProcessingState = .idle
    @State private var llmTitleState: ProcessingState = .idle
    @State private var llmDescriptionState: ProcessingState = .idle
    @State private var llmGeneratedTitle: String = ""
    @State private var isLLMGenerated = false
    @State private var userHasEditedTitle = false
    @State private var savedScreenshotId: UUID?
    @State private var hasStartedProcessing = false
    
    /// New initializer for immediate display with parallel processing
    public init(
        screenshot: NSImage?,
        screenshotId: UUID? = nil,
        screenshotManager: ScreenshotManager? = nil,
        textExtractor: TextExtractor? = nil,
        llmSummarizer: LLMSummarizer? = nil,
        onCreate: @escaping (String, String, TimeEstimate, Priority) -> Void,
        onCreateWithData: ((TaskCreationData) -> Void)? = nil
    ) {
        self.screenshot = screenshot
        self.screenshotId = screenshotId
        self.screenshotManager = screenshotManager
        self.textExtractor = textExtractor
        self.llmSummarizer = llmSummarizer
        self.onCreate = onCreate
        self.onCreateWithData = onCreateWithData
        self.initialExtraction = nil
        self.initialLLMTitle = nil
        self.initialLLMGenerated = false
    }
    
    /// Legacy initializer for backward compatibility
    public init(
        extraction: TextExtraction? = nil,
        screenshot: NSImage? = nil,
        screenshotId: UUID? = nil,
        llmGeneratedTitle: Bool = false,
        onCreate: @escaping (String, String, TimeEstimate, Priority) -> Void,
        onCreateWithData: ((TaskCreationData) -> Void)? = nil
    ) {
        self.screenshot = screenshot
        self.screenshotId = screenshotId
        self.screenshotManager = nil
        self.textExtractor = nil
        self.llmSummarizer = nil
        self.onCreate = onCreate
        self.onCreateWithData = onCreateWithData
        self.initialExtraction = extraction
        self.initialLLMTitle = extraction?.subject
        self.initialLLMGenerated = llmGeneratedTitle
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                GlowingText("New Task", color: CyberpunkTheme.accentPurple, font: CyberpunkTheme.fontTitle)
                
                // Processing indicators
                HStack(spacing: CyberpunkTheme.spacingS) {
                    if case .processing = ocrState {
                        ProcessingIndicator(label: "OCR", color: CyberpunkTheme.accentCyan)
                    }
                    if case .processing = llmTitleState {
                        ProcessingIndicator(label: "AI Title", color: CyberpunkTheme.accentMagenta)
                    }
                    if case .processing = llmDescriptionState {
                        ProcessingIndicator(label: "AI Summary", color: CyberpunkTheme.accentPurple)
                    }
                }
                
                // LLM indicator (when complete)
                if isLLMGenerated && !userHasEditedTitle {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .foregroundColor(CyberpunkTheme.accentCyan)
                        Text("AI Title")
                            .font(CyberpunkTheme.fontCaption)
                            .foregroundColor(CyberpunkTheme.accentCyan)
                    }
                    .padding(.horizontal, CyberpunkTheme.spacingS)
                    .padding(.vertical, CyberpunkTheme.spacingXS)
                    .background(
                        Capsule()
                            .fill(CyberpunkTheme.accentCyan.opacity(0.2))
                    )
                }
                
                Spacer()
                NeonIconButton(systemName: "xmark", color: CyberpunkTheme.textSecondary) {
                    dismiss()
                }
            }
            .padding(CyberpunkTheme.spacingM)
            
            Divider()
                .background(CyberpunkTheme.accentPurple.opacity(0.3))
            
            ScrollView {
                VStack(alignment: .leading, spacing: CyberpunkTheme.spacingL) {
                    // Screenshot preview (if available)
                    if let screenshot = screenshot {
                        screenshotPreview(screenshot)
                    }
                    
                    // Title input
                    VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
                        HStack {
                            Text("Title")
                                .font(CyberpunkTheme.fontHeadline)
                                .foregroundColor(CyberpunkTheme.textSecondary)
                            
                            if case .processing = llmTitleState {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .frame(width: 16, height: 16)
                            } else if isLLMGenerated && !userHasEditedTitle {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12))
                                    .foregroundColor(CyberpunkTheme.accentCyan)
                                    .help("Generated by AI - will be used if you don't enter a title")
                            }
                        }
                        
                        TextField("Task title (leave empty for AI suggestion)", text: $title)
                            .textFieldStyle(.plain)
                            .font(CyberpunkTheme.fontBody)
                            .foregroundColor(CyberpunkTheme.textPrimary)
                            .padding(CyberpunkTheme.spacingS)
                            .background(
                                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                                    .fill(CyberpunkTheme.backgroundSecondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                                            .stroke(CyberpunkTheme.accentPurple.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .onChange(of: title) { newValue in
                                if !newValue.isEmpty {
                                    userHasEditedTitle = true
                                }
                            }
                        
                        // Show AI suggestion if user hasn't typed anything
                        if title.isEmpty && !llmGeneratedTitle.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 11))
                                Text("AI suggestion: \(llmGeneratedTitle)")
                                    .font(CyberpunkTheme.fontCaption)
                            }
                            .foregroundColor(CyberpunkTheme.accentCyan.opacity(0.8))
                            .onTapGesture {
                                title = llmGeneratedTitle
                                userHasEditedTitle = false
                            }
                        }
                    }
                    
                    // Description input (AI-generated summary)
                    VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
                        HStack {
                            Text("Description")
                                .font(CyberpunkTheme.fontHeadline)
                                .foregroundColor(CyberpunkTheme.textSecondary)
                            
                            if case .processing = llmDescriptionState {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .frame(width: 16, height: 16)
                                Text("Generating summary...")
                                    .font(CyberpunkTheme.fontCaption)
                                    .foregroundColor(CyberpunkTheme.textTertiary)
                            }
                        }
                        
                        TextEditor(text: $description)
                            .font(CyberpunkTheme.fontBody)
                            .foregroundColor(CyberpunkTheme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 80)
                            .padding(CyberpunkTheme.spacingS)
                            .background(
                                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                                    .fill(CyberpunkTheme.backgroundSecondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                                            .stroke(CyberpunkTheme.accentPurple.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    
                    // Time estimate selection
                    VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
                        Text("Time Estimate")
                            .font(CyberpunkTheme.fontHeadline)
                            .foregroundColor(CyberpunkTheme.textSecondary)
                        
                        HStack(spacing: CyberpunkTheme.spacingS) {
                            ForEach(TimeEstimate.allCases, id: \.self) { estimate in
                                TimeEstimateButton(
                                    estimate: estimate,
                                    isSelected: selectedTimeEstimate == estimate
                                ) {
                                    selectedTimeEstimate = estimate
                                }
                            }
                        }
                    }
                    
                    // Priority selection
                    VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
                        Text("Priority")
                            .font(CyberpunkTheme.fontHeadline)
                            .foregroundColor(CyberpunkTheme.textSecondary)
                        
                        HStack(spacing: CyberpunkTheme.spacingS) {
                            ForEach(Priority.allCases, id: \.self) { priority in
                                PriorityButton(
                                    priority: priority,
                                    isSelected: selectedPriority == priority
                                ) {
                                    selectedPriority = priority
                                }
                            }
                        }
                    }
                    
                    // Further Details (OCR text) - at bottom before action buttons
                    VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
                        HStack {
                            Text("Further Details")
                                .font(CyberpunkTheme.fontHeadline)
                                .foregroundColor(CyberpunkTheme.textSecondary)
                            
                            if case .processing = ocrState {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .frame(width: 16, height: 16)
                                Text("Extracting text...")
                                    .font(CyberpunkTheme.fontCaption)
                                    .foregroundColor(CyberpunkTheme.textTertiary)
                            } else {
                                Text("(from OCR)")
                                    .font(CyberpunkTheme.fontCaption)
                                    .foregroundColor(CyberpunkTheme.textTertiary)
                            }
                        }
                        
                        TextEditor(text: $furtherDetails)
                            .font(CyberpunkTheme.fontCaption)
                            .foregroundColor(CyberpunkTheme.textSecondary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 100)
                            .padding(CyberpunkTheme.spacingS)
                            .background(
                                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                                    .fill(CyberpunkTheme.backgroundSecondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                                            .stroke(CyberpunkTheme.accentCyan.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(CyberpunkTheme.spacingM)
            }
            
            Divider()
                .background(CyberpunkTheme.accentPurple.opacity(0.3))
            
            // Action buttons
            HStack {
                NeonButton(title: "Cancel", color: CyberpunkTheme.textSecondary) {
                    dismiss()
                }
                
                Spacer()
                
                NeonButton(title: "Create Task", color: CyberpunkTheme.accentGreen) {
                    createTask()
                }
            }
            .padding(CyberpunkTheme.spacingM)
        }
        .frame(minWidth: 500, minHeight: 600)
        .background(CyberpunkTheme.backgroundPrimary)
        .onAppear {
            NSLog("TaskCreationSheet: onAppear called, hasStartedProcessing = %@", hasStartedProcessing ? "true" : "false")
            NSLog("TaskCreationSheet: screenshot = %@", screenshot != nil ? "present" : "nil")
            setupInitialState()
            // Only start processing once
            if !hasStartedProcessing {
                hasStartedProcessing = true
                NSLog("TaskCreationSheet: Starting processing for first time")
                startParallelProcessing()
            }
        }
    }
    
    // MARK: - Setup and Processing
    
    private func setupInitialState() {
        savedScreenshotId = screenshotId
        
        // Handle legacy initializer with pre-populated data
        if let extraction = initialExtraction {
            if let subject = extraction.subject {
                title = subject
                llmGeneratedTitle = subject
                isLLMGenerated = initialLLMGenerated
            }
            description = extraction.bodyContent
            furtherDetails = extraction.rawText
            ocrState = .complete
            llmTitleState = .complete
            llmDescriptionState = .complete
        }
    }
    
    private func startParallelProcessing() {
        // Skip if using legacy initializer with pre-populated data
        guard initialExtraction == nil else { 
            NSLog("TaskCreationSheet: Skipping parallel processing - using legacy initializer")
            return 
        }
        guard let screenshot = screenshot else { 
            NSLog("TaskCreationSheet: Skipping parallel processing - no screenshot")
            return 
        }
        
        // Debug: Check if services are available
        NSLog("TaskCreationSheet: Starting parallel processing...")
        NSLog("TaskCreationSheet: screenshotManager = %@", screenshotManager != nil ? "available" : "nil")
        NSLog("TaskCreationSheet: textExtractor = %@", textExtractor != nil ? "available" : "nil")
        NSLog("TaskCreationSheet: llmSummarizer = %@", llmSummarizer != nil ? "available" : "nil")
        
        // Start parallel processing in a detached task to avoid cancellation
        _Concurrency.Task.detached { [screenshot, screenshotManager, textExtractor, llmSummarizer, screenshotId] in
            await self.runParallelProcessingDetached(
                for: screenshot,
                screenshotManager: screenshotManager,
                textExtractor: textExtractor,
                llmSummarizer: llmSummarizer,
                existingScreenshotId: screenshotId
            )
        }
    }
    
    private func runParallelProcessing(for image: NSImage) async {
        // Save screenshot if needed
        if savedScreenshotId == nil, let manager = screenshotManager {
            do {
                let newId = try manager.saveScreenshot(image)
                await MainActor.run {
                    savedScreenshotId = newId
                }
                print("TaskCreationSheet: Screenshot saved with ID: \(newId)")
            } catch {
                print("TaskCreationSheet: Failed to save screenshot: \(error)")
            }
        }
        
        // Run OCR
        guard let extractor = textExtractor else {
            print("TaskCreationSheet: No text extractor available")
            return
        }
        
        await MainActor.run { ocrState = .processing }
        print("TaskCreationSheet: Starting OCR...")
        
        do {
            let extraction = try await extractor.extractText(from: image)
            print("TaskCreationSheet: OCR complete, text length: \(extraction.rawText.count)")
            
            await MainActor.run {
                furtherDetails = extraction.rawText
                ocrState = .complete
            }
            
            // Now run LLM tasks in parallel
            let rawText = extraction.rawText
            let summarizer = llmSummarizer
            
            async let titleTask: Void = generateTitleAsync(from: rawText, summarizer: summarizer)
            async let descTask: Void = generateDescriptionAsync(from: rawText, summarizer: summarizer)
            
            // Wait for both to complete
            _ = await (titleTask, descTask)
            
            print("TaskCreationSheet: All processing complete")
            
        } catch {
            print("TaskCreationSheet: OCR error - \(error)")
            await MainActor.run {
                ocrState = .error(error.localizedDescription)
            }
        }
    }
    
    /// Detached version that captures services to avoid view lifecycle issues
    private func runParallelProcessingDetached(
        for image: NSImage,
        screenshotManager: ScreenshotManager?,
        textExtractor: TextExtractor?,
        llmSummarizer: LLMSummarizer?,
        existingScreenshotId: UUID?
    ) async {
        // Use existing screenshot ID if provided (screenshot already saved by MainWindowView)
        // Only save if no ID was provided
        if let existingId = existingScreenshotId {
            print("TaskCreationSheet: Using existing screenshot ID: \(existingId)")
            await MainActor.run {
                self.savedScreenshotId = existingId
            }
        } else if let manager = screenshotManager {
            do {
                let newId = try manager.saveScreenshot(image)
                await MainActor.run {
                    self.savedScreenshotId = newId
                }
                print("TaskCreationSheet: Screenshot saved with ID: \(newId)")
            } catch {
                print("TaskCreationSheet: Failed to save screenshot: \(error)")
            }
        }
        
        // Run OCR
        guard let extractor = textExtractor else {
            print("TaskCreationSheet: No text extractor available in detached task")
            return
        }
        
        await MainActor.run { self.ocrState = .processing }
        print("TaskCreationSheet: Starting OCR (detached)...")
        
        do {
            let extraction = try await extractor.extractText(from: image)
            print("TaskCreationSheet: OCR complete, text length: \(extraction.rawText.count)")
            
            await MainActor.run {
                self.furtherDetails = extraction.rawText
                self.ocrState = .complete
            }
            
            // Now run LLM tasks in parallel
            let rawText = extraction.rawText
            
            async let titleTask: Void = self.generateTitleAsyncDetached(from: rawText, summarizer: llmSummarizer)
            async let descTask: Void = self.generateDescriptionAsyncDetached(from: rawText, summarizer: llmSummarizer)
            
            // Wait for both to complete
            _ = await (titleTask, descTask)
            
            print("TaskCreationSheet: All processing complete (detached)")
            
        } catch {
            print("TaskCreationSheet: OCR error - \(error)")
            await MainActor.run {
                self.ocrState = .error(error.localizedDescription)
            }
        }
    }
    
    private func generateTitleAsyncDetached(from text: String, summarizer: LLMSummarizer?) async {
        guard let summarizer = summarizer else {
            print("TaskCreationSheet: No LLM summarizer for title (detached)")
            return
        }
        
        await MainActor.run { self.llmTitleState = .processing }
        print("TaskCreationSheet: Generating title (detached)...")
        
        let result = await summarizer.summarizeForTitle(text: text)
        print("TaskCreationSheet: Title generated: \(result.title), wasGenerated: \(result.wasGenerated)")
        
        await MainActor.run {
            self.llmGeneratedTitle = result.title
            self.isLLMGenerated = result.wasGenerated
            self.llmTitleState = .complete
        }
    }
    
    private func generateDescriptionAsyncDetached(from text: String, summarizer: LLMSummarizer?) async {
        guard let summarizer = summarizer else {
            // Fallback: use first few lines
            print("TaskCreationSheet: No LLM summarizer for description (detached), using fallback")
            await MainActor.run {
                if self.description.isEmpty {
                    let lines = text.components(separatedBy: .newlines)
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                        .prefix(3)
                    self.description = lines.joined(separator: " ")
                    if self.description.count > 200 {
                        self.description = String(self.description.prefix(197)) + "..."
                    }
                }
                self.llmDescriptionState = .complete
            }
            return
        }
        
        await MainActor.run { self.llmDescriptionState = .processing }
        print("TaskCreationSheet: Generating description (detached)...")
        
        let generatedDescription = await summarizer.generateDescription(from: text)
        print("TaskCreationSheet: Description generated: \(generatedDescription.prefix(50))...")
        
        await MainActor.run {
            if self.description.isEmpty {
                self.description = generatedDescription
            }
            self.llmDescriptionState = .complete
        }
    }
    
    private func generateTitleAsync(from text: String, summarizer: LLMSummarizer?) async {
        guard let summarizer = summarizer else {
            print("TaskCreationSheet: No LLM summarizer for title")
            return
        }
        
        await MainActor.run { llmTitleState = .processing }
        print("TaskCreationSheet: Generating title...")
        
        let result = await summarizer.summarizeForTitle(text: text)
        print("TaskCreationSheet: Title generated: \(result.title), wasGenerated: \(result.wasGenerated)")
        
        await MainActor.run {
            llmGeneratedTitle = result.title
            isLLMGenerated = result.wasGenerated
            llmTitleState = .complete
        }
    }
    
    private func generateDescriptionAsync(from text: String, summarizer: LLMSummarizer?) async {
        guard let summarizer = summarizer else {
            // Fallback: use first few lines
            print("TaskCreationSheet: No LLM summarizer for description, using fallback")
            await MainActor.run {
                if description.isEmpty {
                    let lines = text.components(separatedBy: .newlines)
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                        .prefix(3)
                    description = lines.joined(separator: " ")
                    if description.count > 200 {
                        description = String(description.prefix(197)) + "..."
                    }
                }
                llmDescriptionState = .complete
            }
            return
        }
        
        await MainActor.run { llmDescriptionState = .processing }
        print("TaskCreationSheet: Generating description...")
        
        let generatedDescription = await summarizer.generateDescription(from: text)
        print("TaskCreationSheet: Description generated: \(generatedDescription.prefix(50))...")
        
        await MainActor.run {
            if description.isEmpty {
                description = generatedDescription
            }
            llmDescriptionState = .complete
        }
    }
    
    private func createTask() {
        // Use LLM title if user didn't provide one
        let finalTitle = title.isEmpty ? llmGeneratedTitle : title
        let finalIsLLMGenerated = title.isEmpty && isLLMGenerated
        
        if let onCreateWithData = onCreateWithData {
            let data = TaskCreationData(
                title: finalTitle.isEmpty ? "New Task" : finalTitle,
                description: description,
                furtherDetails: furtherDetails,
                timeEstimate: selectedTimeEstimate,
                priority: selectedPriority,
                screenshotId: savedScreenshotId ?? screenshotId,
                llmGeneratedTitle: finalIsLLMGenerated
            )
            onCreateWithData(data)
        } else {
            onCreate(finalTitle.isEmpty ? "New Task" : finalTitle, description, selectedTimeEstimate, selectedPriority)
        }
        dismiss()
    }
    
    @ViewBuilder
    private func screenshotPreview(_ image: NSImage) -> some View {
        NeonCard(color: CyberpunkTheme.accentPurple) {
            VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
                HStack {
                    Image(systemName: "photo")
                        .foregroundColor(CyberpunkTheme.accentPurple)
                    Text("Screenshot")
                        .font(CyberpunkTheme.fontHeadline)
                        .foregroundColor(CyberpunkTheme.accentPurple)
                    
                    Spacer()
                    
                    Button(action: { showingScreenshotViewer = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                            Text("View Full")
                        }
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.accentCyan)
                    }
                    .buttonStyle(.plain)
                }
                
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 150)
                    .cornerRadius(CyberpunkTheme.cornerRadiusM)
                    .overlay(
                        RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                            .stroke(CyberpunkTheme.accentPurple.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}

/// Small processing indicator for header
struct ProcessingIndicator: View {
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            ProgressView()
                .scaleEffect(0.5)
                .frame(width: 12, height: 12)
            Text(label)
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(color)
        }
        .padding(.horizontal, CyberpunkTheme.spacingS)
        .padding(.vertical, CyberpunkTheme.spacingXS)
        .background(
            Capsule()
                .fill(color.opacity(0.2))
        )
    }
}

/// Button for selecting time estimate
struct TimeEstimateButton: View {
    let estimate: TimeEstimate
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(estimate.displayName)
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(isSelected ? CyberpunkTheme.backgroundPrimary : CyberpunkTheme.textPrimary)
                .padding(.horizontal, CyberpunkTheme.spacingM)
                .padding(.vertical, CyberpunkTheme.spacingS)
                .background(
                    RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                        .fill(isSelected ? CyberpunkTheme.color(for: estimate) : CyberpunkTheme.backgroundSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                                .stroke(CyberpunkTheme.color(for: estimate), lineWidth: 1)
                        )
                )
                .shadow(color: isSelected ? CyberpunkTheme.color(for: estimate).opacity(0.5) : .clear, radius: CyberpunkTheme.glowRadius)
        }
        .buttonStyle(.plain)
    }
}

/// Button for selecting priority
struct PriorityButton: View {
    let priority: Priority
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(priority.displayName)
                .font(CyberpunkTheme.fontHeadline)
                .foregroundColor(isSelected ? CyberpunkTheme.backgroundPrimary : CyberpunkTheme.textPrimary)
                .padding(.horizontal, CyberpunkTheme.spacingL)
                .padding(.vertical, CyberpunkTheme.spacingS)
                .background(
                    RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                        .fill(isSelected ? CyberpunkTheme.color(for: priority) : CyberpunkTheme.backgroundSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                                .stroke(CyberpunkTheme.color(for: priority), lineWidth: 2)
                        )
                )
                .shadow(color: isSelected ? CyberpunkTheme.color(for: priority).opacity(0.6) : .clear, radius: CyberpunkTheme.glowRadiusIntense)
        }
        .buttonStyle(.plain)
    }
}
