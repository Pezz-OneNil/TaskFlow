import Testing
@testable import TaskFlowLib

/// **Feature: task-flow-app, Property 4: Task Field Bounds**
/// *For any* task, the timeEstimate SHALL be one of (15, 30, 45, 60, 90) minutes
/// AND the priority SHALL be one of (low=1, medium=2, mega=3).
/// **Validates: Requirements 3.1, 3.2**
@Suite("Task Field Bounds Tests")
struct TaskFieldBoundsTests {
    
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
    @Test("TimeEstimate is valid enum value - 100 iterations")
    func timeEstimateIsValidEnumValue() {
        let validValues: Set<Int> = [15, 30, 45, 60, 90]
        
        for _ in 1...100 {
            let task = randomTask()
            #expect(validValues.contains(task.timeEstimate.rawValue))
        }
    }
    
    /// Property 4: Task Field Bounds - Priority values
    @Test("Priority is valid enum value - 100 iterations")
    func priorityIsValidEnumValue() {
        let validValues: Set<Int> = [1, 2, 3]
        
        for _ in 1...100 {
            let task = randomTask()
            #expect(validValues.contains(task.priority.rawValue))
        }
    }
    
    /// Combined property test for both bounds
    @Test("Task field bounds property - 100 iterations")
    func taskFieldBoundsProperty() {
        let validTimeEstimates: Set<Int> = [15, 30, 45, 60, 90]
        let validPriorities: Set<Int> = [1, 2, 3]
        
        for _ in 1...100 {
            let task = randomTask()
            let timeValid = validTimeEstimates.contains(task.timeEstimate.rawValue)
            let priorityValid = validPriorities.contains(task.priority.rawValue)
            #expect(timeValid && priorityValid)
        }
    }
    
    // MARK: - Unit Tests
    
    @Test("TimeEstimate has all expected cases")
    func timeEstimateAllCases() {
        let expected: Set<Int> = [15, 30, 45, 60, 90]
        let actual = Set(TimeEstimate.allCases.map { $0.rawValue })
        #expect(expected == actual)
    }
    
    @Test("Priority has all expected cases")
    func priorityAllCases() {
        let expected: Set<Int> = [1, 2, 3]
        let actual = Set(Priority.allCases.map { $0.rawValue })
        #expect(expected == actual)
    }
    
    @Test("Priority ordering is correct")
    func priorityOrdering() {
        #expect(Priority.low < Priority.medium)
        #expect(Priority.medium < Priority.mega)
    }
}
