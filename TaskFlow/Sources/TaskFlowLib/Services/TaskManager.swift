import Foundation
import Combine

/// Protocol for task management operations
public protocol TFMTaskManagerProtocol {
    func createTask(from extraction: TFMTextExtraction, timeEstimate: TFMTimeEstimate, priority: TFMPriority) -> TFMTask
    func createTask(from extraction: TFMTextExtraction, timeEstimate: TFMTimeEstimate, priority: TFMPriority, screenshotId: UUID?, llmGeneratedTitle: Bool) -> TFMTask
    func createTask(title: String, description: String, timeEstimate: TFMTimeEstimate, priority: TFMPriority) -> TFMTask
    func updateTask(_ task: TFMTask) -> Bool
    func deleteTask(id: UUID) -> Bool
    func softDeleteTask(_ task: TFMTask)
    func permanentlyDeleteTask(id: UUID) -> Bool
    func getAllTasks() -> [TFMTask]
    func getActiveTasks() -> [TFMTask]
    func getKanbanTasks() -> [TFMTask]
    func moveToKanban(_ task: TFMTask, column: TFMKanbanColumn)
    func moveFromKanban(_ task: TFMTask)
    func markComplete(_ task: TFMTask)
    func restoreFromDeleted(_ task: TFMTask)
}

/// Manages task lifecycle with immediate persistence
public final class TFMTaskManager: TFMTaskManagerProtocol, ObservableObject {
    
    /// Published tasks for SwiftUI binding
    @Published public private(set) var tasks: [TFMTask] = []
    
    private let persistenceManager: TFMPersistenceManagerProtocol
    
    public init(persistenceManager: TFMPersistenceManagerProtocol = PersistenceManager()) {
        self.persistenceManager = persistenceManager
        loadTasks()
    }
    
    // MARK: - Task Creation
    
    /// Create a task from screen capture extraction
    /// Defaults: 20 minutes, Medium priority (per Req 3.5)
    public func createTask(
        from extraction: TFMTextExtraction,
        timeEstimate: TFMTimeEstimate = .twenty,
        priority: TFMPriority = .medium
    ) -> TFMTask {
        return createTask(
            from: extraction,
            timeEstimate: timeEstimate,
            priority: priority,
            screenshotId: nil,
            llmGeneratedTitle: false
        )
    }
    
    /// Create a task from screen capture with screenshot and LLM title info
    /// Per Requirements 2A.1, 2B.2
    public func createTask(
        from extraction: TFMTextExtraction,
        timeEstimate: TFMTimeEstimate = .twenty,
        priority: TFMPriority = .medium,
        screenshotId: UUID? = nil,
        llmGeneratedTitle: Bool = false
    ) -> TFMTask {
        let title = extraction.subject ?? String(extraction.rawText.prefix(50))
        
        var metadata = extraction.toMetadata()
        metadata.llmGeneratedTitle = llmGeneratedTitle
        
        let task = TFMTask(
            title: title,
            description: extraction.bodyContent,
            sourceContent: extraction.rawText,
            furtherDetails: extraction.rawText,  // Store full OCR text for editing
            screenshotId: screenshotId,
            timeEstimate: timeEstimate,
            priority: priority,
            status: .pending,
            metadata: metadata
        )
        
        saveAndRefresh(task)
        return task
    }
    
    /// Create a task manually with title and description
    /// Defaults: 20 minutes, Medium priority (per Req 3.5)
    public func createTask(
        title: String,
        description: String = "",
        timeEstimate: TFMTimeEstimate = .twenty,
        priority: TFMPriority = .medium
    ) -> TFMTask {
        let task = TFMTask(
            title: title,
            description: description,
            timeEstimate: timeEstimate,
            priority: priority,
            status: .pending
        )
        
        saveAndRefresh(task)
        return task
    }
    
    // MARK: - Task Updates
    
    /// Update an existing task
    @discardableResult
    public func updateTask(_ task: TFMTask) -> Bool {
        var updatedTask = task
        updatedTask.updatedAt = Date()
        
        do {
            try persistenceManager.save(updatedTask)
            loadTasks()
            return true
        } catch {
            print("Failed to update task: \(error)")
            return false
        }
    }
    
    /// Delete a task by ID
    @discardableResult
    public func deleteTask(id: UUID) -> Bool {
        do {
            try persistenceManager.delete(taskId: id)
            loadTasks()
            return true
        } catch {
            print("Failed to delete task: \(error)")
            return false
        }
    }
    
    // MARK: - Task Retrieval
    
    /// Get all tasks
    public func getAllTasks() -> [TFMTask] {
        return tasks
    }
    
    /// Get active tasks (excludes Kanban, completed, and deleted tasks)
    /// Used for Pomodoro session prioritization (per Req 5.3)
    public func getActiveTasks() -> [TFMTask] {
        return tasks.filter { task in
            task.kanbanColumn == nil && 
            task.status != .completed && 
            task.status != .deleted
        }
    }
    
    /// Get tasks on the Kanban board (excludes deleted column by default)
    public func getKanbanTasks() -> [TFMTask] {
        return tasks.filter { $0.kanbanColumn != nil && $0.kanbanColumn != .deleted }
    }
    
    /// Get all Kanban tasks including deleted
    public func getAllKanbanTasks() -> [TFMTask] {
        return tasks.filter { $0.kanbanColumn != nil }
    }
    
    /// Get deleted tasks
    public func getDeletedTasks() -> [TFMTask] {
        return tasks.filter { $0.status == .deleted || $0.kanbanColumn == .deleted }
    }
    
    /// Get tasks by Kanban column
    public func getTasks(inColumn column: TFMKanbanColumn) -> [TFMTask] {
        return tasks.filter { $0.kanbanColumn == column }
    }
    
    // MARK: - Kanban Operations
    
    /// Move a task to the Kanban board (per Req 5.1)
    public func moveToKanban(_ task: TFMTask, column: TFMKanbanColumn) {
        var updatedTask = task
        updatedTask.kanbanColumn = column
        updatedTask.status = .deferred
        updatedTask.updatedAt = Date()
        updateTask(updatedTask)
    }
    
    /// Move a task from Kanban back to the active task list (per Req 5.4)
    public func moveFromKanban(_ task: TFMTask) {
        var updatedTask = task
        updatedTask.kanbanColumn = nil
        updatedTask.status = .pending
        updatedTask.updatedAt = Date()
        updateTask(updatedTask)
    }
    
    /// Move a task between Kanban columns
    public func moveKanbanColumn(_ task: TFMTask, to column: TFMKanbanColumn) {
        var updatedTask = task
        updatedTask.kanbanColumn = column
        updatedTask.updatedAt = Date()
        updateTask(updatedTask)
    }
    
    /// Mark a task as complete
    /// Per Requirement 5.6: Moves to Done column on Kanban
    public func markComplete(_ task: TFMTask) {
        var updatedTask = task
        updatedTask.status = .completed
        updatedTask.kanbanColumn = .done  // Always move to Done column
        updatedTask.updatedAt = Date()
        updateTask(updatedTask)
    }
    
    /// Soft delete a task (moves to Deleted column)
    /// Per Requirement 5.7
    public func softDeleteTask(_ task: TFMTask) {
        var updatedTask = task
        updatedTask.status = .deleted
        updatedTask.kanbanColumn = .deleted
        updatedTask.updatedAt = Date()
        updateTask(updatedTask)
    }
    
    /// Restore a task from deleted state
    /// Returns task to active list (not Kanban) so it appears in Pomodoro prioritization
    public func restoreFromDeleted(_ task: TFMTask) {
        var updatedTask = task
        updatedTask.status = .pending
        updatedTask.kanbanColumn = nil  // Clear kanban column to return to active list
        updatedTask.updatedAt = Date()
        updateTask(updatedTask)
    }
    
    /// Permanently delete a task (removes from database)
    @discardableResult
    public func permanentlyDeleteTask(id: UUID) -> Bool {
        return deleteTask(id: id)
    }
    
    // MARK: - Private Helpers
    
    /// Save task and refresh the task list
    private func saveAndRefresh(_ task: TFMTask) {
        do {
            try persistenceManager.save(task)
            loadTasks()
        } catch {
            print("Failed to save task: \(error)")
        }
    }
    
    /// Load all tasks from persistence
    private func loadTasks() {
        do {
            tasks = try persistenceManager.loadAllTasks()
        } catch {
            print("Failed to load tasks: \(error)")
            tasks = []
        }
    }
    
    /// Refresh tasks from persistence
    public func refresh() {
        loadTasks()
    }
    
    /// Reload tasks from persistence (alias for refresh, used after backup restoration)
    public func reloadTasks() {
        loadTasks()
    }
    
    // MARK: - Activity Stats (Annual Calendar)
    
    /// Get task activity statistics for a given year
    /// Returns a dictionary mapping dates to TFMTaskActivityStats
    /// Per Requirements 6.1, 6.2
    public func getActivityStats(for year: Int) -> [Date: TFMTaskActivityStats] {
        let calendar = Calendar.current
        var stats: [Date: TFMTaskActivityStats] = [:]
        
        // Track counts per day
        var addedCounts: [Date: Int] = [:]
        var completedCounts: [Date: Int] = [:]
        
        for task in tasks {
            // Count tasks added (by createdAt date)
            let createdComponents = calendar.dateComponents([.year, .month, .day], from: task.createdAt)
            if createdComponents.year == year,
               let normalizedCreated = calendar.date(from: createdComponents) {
                addedCounts[normalizedCreated, default: 0] += 1
            }
            
            // Count tasks completed (by updatedAt date when status is completed)
            if task.status == .completed {
                let updatedComponents = calendar.dateComponents([.year, .month, .day], from: task.updatedAt)
                if updatedComponents.year == year,
                   let normalizedUpdated = calendar.date(from: updatedComponents) {
                    completedCounts[normalizedUpdated, default: 0] += 1
                }
            }
        }
        
        // Combine into TFMTaskActivityStats
        let allDates = Set(addedCounts.keys).union(Set(completedCounts.keys))
        for date in allDates {
            let added = addedCounts[date] ?? 0
            let completed = completedCounts[date] ?? 0
            stats[date] = TFMTaskActivityStats(date: date, tasksAdded: added, tasksCompleted: completed)
        }
        
        return stats
    }
}


// MARK: - Backward Compatibility

@available(*, deprecated, renamed: "TFMTaskManagerProtocol")
public typealias TaskManagerProtocol = TFMTaskManagerProtocol

@available(*, deprecated, renamed: "TFMTaskManager")
public typealias TaskManager = TFMTaskManager
