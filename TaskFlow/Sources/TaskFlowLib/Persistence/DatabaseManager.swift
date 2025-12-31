// ═══════════════════════════════════════════════════════════════════════════════
// TaskFlow - Intelligent Task Management for macOS
// © 2025 Pezz. All rights reserved.
//
// This software is protected by copyright law and international treaties.
// Unauthorized reproduction or distribution of this software, or any portion
// of it, may result in severe civil and criminal penalties.
// ═══════════════════════════════════════════════════════════════════════════════

import Foundation
import GRDB

/// Current schema version - increment when adding migrations
public let CURRENT_SCHEMA_VERSION = 2

/// Manages SQLite database connection and schema
public final class DatabaseManager {
    
    /// Shared instance for app-wide database access
    public static let shared = DatabaseManager()
    
    /// The database connection pool
    private var dbPool: DatabasePool?
    
    /// Database file path
    public private(set) var databasePath: String?
    
    /// Migration result for reporting to UI
    public struct MigrationResult {
        public let success: Bool
        public let fromVersion: Int
        public let toVersion: Int
        public let migrationsApplied: [String]
        public let error: Error?
        public let backupPath: URL?
    }
    
    /// Last migration result
    public private(set) var lastMigrationResult: MigrationResult?
    
    private init() {}
    
    /// Initialize database at the specified path or default Application Support location
    public func initialize(at path: String? = nil) throws {
        let dbPath = try path ?? defaultDatabasePath()
        self.databasePath = dbPath
        
        // Create directory if needed
        let directory = (dbPath as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(
            atPath: directory,
            withIntermediateDirectories: true
        )
        
        // Configure database with WAL mode for better concurrency and crash recovery
        var config = Configuration()
        config.prepareDatabase { db in
            // Enable WAL mode for atomic writes and crash recovery
            try db.execute(sql: "PRAGMA journal_mode = WAL")
            // Enable foreign keys
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }
        
        dbPool = try DatabasePool(path: dbPath, configuration: config)
        try createSchemaWithMigrations()
    }
    
    /// Initialize with in-memory database for testing
    public func initializeInMemory() throws {
        // Create a temporary file-based database for testing
        // (WAL mode not supported with in-memory databases)
        let tempDir = FileManager.default.temporaryDirectory
        let tempPath = tempDir.appendingPathComponent("taskflow_test_\(UUID().uuidString).db").path
        self.databasePath = tempPath
        
        var fileConfig = Configuration()
        fileConfig.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }
        
        dbPool = try DatabasePool(path: tempPath, configuration: fileConfig)
        try createSchemaWithMigrations()
    }
    
    /// Get the database pool for read/write operations
    public func getPool() throws -> DatabasePool {
        guard let pool = dbPool else {
            throw DatabaseError.notInitialized
        }
        return pool
    }
    
    /// Default database path in Application Support
    private func defaultDatabasePath() throws -> String {
        let fileManager = FileManager.default
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appDirectory = appSupport.appendingPathComponent("TaskFlow", isDirectory: true)
        return appDirectory.appendingPathComponent("taskflow.db").path
    }
    
    /// Get current schema version from database
    public func getCurrentSchemaVersion() throws -> Int {
        guard let pool = dbPool else { return 0 }
        
        return try pool.read { db in
            // Check if schema_info table exists
            let tableExists = try db.tableExists("schema_info")
            if !tableExists {
                return 0
            }
            
            let version: Int? = try Int.fetchOne(db, sql: "SELECT version FROM schema_info LIMIT 1")
            return version ?? 0
        }
    }
    
    /// Create database schema with versioned migrations
    private func createSchemaWithMigrations() throws {
        guard let pool = dbPool else { return }
        
        let currentVersion = try getCurrentSchemaVersion()
        var migrationsApplied: [String] = []
        var backupPath: URL? = nil
        
        // If upgrading, create pre-migration backup
        if currentVersion > 0 && currentVersion < CURRENT_SCHEMA_VERSION {
            print("📦 Schema upgrade detected: v\(currentVersion) → v\(CURRENT_SCHEMA_VERSION)")
            print("📦 Creating pre-migration backup...")
            
            do {
                backupPath = try BackupManager.shared.createPreMigrationBackup()
                print("✅ Pre-migration backup created: \(backupPath?.lastPathComponent ?? "unknown")")
            } catch {
                print("⚠️ Pre-migration backup failed: \(error)")
                // Continue anyway - we'll try to migrate
            }
        }
        
        do {
            try pool.write { db in
                // Create schema_info table first (tracks version)
                try db.create(table: "schema_info", ifNotExists: true) { t in
                    t.column("version", .integer).notNull()
                    t.column("updated_at", .text).notNull()
                }
                
                // Create migration_history table (tracks applied migrations)
                try db.create(table: "migration_history", ifNotExists: true) { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("migration_name", .text).notNull()
                    t.column("applied_at", .text).notNull()
                    t.column("from_version", .integer).notNull()
                    t.column("to_version", .integer).notNull()
                }
                
                // Initialize version if not set
                let versionCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM schema_info") ?? 0
                if versionCount == 0 {
                    try db.execute(
                        sql: "INSERT INTO schema_info (version, updated_at) VALUES (?, ?)",
                        arguments: [0, ISO8601DateFormatter().string(from: Date())]
                    )
                }
                
                // Run base schema creation (v1)
                try self.createBaseSchema(db)
                if currentVersion < 1 {
                    migrationsApplied.append("v1_base_schema")
                    try self.recordMigration(db, name: "v1_base_schema", from: 0, to: 1)
                }
                
                // Run v2 migrations (column additions)
                if currentVersion < 2 {
                    try self.migrateToV2(db)
                    migrationsApplied.append("v2_additional_columns")
                    try self.recordMigration(db, name: "v2_additional_columns", from: max(currentVersion, 1), to: 2)
                }
                
                // Update schema version
                try db.execute(
                    sql: "UPDATE schema_info SET version = ?, updated_at = ?",
                    arguments: [CURRENT_SCHEMA_VERSION, ISO8601DateFormatter().string(from: Date())]
                )
            }
            
            lastMigrationResult = MigrationResult(
                success: true,
                fromVersion: currentVersion,
                toVersion: CURRENT_SCHEMA_VERSION,
                migrationsApplied: migrationsApplied,
                error: nil,
                backupPath: backupPath
            )
            
            if !migrationsApplied.isEmpty {
                print("✅ Migrations completed: \(migrationsApplied.joined(separator: ", "))")
            }
            
        } catch {
            lastMigrationResult = MigrationResult(
                success: false,
                fromVersion: currentVersion,
                toVersion: CURRENT_SCHEMA_VERSION,
                migrationsApplied: migrationsApplied,
                error: error,
                backupPath: backupPath
            )
            throw error
        }
    }
    
    /// Create base schema (v1)
    private func createBaseSchema(_ db: Database) throws {
        // Tasks table
        try db.create(table: "tasks", ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("title", .text).notNull()
            t.column("description", .text)
            t.column("source_content", .text)
            t.column("further_details", .text)
            t.column("screenshot_id", .text)
            t.column("assigned_to", .text)
            t.column("time_estimate", .integer).notNull()
            t.column("priority", .integer).notNull()
            t.column("status", .text).notNull()
            t.column("kanban_column", .text)
            t.column("created_at", .text).notNull()
            t.column("updated_at", .text).notNull()
        }
        
        // Task metadata table
        try db.create(table: "task_metadata", ifNotExists: true) { t in
            t.column("task_id", .text).primaryKey()
                .references("tasks", column: "id", onDelete: .cascade)
            t.column("sender", .text)
            t.column("recipient", .text)
            t.column("subject", .text)
            t.column("source_app", .text)
            t.column("captured_at", .text)
            t.column("keywords", .text)
            t.column("llm_generated_title", .integer).defaults(to: 0)
        }
        
        // Screenshots table
        try db.create(table: "screenshots", ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("file_path", .text).notNull()
            t.column("captured_at", .text).notNull()
            t.column("original_width", .integer).notNull()
            t.column("original_height", .integer).notNull()
        }
        
        // App settings table
        try db.create(table: "app_settings", ifNotExists: true) { t in
            t.column("key", .text).primaryKey()
            t.column("value", .text).notNull()
        }
        
        // Backups table
        try db.create(table: "backups", ifNotExists: true) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("created_at", .text).notNull()
            t.column("data", .blob).notNull()
        }
    }
    
    /// Migrate to v2 - add columns that may be missing from older databases
    private func migrateToV2(_ db: Database) throws {
        // Check and add columns to tasks table
        let taskColumns = try db.columns(in: "tasks").map { $0.name }
        
        if !taskColumns.contains("further_details") {
            try db.execute(sql: "ALTER TABLE tasks ADD COLUMN further_details TEXT")
        }
        
        if !taskColumns.contains("screenshot_id") {
            try db.execute(sql: "ALTER TABLE tasks ADD COLUMN screenshot_id TEXT")
        }
        
        if !taskColumns.contains("assigned_to") {
            try db.execute(sql: "ALTER TABLE tasks ADD COLUMN assigned_to TEXT")
        }
        
        // Check and add columns to task_metadata table
        let metadataColumns = try db.columns(in: "task_metadata").map { $0.name }
        
        if !metadataColumns.contains("llm_generated_title") {
            try db.execute(sql: "ALTER TABLE task_metadata ADD COLUMN llm_generated_title INTEGER DEFAULT 0")
        }
    }
    
    /// Record a migration in the history table
    private func recordMigration(_ db: Database, name: String, from: Int, to: Int) throws {
        try db.execute(
            sql: "INSERT INTO migration_history (migration_name, applied_at, from_version, to_version) VALUES (?, ?, ?, ?)",
            arguments: [name, ISO8601DateFormatter().string(from: Date()), from, to]
        )
    }
    
    /// Get migration history
    public func getMigrationHistory() throws -> [(name: String, appliedAt: Date, fromVersion: Int, toVersion: Int)] {
        guard let pool = dbPool else { return [] }
        
        return try pool.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT migration_name, applied_at, from_version, to_version FROM migration_history ORDER BY id DESC")
            
            let formatter = ISO8601DateFormatter()
            return rows.compactMap { row -> (String, Date, Int, Int)? in
                guard let name = row["migration_name"] as? String,
                      let appliedAtStr = row["applied_at"] as? String,
                      let appliedAt = formatter.date(from: appliedAtStr),
                      let from = row["from_version"] as? Int,
                      let to = row["to_version"] as? Int else {
                    return nil
                }
                return (name, appliedAt, from, to)
            }
        }
    }
    
    /// Close database connection
    public func close() {
        dbPool = nil
        databasePath = nil
    }
}

/// Database-specific errors
public enum DatabaseError: Error, LocalizedError {
    case notInitialized
    case saveFailed(String)
    case loadFailed(String)
    case deleteFailed(String)
    case backupFailed(String)
    case restoreFailed(String)
    case migrationFailed(String)
    case corrupted
    
    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Database not initialized"
        case .saveFailed(let message):
            return "Save failed: \(message)"
        case .loadFailed(let message):
            return "Load failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        case .backupFailed(let message):
            return "Backup failed: \(message)"
        case .restoreFailed(let message):
            return "Restore failed: \(message)"
        case .migrationFailed(let message):
            return "Migration failed: \(message)"
        case .corrupted:
            return "Database is corrupted"
        }
    }
}
