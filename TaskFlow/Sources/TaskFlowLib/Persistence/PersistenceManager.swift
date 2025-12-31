import Foundation
import GRDB

/// Protocol for persistence operations
public protocol PersistenceManagerProtocol {
    func save(_ task: Task) throws
    func save(_ tasks: [Task]) throws
    func loadAllTasks() throws -> [Task]
    func delete(taskId: UUID) throws
    func createBackup() throws
    func restoreFromBackup() throws -> [Task]
}

/// Manages task persistence with immediate writes and retry logic
public final class PersistenceManager: PersistenceManagerProtocol {
    
    private let databaseManager: DatabaseManager
    private let maxRetries = 3
    
    public init(databaseManager: DatabaseManager = .shared) {
        self.databaseManager = databaseManager
    }
    
    /// Save a single task with immediate persistence
    public func save(_ task: Task) throws {
        try withRetry {
            let pool = try self.databaseManager.getPool()
            try pool.write { db in
                try self.saveTask(task, in: db)
            }
        }
    }
    
    /// Save multiple tasks with immediate persistence
    public func save(_ tasks: [Task]) throws {
        try withRetry {
            let pool = try self.databaseManager.getPool()
            try pool.write { db in
                for task in tasks {
                    try self.saveTask(task, in: db)
                }
            }
        }
    }
    
    /// Load all tasks from database
    public func loadAllTasks() throws -> [Task] {
        let pool = try databaseManager.getPool()
        
        return try pool.read { db in
            let taskRecords = try TaskRecord.fetchAll(db)
            
            return try taskRecords.compactMap { taskRecord -> Task? in
                let metadataRecord = try TaskMetadataRecord
                    .filter(Column("task_id") == taskRecord.id)
                    .fetchOne(db)
                return taskRecord.toTask(with: metadataRecord)
            }
        }
    }
    
    /// Delete a task by ID
    public func delete(taskId: UUID) throws {
        try withRetry {
            let pool = try self.databaseManager.getPool()
            _ = try pool.write { db in
                // Metadata is deleted automatically via CASCADE
                try TaskRecord
                    .filter(Column("id") == taskId.uuidString)
                    .deleteAll(db)
            }
        }
    }
    
    /// Create a backup (delegates to BackupManager)
    public func createBackup() throws {
        // This will be implemented by BackupManager
        // For now, just ensure data is persisted
        _ = try loadAllTasks()
    }
    
    /// Restore from backup (delegates to BackupManager)
    public func restoreFromBackup() throws -> [Task] {
        // This will be implemented by BackupManager
        return try loadAllTasks()
    }
    
    // MARK: - Private Helpers
    
    /// Save task and metadata in a single transaction
    private func saveTask(_ task: Task, in db: Database) throws {
        let taskRecord = TaskRecord(from: task)
        try taskRecord.save(db)
        
        let metadataRecord = TaskMetadataRecord(taskId: task.id, from: task.metadata)
        try metadataRecord.save(db)
    }
    
    /// Execute operation with retry logic
    private func withRetry(_ operation: () throws -> Void) throws {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                try operation()
                return
            } catch {
                lastError = error
                if attempt < maxRetries {
                    // Brief delay before retry
                    Thread.sleep(forTimeInterval: 0.1 * Double(attempt))
                }
            }
        }
        
        if let error = lastError {
            throw DatabaseError.saveFailed("Failed after \(maxRetries) attempts: \(error.localizedDescription)")
        }
    }
}
