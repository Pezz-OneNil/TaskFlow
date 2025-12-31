import XCTest
@testable import TaskFlowLib

/// Task Activity Stats Tests
/// Feature: annual-calendar
final class TaskActivityStatsTests: XCTestCase {
    
    // MARK: - Property 10: Task Activity Stats Accuracy
    // For any set of tasks with various creation dates and completion statuses,
    // getActivityStats(for year:) should return accurate counts matching the actual
    // number of tasks created and completed on each date.
    // **Validates: Requirements 6.1, 6.2**
    
    func testTaskActivityStatsAccuracyProperty() throws {
        // Initialize test database
        try DatabaseManager.shared.initializeInMemory()
        
        let persistenceManager = PersistenceManager()
        let taskManager = TaskManager(persistenceManager: persistenceManager)
        let calendar = Calendar.current
        
        // Property test: run 50 iterations (fewer due to task creation overhead)
        for iteration in 0..<50 {
            // Clear existing tasks
            for task in taskManager.getAllTasks() {
                taskManager.deleteTask(id: task.id)
            }
            
            // Generate random number of tasks (1-20)
            let taskCount = Int.random(in: 1...20)
            
            // Track expected counts
            var expectedAdded: [Date: Int] = [:]
            var expectedCompleted: [Date: Int] = [:]
            
            // Test year
            let testYear = 2026
            
            for _ in 0..<taskCount {
                // Random date in test year
                let month = Int.random(in: 1...12)
                let day = Int.random(in: 1...28)
                guard let createdDate = calendar.date(from: DateComponents(
                    year: testYear, month: month, day: day
                )) else { continue }
                
                // Normalize to day granularity
                let normalizedCreated = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: createdDate))!
                
                // Create task with specific createdAt date
                var task = Task(
                    title: "Test Task \(iteration)",
                    description: "Test",
                    createdAt: createdDate,
                    updatedAt: createdDate
                )
                
                // Track added count
                expectedAdded[normalizedCreated, default: 0] += 1
                
                // Randomly complete some tasks
                if Bool.random() {
                    // Random completion date (same or later in year)
                    let completionMonth = Int.random(in: month...12)
                    let completionDay = Int.random(in: 1...28)
                    guard let completedDate = calendar.date(from: DateComponents(
                        year: testYear, month: completionMonth, day: completionDay
                    )) else { continue }
                    
                    let normalizedCompleted = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: completedDate))!
                    
                    task.status = .completed
                    task.updatedAt = completedDate
                    
                    expectedCompleted[normalizedCompleted, default: 0] += 1
                }
                
                // Save task directly to persistence
                try persistenceManager.save(task)
            }
            
            // Reload tasks
            taskManager.refresh()
            
            // Get activity stats
            let stats = taskManager.getActivityStats(for: testYear)
            
            // Verify added counts
            for (date, expectedCount) in expectedAdded {
                let actualCount = stats[date]?.tasksAdded ?? 0
                XCTAssertEqual(actualCount, expectedCount, 
                    "Added count mismatch for \(date): expected \(expectedCount), got \(actualCount)")
            }
            
            // Verify completed counts
            for (date, expectedCount) in expectedCompleted {
                let actualCount = stats[date]?.tasksCompleted ?? 0
                XCTAssertEqual(actualCount, expectedCount,
                    "Completed count mismatch for \(date): expected \(expectedCount), got \(actualCount)")
            }
            
            // Verify no extra dates in stats
            for (date, stat) in stats {
                if stat.tasksAdded > 0 {
                    XCTAssertNotNil(expectedAdded[date], "Unexpected added count for \(date)")
                }
                if stat.tasksCompleted > 0 {
                    XCTAssertNotNil(expectedCompleted[date], "Unexpected completed count for \(date)")
                }
            }
        }
    }
    
    // MARK: - Unit Tests
    
    func testGetActivityStatsEmpty() throws {
        try DatabaseManager.shared.initializeInMemory()
        
        let persistenceManager = PersistenceManager()
        let taskManager = TaskManager(persistenceManager: persistenceManager)
        
        // Clear any existing tasks
        for task in taskManager.getAllTasks() {
            taskManager.deleteTask(id: task.id)
        }
        
        let stats = taskManager.getActivityStats(for: 2026)
        XCTAssertTrue(stats.isEmpty, "Stats should be empty when no tasks exist")
    }
    
    func testGetActivityStatsFiltersYear() throws {
        try DatabaseManager.shared.initializeInMemory()
        
        let persistenceManager = PersistenceManager()
        let taskManager = TaskManager(persistenceManager: persistenceManager)
        let calendar = Calendar.current
        
        // Clear existing tasks
        for task in taskManager.getAllTasks() {
            taskManager.deleteTask(id: task.id)
        }
        
        // Create task in 2025
        let date2025 = calendar.date(from: DateComponents(year: 2025, month: 6, day: 15))!
        let task2025 = Task(
            title: "2025 Task",
            createdAt: date2025,
            updatedAt: date2025
        )
        try persistenceManager.save(task2025)
        
        // Create task in 2026
        let date2026 = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        let task2026 = Task(
            title: "2026 Task",
            createdAt: date2026,
            updatedAt: date2026
        )
        try persistenceManager.save(task2026)
        
        taskManager.refresh()
        
        // Get stats for 2026 only
        let stats2026 = taskManager.getActivityStats(for: 2026)
        
        // Should only have 2026 task
        XCTAssertEqual(stats2026.count, 1)
        
        let normalizedDate = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: date2026))!
        XCTAssertEqual(stats2026[normalizedDate]?.tasksAdded, 1)
        
        // Clean up
        taskManager.deleteTask(id: task2025.id)
        taskManager.deleteTask(id: task2026.id)
    }
    
    func testGetActivityStatsCountsCompletedByUpdatedAt() throws {
        try DatabaseManager.shared.initializeInMemory()
        
        let persistenceManager = PersistenceManager()
        let taskManager = TaskManager(persistenceManager: persistenceManager)
        let calendar = Calendar.current
        
        // Clear existing tasks
        for task in taskManager.getAllTasks() {
            taskManager.deleteTask(id: task.id)
        }
        
        // Create task on June 1, complete on June 15
        let createdDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let completedDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        
        let task = Task(
            title: "Test Task",
            status: .completed,
            createdAt: createdDate,
            updatedAt: completedDate
        )
        try persistenceManager.save(task)
        
        taskManager.refresh()
        
        let stats = taskManager.getActivityStats(for: 2026)
        
        let normalizedCreated = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: createdDate))!
        let normalizedCompleted = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: completedDate))!
        
        // Should have added on June 1
        XCTAssertEqual(stats[normalizedCreated]?.tasksAdded, 1)
        XCTAssertEqual(stats[normalizedCreated]?.tasksCompleted ?? 0, 0)
        
        // Should have completed on June 15
        XCTAssertEqual(stats[normalizedCompleted]?.tasksCompleted, 1)
        
        // Clean up
        taskManager.deleteTask(id: task.id)
    }
}
