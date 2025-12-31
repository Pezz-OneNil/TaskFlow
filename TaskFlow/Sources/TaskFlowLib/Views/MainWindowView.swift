import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Wrapper for captured screenshot to use with sheet(item:) binding
/// This ensures the screenshot is available when the sheet appears
public struct CapturedScreenshotItem: Identifiable {
    public let id: UUID
    public let image: NSImage
    
    public init(image: NSImage, id: UUID = UUID()) {
        self.id = id
        self.image = image
    }
}

/// Wrapper for email drop result to use with sheet(item:) binding
public struct EmailDropResultItem: Identifiable {
    public let id = UUID()
    public let result: EmailDropResult
    
    public init(result: EmailDropResult) {
        self.result = result
    }
}

/// Main navigation tabs
public enum NavigationTab: String, CaseIterable {
    case tasks = "Tasks"
    case pomodoro = "Pomodoro"
    case kanban = "Kanban"
    case annual = "Annual"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .tasks: return "checklist"
        case .pomodoro: return "timer"
        case .kanban: return "rectangle.3.group"
        case .annual: return "calendar"
        case .settings: return "gearshape"
        }
    }
    
    var color: Color {
        switch self {
        case .tasks: return CyberpunkTheme.accentPurple
        case .pomodoro: return CyberpunkTheme.accentCyan
        case .kanban: return CyberpunkTheme.accentMagenta
        case .annual: return CyberpunkTheme.accentYellow
        case .settings: return CyberpunkTheme.textSecondary
        }
    }
    
    /// Returns visible tabs based on settings
    /// Per Requirement 1.2, 1.3
    public static func visibleTabs(showAnnual: Bool) -> [NavigationTab] {
        if showAnnual {
            return [.tasks, .pomodoro, .kanban, .annual, .settings]
        } else {
            return [.tasks, .pomodoro, .kanban, .settings]
        }
    }
}

/// Main window view with tab-based navigation
/// Per Requirements 8.4
public struct MainWindowView: View {
    @ObservedObject var taskManager: TaskManager
    @ObservedObject var pomodoroEngine: PomodoroEngine
    @ObservedObject var backupManager: BackupManager
    @ObservedObject private var settingsManager = SettingsManager.shared
    @StateObject private var statusBarManager = StatusBarManager()
    @StateObject private var emailDropHandler = EmailDropHandler()
    
    @State private var selectedTab: NavigationTab = .tasks
    @State private var showingTaskCreation = false
    @State private var pendingExtraction: TextExtraction?
    
    // Search state
    @State private var searchQuery: String = ""
    @State private var isSearchActive: Bool = false
    
    // Capture flow state
    @State private var showingCaptureOverlay = false
    @State private var capturedScreenshotItem: CapturedScreenshotItem?
    @State private var llmGeneratedTitle: String?
    @State private var isLLMGenerated = false
    @State private var isProcessingCapture = false
    
    // Email drop state
    @State private var emailDropResultItem: EmailDropResultItem?
    
    // Edit task state
    @State private var taskToEdit: Task?
    
    // Window reference for hiding during capture
    @State private var mainWindow: NSWindow?
    
    let searchTermGenerator = SearchTermGenerator()
    let screenshotManager: ScreenshotManager
    let textExtractor: TextExtractor
    let llmSummarizer: LLMSummarizer
    
    public init(
        taskManager: TaskManager,
        pomodoroEngine: PomodoroEngine,
        backupManager: BackupManager,
        screenshotManager: ScreenshotManager,
        textExtractor: TextExtractor,
        llmSummarizer: LLMSummarizer
    ) {
        self.taskManager = taskManager
        self.pomodoroEngine = pomodoroEngine
        self.backupManager = backupManager
        self.screenshotManager = screenshotManager
        self.textExtractor = textExtractor
        self.llmSummarizer = llmSummarizer
    }
    
    /// Filter tasks based on search query
    private func filterTasks(_ tasks: [Task]) -> [Task] {
        guard !searchQuery.isEmpty else { return tasks }
        let query = searchQuery.lowercased()
        return tasks.filter { task in
            task.title.lowercased().contains(query) ||
            task.description.lowercased().contains(query) ||
            task.furtherDetails.lowercased().contains(query) ||
            (task.assignedTo?.lowercased().contains(query) ?? false) ||
            task.metadata.keywords.contains { $0.lowercased().contains(query) } ||
            (task.metadata.sender?.lowercased().contains(query) ?? false) ||
            (task.metadata.subject?.lowercased().contains(query) ?? false)
        }
    }
    
    public var body: some View {
        ZStack {
            // Background
            CyberpunkTheme.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Tab bar
                tabBar
                
                Divider()
                    .background(CyberpunkTheme.accentPurple.opacity(0.3))
                
                // Content
                contentView
                
                // Status bar at bottom
                StatusBarView(statusBarManager: statusBarManager)
            }
            
            // Floating capture button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    floatingCaptureButton
                        .padding(.trailing, CyberpunkTheme.spacingL)
                        .padding(.bottom, CyberpunkTheme.spacingL + 28) // Account for status bar height
                }
            }
            
            // Email drop zone overlay
            DropZoneOverlay(
                dropState: emailDropHandler.dropState,
                progress: emailDropHandler.progress
            )
        }
        // Email drag and drop handling
        .onDrop(of: [.fileURL], delegate: EmailDropDelegate(
            dropHandler: emailDropHandler,
            onDropComplete: { results in
                handleEmailDropResults(results)
            }
        ))
        .sheet(item: $capturedScreenshotItem) { item in
            TaskCreationSheet(
                screenshot: item.image,
                screenshotId: item.id,
                screenshotManager: screenshotManager,
                textExtractor: textExtractor,
                llmSummarizer: llmSummarizer,
                onCreate: { title, description, timeEstimate, priority in
                    _ = taskManager.createTask(
                        title: title,
                        description: description,
                        timeEstimate: timeEstimate,
                        priority: priority
                    )
                    clearCaptureState()
                },
                onCreateWithData: { data in
                    // Create task with all data from the sheet
                    var task = taskManager.createTask(
                        title: data.title,
                        description: data.description,
                        timeEstimate: data.timeEstimate,
                        priority: data.priority
                    )
                    // Update with additional fields
                    task.furtherDetails = data.furtherDetails
                    task.screenshotId = data.screenshotId
                    task.metadata.llmGeneratedTitle = data.llmGeneratedTitle
                    _ = taskManager.updateTask(task)
                    clearCaptureState()
                }
            )
        }
        .sheet(item: $taskToEdit) { task in
            let _ = print("Sheet presenting task: \(task.title)")
            TaskDetailView(
                task: task,
                taskManager: taskManager,
                screenshotManager: screenshotManager
            )
            .frame(minWidth: 500, minHeight: 600)
        }
        .sheet(item: $emailDropResultItem) { item in
            EmailTaskCreationSheet(
                result: item.result,
                taskManager: taskManager,
                onDismiss: {
                    emailDropResultItem = nil
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MenuBarCaptureRequested"))) { _ in
            // Handle capture request from menu bar
            startCapture()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CaptureCompleted"))) { _ in
            // Restore window when capture completes or is cancelled
            restoreMainWindow()
        }
        .background(WindowAccessor(window: $mainWindow))
        .frame(minWidth: 900, minHeight: 600)
    }
    
    // MARK: - Email Drop Handling
    
    /// Handle results from email drop
    private func handleEmailDropResults(_ results: [EmailDropResult]) {
        let successResults = results.filter { $0.isSuccess }
        
        if successResults.isEmpty {
            // All failed
            statusBarManager.setError("Failed to process email files")
            statusBarManager.clearAfterDelay(3)
            return
        }
        
        // Check if auto-create is enabled
        if SettingsManager.shared.emailAutoCreateTasks {
            // Auto-create tasks without showing dialog
            for result in successResults {
                if let email = result.parsedEmail {
                    let title = result.suggestedTitle ?? email.subject
                    let description = result.suggestedDescription ?? extractEmailDescription(email)
                    
                    var task = taskManager.createTask(
                        title: title,
                        description: description,
                        timeEstimate: .twenty,
                        priority: .medium
                    )
                    
                    // Add email metadata and body content
                    task.metadata.sender = email.sender.displayString
                    task.metadata.subject = email.subject
                    task.furtherDetails = email.body
                    _ = taskManager.updateTask(task)
                }
            }
            
            statusBarManager.setSuccess("Created \(successResults.count) task(s) from email")
            statusBarManager.clearAfterDelay(2)
        } else {
            // Show task creation dialog for first result
            // (for multiple files, we process one at a time)
            if let firstResult = successResults.first {
                emailDropResultItem = EmailDropResultItem(result: firstResult)
            }
        }
    }
    
    /// Extract description from parsed email
    private func extractEmailDescription(_ email: ParsedEmail) -> String {
        let body = email.body
        let maxLength = 300
        
        if body.count > maxLength {
            let index = body.index(body.startIndex, offsetBy: maxLength)
            return String(body[..<index]) + "..."
        }
        
        return body
    }
    
    // MARK: - Tab Bar
    
    private var tabBar: some View {
        GeometryReader { geometry in
            let showTabText = geometry.size.width > 700 // Hide text below 700px width
            
            HStack(spacing: showTabText ? CyberpunkTheme.spacingL : CyberpunkTheme.spacingM) {
                ForEach(NavigationTab.visibleTabs(showAnnual: settingsManager.showAnnualCalendar), id: \.self) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        showText: showTabText
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }
                }
                
                Spacer()
                
                // Search bar - hide when very narrow
                if geometry.size.width > 600 {
                    searchBar
                }
                
                // Model selector - hide when narrow
                if geometry.size.width > 800 {
                    ModelSelectorView(llmSummarizer: llmSummarizer)
                }
                
                // Quick stats
                HStack(spacing: CyberpunkTheme.spacingM) {
                    StatBadge(
                        icon: "checklist",
                        value: "\(taskManager.getActiveTasks().count)",
                        color: CyberpunkTheme.accentPurple
                    )
                    
                    if pomodoroEngine.isRunning {
                        StatBadge(
                            icon: "timer",
                            value: formatTime(pomodoroEngine.remainingTime),
                            color: CyberpunkTheme.accentCyan
                        )
                    }
                }
            }
            .padding(.horizontal, CyberpunkTheme.spacingM)
            .padding(.vertical, CyberpunkTheme.spacingS)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 48)
        .background(CyberpunkTheme.backgroundSecondary)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: CyberpunkTheme.spacingS) {
            HStack(spacing: CyberpunkTheme.spacingXS) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(isSearchActive ? CyberpunkTheme.accentCyan : CyberpunkTheme.textTertiary)
                    .font(.system(size: 14))
                
                TextField("Search tasks...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.textPrimary)
                    .frame(width: isSearchActive ? 150 : 100)
                    .onSubmit {
                        isSearchActive = !searchQuery.isEmpty
                    }
            }
            .padding(.horizontal, CyberpunkTheme.spacingS)
            .padding(.vertical, CyberpunkTheme.spacingXS)
            .background(
                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                    .fill(CyberpunkTheme.backgroundPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                            .stroke(isSearchActive ? CyberpunkTheme.accentCyan : CyberpunkTheme.textTertiary.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Clear search button
            if !searchQuery.isEmpty {
                Button(action: {
                    searchQuery = ""
                    isSearchActive = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(CyberpunkTheme.accentMagenta)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .help("Clear search")
            }
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .tasks:
            TaskListView(
                taskManager: taskManager,
                searchQuery: searchQuery,
                filterTasks: filterTasks,
                onComplete: { task in
                    taskManager.markComplete(task)
                },
                onDelete: { task in
                    taskManager.softDeleteTask(task)
                },
                onMoveToKanban: { task in
                    taskManager.moveToKanban(task, column: .backlog)
                },
                onCopySearchTerms: { task in
                    _ = searchTermGenerator.generateAndCopy(for: task)
                },
                onEdit: { task in
                    taskToEdit = task
                }
            )
            
        case .pomodoro:
            PomodoroTimerView(
                engine: pomodoroEngine,
                onStartSession: { _ in },
                onEdit: { task in
                    taskToEdit = task
                }
            )
            
        case .kanban:
            KanbanBoardView(
                taskManager: taskManager,
                searchQuery: searchQuery,
                filterTasks: filterTasks,
                onMoveColumn: { task, column in
                    taskManager.moveKanbanColumn(task, to: column)
                },
                onMoveToActive: { task in
                    taskManager.moveFromKanban(task)
                },
                onComplete: { task in
                    taskManager.markComplete(task)
                },
                onRestore: { task in
                    taskManager.restoreFromDeleted(task)
                },
                onPermanentDelete: { task in
                    _ = taskManager.permanentlyDeleteTask(id: task.id)
                },
                onEdit: { task in
                    taskToEdit = task
                }
            )
            
        case .annual:
            AnnualCalendarView(taskManager: taskManager)
            
        case .settings:
            BackupRestoreView(
                backupManager: backupManager,
                taskManager: taskManager
            )
        }
    }
    
    // MARK: - Floating Capture Button
    
    private var floatingCaptureButton: some View {
        Button(action: {
            startCapture()
        }) {
            ZStack {
                Circle()
                    .fill(CyberpunkTheme.accentPurple)
                    .frame(width: 56, height: 56)
                    .shadow(color: CyberpunkTheme.accentPurple.opacity(0.6), radius: CyberpunkTheme.glowRadiusIntense)
                
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 24))
                    .foregroundColor(CyberpunkTheme.textPrimary)
            }
        }
        .buttonStyle(.plain)
        .keyboardShortcut("c", modifiers: [.command, .shift])
        .help("Capture screen (⌘⇧C)")
    }
    
    // MARK: - Capture Flow
    
    /// Start the screen capture flow
    private func startCapture() {
        statusBarManager.setProcessing("Starting capture...")
        
        // Hide the main window so user can capture what's behind it
        hideMainWindow()
        
        // Small delay to ensure window is fully hidden before showing overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            // Create and present the capture overlay window
            let controller = CaptureOverlayWindowController(
                onCapture: { result in
                    processCapture(result)
                },
                onCancel: {
                    statusBarManager.clearStatus()
                    clearCaptureState()
                    // Restore window on cancel
                    restoreMainWindow()
                }
            )
            controller.present()
        }
    }
    
    /// Hide the main window during capture
    private func hideMainWindow() {
        if let window = mainWindow {
            print("MainWindowView: Hiding main window for capture")
            window.orderOut(nil)
        } else {
            // Fallback: try to find and hide any TaskFlow window
            for window in NSApp.windows {
                if window.title.contains("TaskFlow") || window.contentView is NSHostingView<MainWindowView> {
                    print("MainWindowView: Hiding window (fallback): \(window.title)")
                    window.orderOut(nil)
                    break
                }
            }
        }
    }
    
    /// Restore the main window after capture
    private func restoreMainWindow() {
        if let window = mainWindow {
            print("MainWindowView: Restoring main window")
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            // Fallback: activate app and show first available window
            NSApp.activate(ignoringOtherApps: true)
            if let window = NSApp.windows.first(where: { $0.canBecomeKey }) {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    /// Process the captured screenshot - immediately show task creation sheet
    /// Per Requirement 19.1 - Screenshot shown immediately, OCR/LLM run in parallel
    private func processCapture(_ result: CaptureResult) {
        print("ProcessCapture: Screenshot captured, showing task creation immediately...")
        statusBarManager.setSuccess("Screenshot captured")
        
        // Restore the main window
        restoreMainWindow()
        
        // Save the screenshot first to get a valid ID
        // This ensures the screenshot is persisted before showing the sheet
        do {
            let screenshotId = try screenshotManager.saveScreenshot(result.image)
            print("ProcessCapture: Screenshot saved with ID: \(screenshotId)")
            
            // Create the item with the screenshot and its saved ID
            // Using item binding ensures the screenshot is available when sheet appears
            capturedScreenshotItem = CapturedScreenshotItem(image: result.image, id: screenshotId)
        } catch {
            print("ProcessCapture: Failed to save screenshot: \(error)")
            // Still show the sheet even if save failed - parallel processing will retry
            capturedScreenshotItem = CapturedScreenshotItem(image: result.image)
        }
        
        statusBarManager.clearAfterDelay(2)
    }
    
    /// Clear all capture-related state
    private func clearCaptureState() {
        pendingExtraction = nil
        capturedScreenshotItem = nil
        llmGeneratedTitle = nil
        isLLMGenerated = false
        isProcessingCapture = false
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Tab button component with responsive text/icon display
struct TabButton: View {
    let tab: NavigationTab
    let isSelected: Bool
    let showText: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: showText ? CyberpunkTheme.spacingS : 0) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16))
                
                if showText {
                    Text(tab.rawValue)
                        .font(CyberpunkTheme.fontHeadline)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .foregroundColor(isSelected ? tab.color : CyberpunkTheme.textSecondary)
            .padding(.horizontal, showText ? CyberpunkTheme.spacingM : CyberpunkTheme.spacingS)
            .padding(.vertical, CyberpunkTheme.spacingS)
            .background(
                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                    .fill(isSelected ? tab.color.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                    .stroke(isSelected ? tab.color : Color.clear, lineWidth: 1)
            )
            .shadow(color: isSelected ? tab.color.opacity(0.3) : .clear, radius: CyberpunkTheme.glowRadiusSubtle)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(tab.rawValue)
    }
}

/// Small stat badge for the header
struct StatBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: CyberpunkTheme.spacingXS) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(value)
                .font(CyberpunkTheme.fontCaption)
        }
        .foregroundColor(color)
        .padding(.horizontal, CyberpunkTheme.spacingS)
        .padding(.vertical, CyberpunkTheme.spacingXS)
        .background(
            Capsule()
                .fill(color.opacity(0.2))
        )
    }
}

/// Helper to access the NSWindow from SwiftUI
struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if self.window == nil {
                self.window = nsView.window
            }
        }
    }
}
