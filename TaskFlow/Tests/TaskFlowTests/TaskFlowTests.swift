import XCTest
@testable import TaskFlowLib

/// TaskFlow Basic Tests
final class TaskFlowTests: XCTestCase {
    
    // MARK: - PriorityScheduler Tests
    
    func testPrioritySchedulerOrdersByPriority() {
        let scheduler = PriorityScheduler()
        
        let lowTask = Task(title: "Low", timeEstimate: .twenty, priority: .low)
        let mediumTask = Task(title: "Medium", timeEstimate: .twenty, priority: .medium)
        let megaTask = Task(title: "Mega", timeEstimate: .twenty, priority: .mega)
        
        let tasks = [lowTask, mediumTask, megaTask]
        let sorted = scheduler.sortByPriority(tasks)
        
        XCTAssertEqual(sorted[0].priority, .mega)
        XCTAssertEqual(sorted[1].priority, .medium)
        XCTAssertEqual(sorted[2].priority, .low)
    }
    
    func testPrioritySchedulerOrdersByTimeWithinPriority() {
        let scheduler = PriorityScheduler()
        
        let longTask = Task(title: "Long", timeEstimate: .sixty, priority: .medium)
        let shortTask = Task(title: "Short", timeEstimate: .ten, priority: .medium)
        let mediumTask = Task(title: "Medium", timeEstimate: .forty, priority: .medium)
        
        let tasks = [longTask, shortTask, mediumTask]
        let sorted = scheduler.sortByPriority(tasks)
        
        XCTAssertEqual(sorted[0].timeEstimate, .ten)
        XCTAssertEqual(sorted[1].timeEstimate, .forty)
        XCTAssertEqual(sorted[2].timeEstimate, .sixty)
    }
    
    func testPrioritySchedulerFiltersExceedingTime() {
        let scheduler = PriorityScheduler()
        
        let shortTask = Task(title: "Short", timeEstimate: .ten, priority: .medium)
        let longTask = Task(title: "Long", timeEstimate: .sixty, priority: .mega)
        
        let tasks = [shortTask, longTask]
        // 30 minutes remaining (1800 seconds)
        let filtered = scheduler.prioritizeTasks(tasks, remainingTime: 1800)
        
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].title, "Short")
    }
    
    // MARK: - Task Default Values Tests
    
    func testTaskDefaultValues() {
        let task = Task(title: "Test Task")
        
        XCTAssertEqual(task.timeEstimate, .twenty)
        XCTAssertEqual(task.priority, .medium)
        XCTAssertEqual(task.status, .pending)
        XCTAssertNil(task.kanbanColumn)
    }
}
