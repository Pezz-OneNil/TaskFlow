import Foundation

/// Random generators for property-based testing
public struct TaskGenerators {
    
    public static func randomTimeEstimate() -> TimeEstimate {
        TimeEstimate.allCases.randomElement()!
    }
    
    public static func randomPriority() -> Priority {
        Priority.allCases.randomElement()!
    }
    
    public static func randomTaskStatus() -> TaskStatus {
        TaskStatus.allCases.randomElement()!
    }
    
    public static func randomKanbanColumn() -> KanbanColumn? {
        Bool.random() ? KanbanColumn.allCases.randomElement() : nil
    }
    
    public static func randomString(length: Int = 10) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    public static func randomTask() -> Task {
        Task(
            title: randomString(),
            description: randomString(length: 20),
            sourceContent: randomString(length: 50),
            furtherDetails: Bool.random() ? randomString(length: 100) : "",
            screenshotId: Bool.random() ? UUID() : nil,
            timeEstimate: randomTimeEstimate(),
            priority: randomPriority(),
            status: randomTaskStatus(),
            kanbanColumn: randomKanbanColumn()
        )
    }
    
    public static func randomMetadata() -> TaskMetadata {
        TaskMetadata(
            sender: Bool.random() ? randomString() : nil,
            recipient: Bool.random() ? randomString() : nil,
            subject: Bool.random() ? randomString(length: 30) : nil,
            sourceApp: Bool.random() ? ["Mail", "Teams", "Slack", "Calendar"].randomElement() : nil,
            capturedAt: Bool.random() ? Date() : nil,
            keywords: (0..<Int.random(in: 0...5)).map { _ in randomString(length: 6) },
            llmGeneratedTitle: Bool.random()
        )
    }
    
    public static func randomExtraction() -> TextExtraction {
        TextExtraction(
            rawText: randomString(length: 100),
            sender: Bool.random() ? randomString() : nil,
            recipient: Bool.random() ? randomString() : nil,
            subject: Bool.random() ? randomString(length: 30) : nil,
            bodyContent: randomString(length: 50),
            detectedApp: Bool.random() ? ["Mail", "Teams", "Slack", "Calendar"].randomElement() : nil,
            keywords: (0..<Int.random(in: 0...5)).map { _ in randomString(length: 6) }
        )
    }
}
