import Foundation
import Combine

/// Protocol for task management operations
public protocol TaskManagerProtocol {
    func createTask(from extraction: TextExtraction, timeEstimate: TimeEstimate, priority: Priority) -> Task
    func createTask(from extraction: TextExtraction, timeEstimate: TimeEstimate, priority: Priority, screenshotId: UUID?, llmGeneratedTitle: Bool) -> Task
    func createTask(title: String, description: String, timeEstimate: TimeEstimate, priority: Priority) -> Task
    func updateTask(_ task: Task) -> Bool
    func deleteTask(id: UUID) -> Bool
    func softDeleteTask(_ task: Task)
    func permanentlyDeleteTask(id: UUID) -> Bool
    func getAllTasks() -> [Task]
    func getActiveTasks() -> [Task]
    func getKanbanTasks() -> [Task]
    func moveToKanban(_ task: Task, column: KanbanColumn)
    func moveFromKanban(_ task: Task)
    func markComplete(_ task: Task)
    func restoreFromDeleted(_ task: Task)
}

/// Manages task lifecycle with immediate persistence
public final class TaskManager: TaskManagerProtocol, ObservableObject {
    
    /// Published tasks for SwiftUI binding
    @Published public private(set) var tasks: [Task] = []
    
    private let persistenceManager: PersistenceManagerProtocol
    
    public init(persistenceManager: PersistenceManagerProtocol = PersistenceManager()) {
        self.persistenceManager = persistenceManager
        loadTasks()
    }
    
    // MARK: - Task Creation
    
    /// Create a task from screen capture extraction
    /// Defaults: 20 minutes, Medium priority (per Req 3.5)
    public func createTask(
        from extraction: TextExtraction,
        timeEstimate: TimeEstimate = .twenty,
        priority: Priority = .medium
    ) -> Task {
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
        from extraction: TextExtraction,
        timeEstimate: TimeEstimate = .twenty,
        priority: Priority = .medium,
        screenshotId: UUID? = nil,
        llmGeneratedTitle: Bool = false
    ) -> Task {
        let title = extraction.subject ?? String(extraction.rawText.prefix(50))
        
        var metadata = extraction.toMetadata()
        metadata.llmGeneratedTitle = llmGeneratedTitle
        
        let task = Task(
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
        timeEstimate: TimeEstimate = .twenty,
        priority: Priority = .medium
    ) -> Task {
        let task = Task(
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
    public func updateTask(_ task: Task) -> Bool {
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
    public func getAllTasks() -> [Task] {
        return tasks
    }
    
    /// Get active tasks (excludes Kanban, completed, and deleted tasks)
    /// Used for Pomodoro session prioritization (per Req 5.3)
    public func getActiveTasks() -> [Task] {
        return tasks.filter { task in
            task.kanbanColumn == nil && 
            task.status != .completed && 
            task.status != .deleted
        }
    }
    
    /// Get tasks on the Kanban board (excludes deleted column by default)
    public func getKanbanTasks() -> [Task] {
        return tasks.filter { $0.kanbanColumn != nil && $0.kanbanColumn != .deleted }
    }
    
    /// Get all Kanban tasks including deleted
    public func getAllKanbanTasks() -> [Task] {
        return tasks.filter { $0.kanbanColumn != nil }
    }
    
    /// Get deleted tasks
    public func getDeletedTasks() -> [Task] {
        return tasks.filter { $0.status == .deleted || $0.kanbanColumn == .deleted }
    }
    
    /// Get tasks by Kanban column
    public func getTasks(inColumn column: KanbanColumn) -> [Task] {
        return tasks.filter { $0.kanbanColumn == column }
    }
    
    // MARK: - Kanban Operations
    
    /// Move a task to the Kanban board (per Req 5.1)
    public func moveToKanban(_ task: Task, column: KanbanColumn) {
        var updatedTask = task
        updatedTask.kanbanColumn = column
        updatedTask.status = .deferred
        updatedTask.updatedAt = Date()
        updateTask(updatedTask)
    }
    
    /// Move a task from Kanban back to the active task list (per Req 5.4)
    public func moveFromKanban(_ task: Task) {
        var updatedTask = task
        updatedTask.kanbanColumn = nil
        updatedTask.status = .pending
        updatedTask.updatedAt = Date()
        updateTask(updatedTask)
    }
    
    /// Move a task between Kanban columns
    public func moveKanbanColumn(_ task: Task, to column: KanbanColumn) {
        var updatedTask = task
        updatedTask.kanbanColumn = column
        updatedTask.updatedAt = Date()
        updateTask(updatedTask)
    }
    
    /// Mark a task as complete
    /// Per Requirement 5.6: Moves to Done column on Kanban
    public func markComplete(_ task: Task) {
        var updatedTask = task
        updatedTask.status = .completed
        updatedTask.kanbanColumn = .done  // Always move to Done column
        updatedTask.updatedAt = Date()
        updateTask(updatedTask)
    }
    
    /// Soft delete a task (moves to Deleted column)
    /// Per Requirement 5.7
    public func softDeleteTask(_ task: Task) {
        var updatedTask = task
        updatedTask.status = .deleted
        updatedTask.kanbanColumn = .deleted
        updatedTask.updatedAt = Date()
        updateTask(updatedTask)
    }
    
    /// Restore a task from deleted state
    public func restoreFromDeleted(_ task: Task) {
        var updatedTask = task
        updatedTask.status = .pending
        updatedTask.kanbanColumn = .backlog
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
    private func saveAndRefresh(_ task: Task) {
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
}
