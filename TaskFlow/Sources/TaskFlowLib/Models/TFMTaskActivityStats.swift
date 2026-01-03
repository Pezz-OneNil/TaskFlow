import Foundation

/// Statistics for task activity on a specific date
/// Per Requirements 6.1, 6.2
public struct TFMTaskActivityStats: Equatable {
    /// The date these stats are for (at day granularity)
    public let date: Date
    
    /// Number of tasks created on this date
    public let tasksAdded: Int
    
    /// Number of tasks completed on this date
    public let tasksCompleted: Int
    
    public init(date: Date, tasksAdded: Int, tasksCompleted: Int) {
        self.date = date
        self.tasksAdded = tasksAdded
        self.tasksCompleted = tasksCompleted
    }
    
    /// Returns true if there is any activity on this date
    public var hasActivity: Bool {
        tasksAdded > 0 || tasksCompleted > 0
    }
}

// MARK: - Backward Compatibility

@available(*, deprecated, renamed: "TFMTaskActivityStats")
public typealias TaskActivityStats = TFMTaskActivityStats
