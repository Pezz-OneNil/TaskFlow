import XCTest
@testable import TaskFlowLib

/// **Feature: task-flow-app, Property 4: Task Field Bounds**
/// *For any* task, the timeEstimate SHALL be one of (10, 20, 40, 60, 90) minutes
/// AND the priority SHALL be one of (low=1, medium=2, mega=3).
/// **Validates: Requirements 3.1, 3.2**
final class TaskFieldBoundsTests: XCTestCase {
    
    private final class MockPersistenceManager: PersistenceManagerProtocol {
        private var storedTasks: [UUID: Task] = [:]
        
        func save(_ task: Task) throws {
            storedTasks[task.id] = task
        }
        
        func save(_ tasks: [Task]) throws {
            for task in tasks {
                storedTasks[task.id] = task
            }
        }
        
        func loadAllTasks() throws -> [Task] {
            Array(storedTasks.values)
        }
        
        func delete(taskId: UUID) throws {
            storedTasks.removeValue(forKey: taskId)
        }
        
        func createBackup() throws {}
        
        func restoreFromBackup() throws -> [Task] {
            Array(storedTasks.values)
        }
    }
    
    // MARK: - Random Generators
    
    private func randomTimeEstimate() -> TimeEstimate {
        TimeEstimate.allCases.randomElement()!
    }
    
    private func randomPriority() -> Priority {
        Priority.allCases.randomElement()!
    }
    
    private func randomTaskStatus() -> TaskStatus {
        TaskStatus.allCases.randomElement()!
    }
    
    private func randomKanbanColumn() -> KanbanColumn? {
        Bool.random() ? KanbanColumn.allCases.randomElement() : nil
    }
    
    private func randomString(length: Int = 10) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    private func randomTask() -> Task {
        Task(
            title: randomString(),
            description: randomString(length: 20),
            sourceContent: randomString(length: 50),
            timeEstimate: randomTimeEstimate(),
            priority: randomPriority(),
            status: randomTaskStatus(),
            kanbanColumn: randomKanbanColumn()
        )
    }
    
    // MARK: - Property Tests (100 iterations each)
    
    /// Property 4: Task Field Bounds - TimeEstimate values
    func testTimeEstimateIsValidEnumValue() {
        let validValues: Set<Int> = [10, 20, 40, 60, 90]
        
        for _ in 1...100 {
            let task = randomTask()
            XCTAssertTrue(validValues.contains(task.timeEstimate.rawValue),
                         "TimeEstimate \(task.timeEstimate.rawValue) is not valid")
        }
    }
    
    /// Property 4: Task Field Bounds - Priority values
    func testPriorityIsValidEnumValue() {
        let validValues: Set<Int> = [1, 2, 3]
        
        for _ in 1...100 {
            let task = randomTask()
            XCTAssertTrue(validValues.contains(task.priority.rawValue),
                         "Priority \(task.priority.rawValue) is not valid")
        }
    }
    
    /// Combined property test for both bounds
    func testTaskFieldBoundsProperty() {
        let validTimeEstimates: Set<Int> = [10, 20, 40, 60, 90]
        let validPriorities: Set<Int> = [1, 2, 3]
        
        for _ in 1...100 {
            let task = randomTask()
            let timeValid = validTimeEstimates.contains(task.timeEstimate.rawValue)
            let priorityValid = validPriorities.contains(task.priority.rawValue)
            XCTAssertTrue(timeValid && priorityValid,
                         "Task bounds invalid: time=\(task.timeEstimate.rawValue), priority=\(task.priority.rawValue)")
        }
    }
    
    // MARK: - Unit Tests
    
    func testTimeEstimateHasAllExpectedCases() {
        let expected: Set<Int> = [10, 20, 40, 60, 90]
        let actual = Set(TimeEstimate.allCases.map { $0.rawValue })
        XCTAssertEqual(expected, actual)
    }
    
    func testPriorityHasAllExpectedCases() {
        let expected: Set<Int> = [1, 2, 3]
        let actual = Set(Priority.allCases.map { $0.rawValue })
        XCTAssertEqual(expected, actual)
    }
    
    func testPriorityOrderingIsCorrect() {
        XCTAssertLessThan(Priority.low, Priority.medium)
        XCTAssertLessThan(Priority.medium, Priority.mega)
    }

    func testTaskManagerDefaultCreateTaskValues() {
        let taskManager = TaskManager(persistenceManager: MockPersistenceManager())
        let task = taskManager.createTask(title: "Default Task")
        
        XCTAssertEqual(task.timeEstimate, .twenty)
        XCTAssertEqual(task.priority, .medium)
    }
}
