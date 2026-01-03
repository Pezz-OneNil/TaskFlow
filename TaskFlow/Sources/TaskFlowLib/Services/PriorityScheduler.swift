import Foundation

/// Protocol for task prioritization
public protocol TFMPrioritySchedulerProtocol {
    func prioritizeTasks(_ tasks: [TFMTask], remainingTime: TimeInterval) -> [TFMTask]
    func getNextTask(from tasks: [TFMTask], remainingTime: TimeInterval) -> TFMTask?
}

/// Schedules tasks by priority and time estimate
/// Ordering: Priority descending (Mega > Medium > Low), then time ascending
public final class TFMPriorityScheduler: TFMPrioritySchedulerProtocol {
    
    public init() {}
    
    /// Prioritize tasks based on priority (desc) then time estimate (asc)
    /// Filters out tasks that exceed remaining time
    /// Per Requirements 4.2, 4.3
    public func prioritizeTasks(_ tasks: [TFMTask], remainingTime: TimeInterval) -> [TFMTask] {
        let remainingMinutes = Int(remainingTime / 60)
        
        return tasks
            // Filter tasks that fit in remaining time
            .filter { $0.timeEstimate.rawValue <= remainingMinutes }
            // Sort by priority descending, then time ascending
            .sorted { task1, task2 in
                if task1.priority != task2.priority {
                    // Higher priority first (mega=3 > medium=2 > low=1)
                    return task1.priority.rawValue > task2.priority.rawValue
                }
                // Same priority: shorter time first
                return task1.timeEstimate.rawValue < task2.timeEstimate.rawValue
            }
    }
    
    /// Get the next task that fits in remaining time
    /// Returns the highest priority task with shortest time estimate
    public func getNextTask(from tasks: [TFMTask], remainingTime: TimeInterval) -> TFMTask? {
        return prioritizeTasks(tasks, remainingTime: remainingTime).first
    }
    
    /// Get all tasks sorted by priority (without time filtering)
    /// Useful for displaying the full queue
    public func sortByPriority(_ tasks: [TFMTask]) -> [TFMTask] {
        return tasks.sorted { task1, task2 in
            if task1.priority != task2.priority {
                return task1.priority.rawValue > task2.priority.rawValue
            }
            return task1.timeEstimate.rawValue < task2.timeEstimate.rawValue
        }
    }
    
    /// Calculate total time for a list of tasks
    public func totalTime(for tasks: [TFMTask]) -> TimeInterval {
        return tasks.reduce(0) { total, task in
            total + TimeInterval(task.timeEstimate.rawValue * 60)
        }
    }
    
    /// Get tasks that fit within a time budget
    public func tasksThatFit(in timeInterval: TimeInterval, from tasks: [TFMTask]) -> [TFMTask] {
        let prioritized = sortByPriority(tasks)
        var result: [TFMTask] = []
        var remainingTime = timeInterval
        
        for task in prioritized {
            let taskTime = TimeInterval(task.timeEstimate.rawValue * 60)
            if taskTime <= remainingTime {
                result.append(task)
                remainingTime -= taskTime
            }
        }
        
        return result
    }
}

// MARK: - Backward Compatibility

@available(*, deprecated, renamed: "TFMPrioritySchedulerProtocol")
public typealias PrioritySchedulerProtocol = TFMPrioritySchedulerProtocol

@available(*, deprecated, renamed: "TFMPriorityScheduler")
public typealias PriorityScheduler = TFMPriorityScheduler
