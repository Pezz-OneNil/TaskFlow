import Foundation
import GRDB

/// Protocol for persistence operations
public protocol TFMPersistenceManagerProtocol {
    func save(_ task: TFMTask) throws
    func save(_ tasks: [TFMTask]) throws
    func loadAllTasks() throws -> [TFMTask]
    func delete(taskId: UUID) throws
    func createBackup() throws
    func restoreFromBackup() throws -> [TFMTask]
}

/// Manages task persistence with immediate writes and retry logic
public final class TFMPersistenceManager: TFMPersistenceManagerProtocol {
    
    private let databaseManager: TFMDatabaseManager
    private let maxRetries = 3
    
    public init(databaseManager: TFMDatabaseManager = .shared) {
        self.databaseManager = databaseManager
    }
    
    /// Save a single task with immediate persistence
    public func save(_ task: TFMTask) throws {
        try withRetry {
            let pool = try self.databaseManager.getPool()
            try pool.write { db in
                try self.saveTask(task, in: db)
            }
        }
    }
    
    /// Save multiple tasks with immediate persistence
    public func save(_ tasks: [TFMTask]) throws {
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
    public func loadAllTasks() throws -> [TFMTask] {
        let pool = try databaseManager.getPool()
        
        return try pool.read { db in
            let taskRecords = try TFMTaskRecord.fetchAll(db)
            
            return try taskRecords.compactMap { taskRecord -> TFMTask? in
                let metadataRecord = try TFMTaskMetadataRecord
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
                try TFMTaskRecord
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
    public func restoreFromBackup() throws -> [TFMTask] {
        // This will be implemented by BackupManager
        return try loadAllTasks()
    }
    
    // MARK: - Private Helpers
    
    /// Save task and metadata in a single transaction
    private func saveTask(_ task: TFMTask, in db: Database) throws {
        let taskRecord = TFMTaskRecord(from: task)
        try taskRecord.save(db)
        
        let metadataRecord = TFMTaskMetadataRecord(taskId: task.id, from: task.metadata)
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

// MARK: - Backward Compatibility

@available(*, deprecated, renamed: "TFMPersistenceManagerProtocol")
public typealias PersistenceManagerProtocol = TFMPersistenceManagerProtocol

@available(*, deprecated, renamed: "TFMPersistenceManager")
public typealias PersistenceManager = TFMPersistenceManager
