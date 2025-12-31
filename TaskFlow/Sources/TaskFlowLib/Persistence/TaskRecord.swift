import Foundation
import GRDB

/// GRDB record for Task persistence
struct TaskRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "tasks"
    
    var id: String
    var title: String
    var description: String?
    var sourceContent: String?
    var furtherDetails: String?
    var screenshotId: String?
    var assignedTo: String?
    var timeEstimate: Int
    var priority: Int
    var status: String
    var kanbanColumn: String?
    var createdAt: String
    var updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case sourceContent = "source_content"
        case furtherDetails = "further_details"
        case screenshotId = "screenshot_id"
        case assignedTo = "assigned_to"
        case timeEstimate = "time_estimate"
        case priority
        case status
        case kanbanColumn = "kanban_column"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Convert from domain Task model
    init(from task: Task) {
        self.id = task.id.uuidString
        self.title = task.title
        self.description = task.description.isEmpty ? nil : task.description
        self.sourceContent = task.sourceContent.isEmpty ? nil : task.sourceContent
        self.furtherDetails = task.furtherDetails.isEmpty ? nil : task.furtherDetails
        self.screenshotId = task.screenshotId?.uuidString
        self.assignedTo = task.assignedTo
        self.timeEstimate = task.timeEstimate.rawValue
        self.priority = task.priority.rawValue
        self.status = task.status.rawValue
        self.kanbanColumn = task.kanbanColumn?.rawValue
        self.createdAt = ISO8601DateFormatter().string(from: task.createdAt)
        self.updatedAt = ISO8601DateFormatter().string(from: task.updatedAt)
    }
    
    /// Convert to domain Task model (requires metadata)
    func toTask(with metadata: TaskMetadataRecord?) -> Task? {
        guard let uuid = UUID(uuidString: id),
              let timeEst = TimeEstimate(rawValue: timeEstimate),
              let prio = Priority(rawValue: priority),
              let stat = TaskStatus(rawValue: status),
              let created = ISO8601DateFormatter().date(from: createdAt),
              let updated = ISO8601DateFormatter().date(from: updatedAt) else {
            return nil
        }
        
        let kanban = kanbanColumn.flatMap { KanbanColumn(rawValue: $0) }
        let taskMetadata = metadata?.toTaskMetadata() ?? TaskMetadata()
        let ssId = screenshotId.flatMap { UUID(uuidString: $0) }
        
        return Task(
            id: uuid,
            title: title,
            description: description ?? "",
            sourceContent: sourceContent ?? "",
            furtherDetails: furtherDetails ?? "",
            screenshotId: ssId,
            assignedTo: assignedTo,
            timeEstimate: timeEst,
            priority: prio,
            status: stat,
            kanbanColumn: kanban,
            createdAt: created,
            updatedAt: updated,
            metadata: taskMetadata
        )
    }
}

/// GRDB record for TaskMetadata persistence
struct TaskMetadataRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "task_metadata"
    
    var taskId: String
    var sender: String?
    var recipient: String?
    var subject: String?
    var sourceApp: String?
    var capturedAt: String?
    var keywords: String? // JSON array
    var llmGeneratedTitle: Int
    
    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case sender
        case recipient
        case subject
        case sourceApp = "source_app"
        case capturedAt = "captured_at"
        case keywords
        case llmGeneratedTitle = "llm_generated_title"
    }
    
    /// Convert from domain TaskMetadata model
    init(taskId: UUID, from metadata: TaskMetadata) {
        self.taskId = taskId.uuidString
        self.sender = metadata.sender
        self.recipient = metadata.recipient
        self.subject = metadata.subject
        self.sourceApp = metadata.sourceApp
        self.capturedAt = metadata.capturedAt.map { ISO8601DateFormatter().string(from: $0) }
        self.llmGeneratedTitle = metadata.llmGeneratedTitle ? 1 : 0
        
        // Encode keywords as JSON array
        if !metadata.keywords.isEmpty {
            self.keywords = try? String(data: JSONEncoder().encode(metadata.keywords), encoding: .utf8)
        } else {
            self.keywords = nil
        }
    }
    
    /// Convert to domain TaskMetadata model
    func toTaskMetadata() -> TaskMetadata {
        let capturedDate = capturedAt.flatMap { ISO8601DateFormatter().date(from: $0) }
        
        // Decode keywords from JSON
        var keywordList: [String] = []
        if let keywordsJson = keywords,
           let data = keywordsJson.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            keywordList = decoded
        }
        
        return TaskMetadata(
            sender: sender,
            recipient: recipient,
            subject: subject,
            sourceApp: sourceApp,
            capturedAt: capturedDate,
            keywords: keywordList,
            llmGeneratedTitle: llmGeneratedTitle == 1
        )
    }
}

/// GRDB record for Screenshot persistence
public struct ScreenshotRecord: Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "screenshots"
    
    public var id: String
    public var filePath: String
    public var capturedAt: String
    public var originalWidth: Int
    public var originalHeight: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case filePath = "file_path"
        case capturedAt = "captured_at"
        case originalWidth = "original_width"
        case originalHeight = "original_height"
    }
    
    public init(id: UUID, filePath: String, capturedAt: Date, width: Int, height: Int) {
        self.id = id.uuidString
        self.filePath = filePath
        self.capturedAt = ISO8601DateFormatter().string(from: capturedAt)
        self.originalWidth = width
        self.originalHeight = height
    }
}
