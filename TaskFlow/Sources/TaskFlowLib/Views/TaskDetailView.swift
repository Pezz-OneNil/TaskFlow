import SwiftUI
import AppKit

/// Sheet for viewing and editing task details
/// Per Requirements 3.1, 3.2, 3.4, 3.5
public struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var taskManager: TaskManager
    @StateObject private var assigneeManager = AssigneeManager.shared
    let task: TFMTask
    let screenshotManager: ScreenshotManager
    let textExtractor: TextExtractor
    let onSave: ((TFMTask) -> Void)?
    
    @State private var title: String
    @State private var description: String
    @State private var furtherDetails: String
    @State private var assignedTo: String
    @State private var selectedTimeEstimate: TFMTimeEstimate
    @State private var selectedPriority: TFMPriority
    @State private var showingScreenshotViewer = false
    @State private var screenshot: NSImage?
    @State private var screenshotId: UUID?
    @State private var showAssigneeSuggestions = false
    @State private var isReplacingScreenshot = false
    
    public init(
        task: TFMTask,
        taskManager: TaskManager,
        screenshotManager: ScreenshotManager = ScreenshotManager(),
        textExtractor: TextExtractor = TextExtractor(),
        onSave: ((TFMTask) -> Void)? = nil
    ) {
        self.task = task
        self.taskManager = taskManager
        self.screenshotManager = screenshotManager
        self.textExtractor = textExtractor
        self.onSave = onSave
        
        // Initialize state from task
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description)
        _furtherDetails = State(initialValue: task.furtherDetails)
        _assignedTo = State(initialValue: task.assignedTo ?? "")
        _selectedTimeEstimate = State(initialValue: task.timeEstimate)
        _selectedPriority = State(initialValue: task.priority)
        _screenshotId = State(initialValue: task.screenshotId)
    }
    
    public var body: some View {
        let _ = print("TaskDetailView body rendering - task: \(task.title)")
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
                .background(CyberpunkTheme.accentPurple.opacity(0.3))
            
            ScrollView {
                VStack(alignment: .leading, spacing: CyberpunkTheme.spacingL) {
                    // Screenshot preview (if available)
                    screenshotSection
                    
                    // Metadata info
                    if task.metadata.hasContent {
                        metadataSection
                    }
                    
                    // Title input
                    titleSection
                    
                    // Description input
                    descriptionSection
                    
                    // Assigned To field
                    assignedToSection
                    
                    // Time estimate selection
                    timeEstimateSection
                    
                    // Priority selection
                    prioritySection
                    
                    // Further Details (OCR text) - at bottom before status
                    if !task.furtherDetails.isEmpty || !furtherDetails.isEmpty {
                        furtherDetailsSection
                    }
                    
                    // Status info
                    statusSection
                }
                .padding(CyberpunkTheme.spacingM)
            }
            
            Divider()
                .background(CyberpunkTheme.accentPurple.opacity(0.3))
            
            // Action buttons
            footer
        }
        .frame(minWidth: 500, minHeight: 600)
        .background(CyberpunkTheme.backgroundPrimary)
        .onAppear {
            loadScreenshot()
        }
        .sheet(isPresented: $showingScreenshotViewer) {
            if let screenshot = screenshot {
                ScreenshotViewerSheet(
                    screenshot: screenshot,
                    screenshotId: screenshotId,
                    screenshotManager: screenshotManager
                )
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            GlowingText("Edit Task", color: CyberpunkTheme.accentPurple, font: CyberpunkTheme.fontTitle)
            
            // LLM indicator
            if task.metadata.llmGeneratedTitle {
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
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private var screenshotSection: some View {
        NeonCard(color: CyberpunkTheme.accentPurple) {
            VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
                HStack {
                    Image(systemName: "photo")
                        .foregroundColor(CyberpunkTheme.accentPurple)
                    Text("Screenshot")
                        .font(CyberpunkTheme.fontHeadline)
                        .foregroundColor(CyberpunkTheme.accentPurple)
                    
                    Spacer()
                    
                    if screenshot != nil {
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
                    
                    Button(action: replaceScreenshot) {
                        HStack(spacing: 4) {
                            Image(systemName: screenshot != nil ? "arrow.triangle.2.circlepath" : "plus.circle")
                            Text(screenshot != nil ? "Replace" : "Add")
                        }
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.accentGreen)
                    }
                    .buttonStyle(.plain)
                    .disabled(isReplacingScreenshot)
                }
                
                if let screenshot = screenshot {
                    Image(nsImage: screenshot)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 150)
                        .cornerRadius(CyberpunkTheme.cornerRadiusM)
                        .overlay(
                            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                                .stroke(CyberpunkTheme.accentPurple.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    HStack {
                        Spacer()
                        VStack(spacing: CyberpunkTheme.spacingS) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 32))
                                .foregroundColor(CyberpunkTheme.textTertiary)
                            Text("No screenshot attached")
                                .font(CyberpunkTheme.fontCaption)
                                .foregroundColor(CyberpunkTheme.textTertiary)
                        }
                        .padding(CyberpunkTheme.spacingL)
                        Spacer()
                    }
                }
                
                if isReplacingScreenshot {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: CyberpunkTheme.accentCyan))
                            .scaleEffect(0.8)
                        Text("Processing...")
                            .font(CyberpunkTheme.fontCaption)
                            .foregroundColor(CyberpunkTheme.accentCyan)
                    }
                }
            }
        }
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
    
    private var metadataSection: some View {
        NeonCard(color: CyberpunkTheme.accentCyan) {
            VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(CyberpunkTheme.accentCyan)
                    Text("Source Info")
                        .font(CyberpunkTheme.fontHeadline)
                        .foregroundColor(CyberpunkTheme.accentCyan)
                }
                
                if let sender = task.metadata.sender {
                    metadataRow(label: "From", value: sender)
                }
                
                if let recipient = task.metadata.recipient {
                    metadataRow(label: "To", value: recipient)
                }
                
                if let subject = task.metadata.subject {
                    metadataRow(label: "Subject", value: subject)
                }
                
                if let app = task.metadata.sourceApp {
                    metadataRow(label: "Source", value: app)
                }
                
                if !task.metadata.keywords.isEmpty {
                    HStack(alignment: .top) {
                        Text("Keywords:")
                            .foregroundColor(CyberpunkTheme.textSecondary)
                        
                        FlowLayout(spacing: 4) {
                            ForEach(task.metadata.keywords, id: \.self) { keyword in
                                Text(keyword)
                                    .font(CyberpunkTheme.fontCaption)
                                    .foregroundColor(CyberpunkTheme.accentCyan)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(CyberpunkTheme.accentCyan.opacity(0.2))
                                    )
                            }
                        }
                    }
                    .font(CyberpunkTheme.fontCaption)
                }
            }
        }
    }
    
    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text("\(label):")
                .foregroundColor(CyberpunkTheme.textSecondary)
            Text(value)
                .foregroundColor(CyberpunkTheme.textPrimary)
        }
        .font(CyberpunkTheme.fontCaption)
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
            HStack {
                Text("Title")
                    .font(CyberpunkTheme.fontHeadline)
                    .foregroundColor(CyberpunkTheme.textSecondary)
                
                if task.metadata.llmGeneratedTitle {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(CyberpunkTheme.accentCyan)
                        .help("Originally generated by AI")
                }
            }
            
            TextField("Task title", text: $title)
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
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
            Text("Description")
                .font(CyberpunkTheme.fontHeadline)
                .foregroundColor(CyberpunkTheme.textSecondary)
            
            TextEditor(text: $description)
                .font(CyberpunkTheme.fontBody)
                .foregroundColor(CyberpunkTheme.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 60)
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
    }
    
    private var assignedToSection: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
            Text("Assigned To")
                .font(CyberpunkTheme.fontHeadline)
                .foregroundColor(CyberpunkTheme.textSecondary)
            
            ZStack(alignment: .topLeading) {
                TextField("Person or company name", text: $assignedTo)
                    .textFieldStyle(.plain)
                    .font(CyberpunkTheme.fontBody)
                    .foregroundColor(CyberpunkTheme.textPrimary)
                    .padding(CyberpunkTheme.spacingS)
                    .background(
                        RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                            .fill(CyberpunkTheme.backgroundSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                                    .stroke(CyberpunkTheme.accentCyan.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .onChange(of: assignedTo) { newValue in
                        showAssigneeSuggestions = !newValue.isEmpty && !assigneeManager.suggestions(for: newValue).isEmpty
                    }
                
                // Autocomplete suggestions dropdown
                if showAssigneeSuggestions {
                    let suggestions = assigneeManager.suggestions(for: assignedTo)
                    if !suggestions.isEmpty && suggestions.first != assignedTo {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(suggestions.prefix(5), id: \.self) { suggestion in
                                Button(action: {
                                    assignedTo = suggestion
                                    showAssigneeSuggestions = false
                                }) {
                                    Text(suggestion)
                                        .font(CyberpunkTheme.fontBody)
                                        .foregroundColor(CyberpunkTheme.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, CyberpunkTheme.spacingS)
                                        .padding(.vertical, CyberpunkTheme.spacingXS)
                                }
                                .buttonStyle(.plain)
                                .background(Color.clear)
                                .contentShape(Rectangle())
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                                .fill(CyberpunkTheme.backgroundSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                                        .stroke(CyberpunkTheme.accentCyan.opacity(0.5), lineWidth: 1)
                                )
                        )
                        .offset(y: 40)
                        .zIndex(100)
                    }
                }
            }
        }
    }
    
    private var furtherDetailsSection: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
            HStack {
                Text("Further Details")
                    .font(CyberpunkTheme.fontHeadline)
                    .foregroundColor(CyberpunkTheme.textSecondary)
                
                Text("(from OCR)")
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.textTertiary)
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
    
    private var timeEstimateSection: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
            Text("Time Estimate")
                .font(CyberpunkTheme.fontHeadline)
                .foregroundColor(CyberpunkTheme.textSecondary)
            
            HStack(spacing: CyberpunkTheme.spacingS) {
                ForEach(TFMTimeEstimate.allCases, id: \.self) { estimate in
                    TimeEstimateButton(
                        estimate: estimate,
                        isSelected: selectedTimeEstimate == estimate
                    ) {
                        selectedTimeEstimate = estimate
                    }
                }
            }
        }
    }
    
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
            Text("Priority")
                .font(CyberpunkTheme.fontHeadline)
                .foregroundColor(CyberpunkTheme.textSecondary)
            
            HStack(spacing: CyberpunkTheme.spacingS) {
                ForEach(TFMPriority.allCases, id: \.self) { priority in
                    PriorityButton(
                        priority: priority,
                        isSelected: selectedPriority == priority
                    ) {
                        selectedPriority = priority
                    }
                }
            }
        }
    }
    
    private var statusSection: some View {
        NeonCard(color: CyberpunkTheme.textSecondary) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status: \(task.status.displayName)")
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textSecondary)
                    
                    if let column = task.kanbanColumn {
                        Text("Kanban: \(column.displayName)")
                            .font(CyberpunkTheme.fontCaption)
                            .foregroundColor(CyberpunkTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Created: \(formatDate(task.createdAt))")
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textTertiary)
                    
                    Text("Updated: \(formatDate(task.updatedAt))")
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textTertiary)
                }
            }
        }
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            NeonButton(title: "Cancel", color: CyberpunkTheme.textSecondary) {
                dismiss()
            }
            
            Spacer()
            
            NeonButton(title: "Save Changes", color: CyberpunkTheme.accentGreen) {
                saveChanges()
            }
            .disabled(title.isEmpty)
        }
        .padding(CyberpunkTheme.spacingM)
    }
    
    // MARK: - Actions
    
    private func loadScreenshot() {
        if let id = screenshotId,
           let stored = screenshotManager.loadScreenshot(id: id) {
            screenshot = stored.image
        }
    }
    
    private func replaceScreenshot() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .tiff]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select a screenshot to attach"
        
        if panel.runModal() == .OK, let url = panel.url {
            isReplacingScreenshot = true
            
            _Concurrency.Task {
                do {
                    let imageData = try Data(contentsOf: url)
                    guard let image = NSImage(data: imageData) else {
                        throw NSError(domain: "TaskFlow", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image file"])
                    }
                    
                    // Save new screenshot
                    let newId = try screenshotManager.saveScreenshot(image)
                    
                    // Run OCR on new screenshot
                    let extraction = try await textExtractor.extractText(from: image)
                    
                    await MainActor.run {
                        screenshot = image
                        screenshotId = newId
                        
                        // Update further details with new OCR text if it was empty
                        if furtherDetails.isEmpty {
                            furtherDetails = extraction.rawText
                        }
                        
                        isReplacingScreenshot = false
                    }
                } catch {
                    await MainActor.run {
                        isReplacingScreenshot = false
                        print("Failed to replace screenshot: \(error)")
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        var updatedTask = task
        updatedTask.title = title
        updatedTask.description = description
        updatedTask.furtherDetails = furtherDetails
        updatedTask.assignedTo = assignedTo.isEmpty ? nil : assignedTo
        updatedTask.screenshotId = screenshotId
        updatedTask.timeEstimate = selectedTimeEstimate
        updatedTask.priority = selectedPriority
        updatedTask.updatedAt = Date()
        
        // Save assignee name for future autocomplete
        if !assignedTo.isEmpty {
            assigneeManager.addAssignee(assignedTo)
        }
        
        _ = taskManager.updateTask(updatedTask)
        onSave?(updatedTask)
        dismiss()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Simple flow layout for keywords
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}
