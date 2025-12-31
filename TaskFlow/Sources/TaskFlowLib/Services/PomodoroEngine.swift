import Foundation
import Combine

/// Protocol for Pomodoro timer functionality
public protocol PomodoroEngineProtocol: ObservableObject {
    var remainingTime: TimeInterval { get }
    var isRunning: Bool { get }
    var isPaused: Bool { get }
    var currentTask: Task? { get }
    var upcomingTasks: [Task] { get }
    var sessionDuration: TimeInterval { get }
    
    func startSession(duration: TimeInterval)
    func pauseSession()
    func resumeSession()
    func stopSession()
    func completeCurrentTask()
    func skipCurrentTask()
}

/// Pomodoro timer engine that manages timed work sessions
/// Integrates with PriorityScheduler for automatic task ordering
/// Per Requirements 4.1, 4.4, 4.5, 4.6
public final class PomodoroEngine: ObservableObject, PomodoroEngineProtocol {
    
    // MARK: - Published Properties
    
    @Published public private(set) var remainingTime: TimeInterval = 0
    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var isPaused: Bool = false
    @Published public private(set) var currentTask: Task?
    @Published public private(set) var upcomingTasks: [Task] = []
    @Published public private(set) var sessionDuration: TimeInterval = 0
    
    // MARK: - Dependencies
    
    private let taskManager: TaskManager
    private let scheduler: PriorityScheduler
    
    // MARK: - Timer
    
    private var timer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Session State
    
    /// Tasks that have been skipped during this session (won't be shown again until session restarts)
    private var skippedTaskIds: Set<UUID> = []
    
    // MARK: - Callbacks
    
    /// Called when session expires
    public var onSessionExpired: (() -> Void)?
    
    /// Called when a task is completed
    public var onTaskCompleted: ((Task) -> Void)?
    
    /// Called when advancing to next task
    public var onTaskAdvanced: ((Task?) -> Void)?
    
    // MARK: - Initialization
    
    public init(taskManager: TaskManager, scheduler: PriorityScheduler = PriorityScheduler()) {
        self.taskManager = taskManager
        self.scheduler = scheduler
    }
    
    // MARK: - Session Control
    
    /// Start a new Pomodoro session with specified duration
    /// Per Requirement 4.1
    public func startSession(duration: TimeInterval) {
        stopSession() // Clean up any existing session
        
        sessionDuration = duration
        remainingTime = duration
        isRunning = true
        isPaused = false
        skippedTaskIds = [] // Clear skipped tasks for new session
        
        // Get prioritized tasks
        refreshTaskQueue()
        
        // Advance to first task
        advanceToNextTask()
        
        // Start timer
        startTimer()
    }
    
    /// Pause the current session
    public func pauseSession() {
        guard isRunning && !isPaused else { return }
        isPaused = true
        timer?.cancel()
        timer = nil
    }
    
    /// Resume a paused session
    public func resumeSession() {
        guard isRunning && isPaused else { return }
        isPaused = false
        startTimer()
    }
    
    /// Stop the current session completely
    public func stopSession() {
        timer?.cancel()
        timer = nil
        isRunning = false
        isPaused = false
        remainingTime = 0
        sessionDuration = 0
        currentTask = nil
        upcomingTasks = []
        skippedTaskIds = []
    }
    
    // MARK: - Task Progression
    
    /// Complete the current task and advance to next
    /// Per Requirement 4.4
    public func completeCurrentTask() {
        guard let task = currentTask else { return }
        
        // Mark task as completed
        taskManager.markComplete(task)
        onTaskCompleted?(task)
        
        // Advance to next task
        advanceToNextTask()
    }
    
    /// Skip the current task without completing and advance to next
    public func skipCurrentTask() {
        guard let task = currentTask else { return }
        
        // Add to skipped set so it won't appear again this session
        skippedTaskIds.insert(task.id)
        
        // Advance to next task
        advanceToNextTask()
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    private func tick() {
        guard isRunning && !isPaused else { return }
        
        remainingTime -= 1
        
        if remainingTime <= 0 {
            handleSessionExpired()
        }
    }
    
    private func handleSessionExpired() {
        // Per Requirement 4.5: pause and notify when session expires
        pauseSession()
        remainingTime = 0
        onSessionExpired?()
    }
    
    private func refreshTaskQueue() {
        // Get tasks from Kanban backlog, in progress, and blocked columns
        // Per user requirement: Pomodoro pulls from Kanban columns, not active tasks
        var kanbanTasks: [Task] = []
        kanbanTasks.append(contentsOf: taskManager.getTasks(inColumn: .backlog))
        kanbanTasks.append(contentsOf: taskManager.getTasks(inColumn: .inProgress))
        kanbanTasks.append(contentsOf: taskManager.getTasks(inColumn: .blocked))
        
        // Filter out skipped tasks
        kanbanTasks = kanbanTasks.filter { !skippedTaskIds.contains($0.id) }
        
        // Sort by priority (Mega > Medium > Low) using the scheduler
        upcomingTasks = scheduler.prioritizeTasks(kanbanTasks, remainingTime: remainingTime)
    }
    
    private func advanceToNextTask() {
        // Refresh queue with current remaining time
        refreshTaskQueue()
        
        // Get next task that fits
        currentTask = upcomingTasks.first
        
        // Remove current from upcoming
        if currentTask != nil {
            upcomingTasks = Array(upcomingTasks.dropFirst())
        }
        
        onTaskAdvanced?(currentTask)
    }
    
    // MARK: - Utility
    
    /// Get tasks from Kanban columns for Pomodoro session
    private func getKanbanTasksForPomodoro() -> [Task] {
        var kanbanTasks: [Task] = []
        kanbanTasks.append(contentsOf: taskManager.getTasks(inColumn: .backlog))
        kanbanTasks.append(contentsOf: taskManager.getTasks(inColumn: .inProgress))
        kanbanTasks.append(contentsOf: taskManager.getTasks(inColumn: .blocked))
        return kanbanTasks
    }
    
    /// Get estimated number of tasks that can fit in remaining time
    public func estimatedTaskCount() -> Int {
        let kanbanTasks = getKanbanTasksForPomodoro()
        let fitting = scheduler.tasksThatFit(in: remainingTime > 0 ? remainingTime : sessionDuration, from: kanbanTasks)
        return fitting.count
    }
    
    /// Get total time of tasks that fit in remaining session
    public func estimatedWorkTime() -> TimeInterval {
        let kanbanTasks = getKanbanTasksForPomodoro()
        let fitting = scheduler.tasksThatFit(in: remainingTime > 0 ? remainingTime : sessionDuration, from: kanbanTasks)
        return scheduler.totalTime(for: fitting)
    }
}
