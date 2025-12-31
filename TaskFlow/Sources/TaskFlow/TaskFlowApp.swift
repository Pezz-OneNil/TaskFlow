// ═══════════════════════════════════════════════════════════════════════════════
// TaskFlow - Intelligent Task Management for macOS
// © 2025 Pezz. All rights reserved.
//
// This software is protected by copyright law and international treaties.
// Unauthorized reproduction or distribution of this software, or any portion
// of it, may result in severe civil and criminal penalties.
// ═══════════════════════════════════════════════════════════════════════════════

import SwiftUI
import TaskFlowLib

@main
struct TaskFlowApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            MainWindowView(
                taskManager: appState.taskManager,
                pomodoroEngine: appState.pomodoroEngine,
                backupManager: appState.backupManager,
                screenshotManager: appState.screenshotManager,
                textExtractor: appState.textExtractor,
                llmSummarizer: appState.llmSummarizer
            )
            .preferredColorScheme(.dark)
            .onAppear {
                appState.initialize()
                setupMenuBar()
            }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Task") {
                    // TODO: Trigger new task creation
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Capture Screen") {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("MenuBarCaptureRequested"),
                        object: nil
                    )
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }
        }
    }
    
    private func setupMenuBar() {
        MenuBarManager.shared.setup {
            // Post notification to trigger capture from menu bar
            NotificationCenter.default.post(
                name: NSNotification.Name("MenuBarCaptureRequested"),
                object: nil
            )
        }
    }
}

/// Central app state management
class AppState: ObservableObject {
    let persistenceManager: PersistenceManager
    let taskManager: TaskManager
    let pomodoroEngine: PomodoroEngine
    let backupManager: BackupManager
    let permissionManager: PermissionManager
    let llmSummarizer: LLMSummarizer
    let screenshotManager: ScreenshotManager
    let textExtractor: TextExtractor
    
    init() {
        // Initialize database
        do {
            try DatabaseManager.shared.initialize()
        } catch {
            print("Failed to initialize database: \(error)")
        }
        
        // Create managers
        self.persistenceManager = PersistenceManager()
        self.taskManager = TaskManager(persistenceManager: persistenceManager)
        self.backupManager = BackupManager()
        self.permissionManager = PermissionManager()
        self.llmSummarizer = LLMSummarizer()
        self.screenshotManager = ScreenshotManager()
        self.textExtractor = TextExtractor()
        
        // Create Pomodoro engine with task manager
        let scheduler = PriorityScheduler()
        self.pomodoroEngine = PomodoroEngine(taskManager: taskManager, scheduler: scheduler)
        
        // Set up Pomodoro callbacks
        setupPomodoroCallbacks()
    }
    
    func initialize() {
        // Check permissions
        permissionManager.checkPermissions()
        
        // Start daily backup scheduler
        backupManager.startDailyBackupSchedule()
        
        // Validate and restore from backup if needed
        do {
            _ = try backupManager.validateAndRecover()
        } catch {
            print("Backup validation failed: \(error)")
        }
        
        // Pre-warm LLM model in background for faster first capture
        _Concurrency.Task {
            await llmSummarizer.warmup()
        }
    }
    
    private func setupPomodoroCallbacks() {
        pomodoroEngine.onSessionExpired = {
            // TODO: Show notification
            print("Pomodoro session expired")
        }
        
        pomodoroEngine.onTaskCompleted = { task in
            print("Task completed: \(task.title)")
        }
    }
}
