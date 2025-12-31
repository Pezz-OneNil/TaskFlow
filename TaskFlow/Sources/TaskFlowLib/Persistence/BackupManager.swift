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

/// Type of backup for retention policy management
public enum BackupType: String, Codable {
    case manual      // User-initiated backups (keep max 5)
    case daily       // Automatic daily backups (keep 14 days)
    case preMigration // Created before schema migrations (keep all)
}

/// Information about a backup file
public struct BackupInfo: Identifiable {
    public let id: UUID
    public let url: URL
    public let createdAt: Date
    public let fileSize: Int64
    public let taskCount: Int?
    public let screenshotCount: Int
    public let backupType: BackupType
    public let isZipArchive: Bool
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    public var typeLabel: String {
        switch backupType {
        case .manual: return "Manual"
        case .daily: return "Daily"
        case .preMigration: return "Pre-Migration"
        }
    }
}

/// Manages backup creation, restoration, and periodic scheduling
public final class BackupManager: ObservableObject {
    
    /// Shared instance
    public static let shared = BackupManager()
    
    private let databaseManager: DatabaseManager
    private var dailyBackupTimer: Timer?
    
    /// Retention policy constants
    private let maxManualBackups = 5
    private let maxDailyBackupDays = 14
    
    /// Published state for UI
    @Published public var isCreatingBackup = false
    @Published public var isRestoring = false
    @Published public var lastBackupDate: Date?
    @Published public var availableBackups: [BackupInfo] = []
    
    /// Backup directory path
    public var backupDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("TaskFlow/Backups", isDirectory: true)
    }
    
    /// Screenshots directory path
    private var screenshotsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("TaskFlow/Screenshots", isDirectory: true)
    }
    
    public init(databaseManager: DatabaseManager = .shared) {
        self.databaseManager = databaseManager
        refreshBackupList()
    }
    
    // MARK: - Backup List Management
    
    /// Refresh the list of available backups
    public func refreshBackupList() {
        do {
            let backupFiles = try FileManager.default.contentsOfDirectory(
                at: backupDirectory,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: .skipsHiddenFiles
            ).filter { $0.pathExtension == "json" || $0.pathExtension == "zip" }
            
            availableBackups = backupFiles.compactMap { url -> BackupInfo? in
                guard let resourceValues = try? url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey]),
                      let createdAt = resourceValues.creationDate,
                      let fileSize = resourceValues.fileSize else {
                    return nil
                }
                
                let isZip = url.pathExtension == "zip"
                let filename = url.lastPathComponent
                
                // Determine backup type from filename
                let backupType: BackupType
                if filename.contains("_daily_") {
                    backupType = .daily
                } else if filename.contains("_premigration_") {
                    backupType = .preMigration
                } else {
                    backupType = .manual
                }
                
                // Try to get task count and screenshot count
                var taskCount: Int? = nil
                var screenshotCount = 0
                
                if isZip {
                    // For zip archives, read manifest if available
                    if let manifest = readZipManifest(url) {
                        taskCount = manifest.taskCount
                        screenshotCount = manifest.screenshotCount
                    }
                } else {
                    // For JSON files, parse directly
                    if let data = try? Data(contentsOf: url),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let tasks = json["tasks"] as? [[String: Any]] {
                        taskCount = tasks.count
                    }
                }
                
                return BackupInfo(
                    id: UUID(),
                    url: url,
                    createdAt: createdAt,
                    fileSize: Int64(fileSize),
                    taskCount: taskCount,
                    screenshotCount: screenshotCount,
                    backupType: backupType,
                    isZipArchive: isZip
                )
            }.sorted { $0.createdAt > $1.createdAt }
            
            lastBackupDate = availableBackups.first?.createdAt
            
        } catch {
            availableBackups = []
        }
    }

    
    // MARK: - Zip Manifest
    
    private struct ZipManifest: Codable {
        let taskCount: Int
        let screenshotCount: Int
        let createdAt: Date
        let schemaVersion: Int
    }
    
    private func readZipManifest(_ zipUrl: URL) -> ZipManifest? {
        // Extract and read manifest.json from zip
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // Use ditto to extract just the manifest
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            process.arguments = ["-x", "-k", zipUrl.path, tempDir.path]
            try process.run()
            process.waitUntilExit()
            
            let manifestUrl = tempDir.appendingPathComponent("manifest.json")
            if FileManager.default.fileExists(atPath: manifestUrl.path) {
                let data = try Data(contentsOf: manifestUrl)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(ZipManifest.self, from: data)
            }
        } catch {
            print("⚠️ Failed to read zip manifest: \(error)")
        }
        return nil
    }
    
    // MARK: - Backup Creation
    
    /// Create a manual backup (includes screenshots as zip archive)
    @discardableResult
    public func createBackup() throws -> URL {
        return try createZipBackup(type: .manual)
    }
    
    /// Create a pre-migration backup before schema upgrades
    @discardableResult
    public func createPreMigrationBackup() throws -> URL {
        return try createZipBackup(type: .preMigration)
    }
    
    /// Create a daily backup if one hasn't been created today
    public func createDailyBackupIfNeeded() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if we already have a daily backup for today
        let hasTodayBackup = availableBackups.contains { backup in
            backup.backupType == .daily &&
            calendar.isDate(backup.createdAt, inSameDayAs: today)
        }
        
        if !hasTodayBackup {
            do {
                _ = try createZipBackup(type: .daily)
                print("✅ Daily backup created")
            } catch {
                print("⚠️ Failed to create daily backup: \(error)")
            }
        }
    }
    
    /// Create a zip backup including screenshots
    private func createZipBackup(type: BackupType) throws -> URL {
        isCreatingBackup = true
        defer {
            isCreatingBackup = false
            refreshBackupList()
            cleanupOldBackups()
        }
        
        let pool = try databaseManager.getPool()
        
        // Load all data
        let backup = try pool.read { db -> BackupData in
            let taskRecords = try TaskRecord.fetchAll(db)
            let metadataRecords = try TaskMetadataRecord.fetchAll(db)
            let calendarEventRecords = try CalendarEventRecord.fetchAll(db)
            let version = try Int.fetchOne(db, sql: "SELECT version FROM schema_info LIMIT 1") ?? CURRENT_SCHEMA_VERSION
            
            // Load category names from UserDefaults
            var categoryNames: [String: String] = [:]
            for i in 0..<10 {
                let key = "category_\(i)_name"
                if let name = UserDefaults.standard.string(forKey: key) {
                    categoryNames[key] = name
                }
            }
            
            return BackupData(
                version: version,
                createdAt: Date(),
                tasks: taskRecords,
                metadata: metadataRecords,
                calendarEvents: calendarEventRecords,
                categoryNames: categoryNames.isEmpty ? nil : categoryNames
            )
        }
        
        // Create temp directory for backup contents
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        // Write task data as JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let taskData = try encoder.encode(backup)
        try taskData.write(to: tempDir.appendingPathComponent("tasks.json"))
        
        // Copy screenshots
        var screenshotCount = 0
        let screenshotsBackupDir = tempDir.appendingPathComponent("screenshots")
        try FileManager.default.createDirectory(at: screenshotsBackupDir, withIntermediateDirectories: true)
        
        // Get all screenshot IDs from tasks
        let screenshotIds = Set(backup.tasks.compactMap { $0.screenshotId })
        
        for screenshotId in screenshotIds {
            let sourcePath = screenshotsDirectory.appendingPathComponent("\(screenshotId).png")
            if FileManager.default.fileExists(atPath: sourcePath.path) {
                let destPath = screenshotsBackupDir.appendingPathComponent("\(screenshotId).png")
                try FileManager.default.copyItem(at: sourcePath, to: destPath)
                screenshotCount += 1
            }
        }
        
        // Write manifest
        let manifest = ZipManifest(
            taskCount: backup.tasks.count,
            screenshotCount: screenshotCount,
            createdAt: Date(),
            schemaVersion: backup.version
        )
        let manifestData = try encoder.encode(manifest)
        try manifestData.write(to: tempDir.appendingPathComponent("manifest.json"))
        
        // Ensure backup directory exists
        try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        
        // Create zip file with timestamp and type
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let typePrefix: String
        switch type {
        case .manual: typePrefix = "backup"
        case .daily: typePrefix = "backup_daily"
        case .preMigration: typePrefix = "backup_premigration"
        }
        let zipFile = backupDirectory.appendingPathComponent("\(typePrefix)_\(timestamp).zip")
        
        // Create zip using ditto
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-c", "-k", "--keepParent", tempDir.path, zipFile.path]
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw DatabaseError.backupFailed("Failed to create zip archive")
        }
        
        print("✅ Backup created: \(zipFile.lastPathComponent) (\(backup.tasks.count) tasks, \(screenshotCount) screenshots)")
        return zipFile
    }

    
    // MARK: - Backup Restoration
    
    /// Restore from the most recent valid backup
    public func restoreFromBackup() throws -> [Task] {
        isRestoring = true
        defer { isRestoring = false }
        
        // Try most recent backup (prefer zip archives)
        if let latestBackup = availableBackups.first {
            return try restoreFromBackup(latestBackup)
        }
        
        throw DatabaseError.restoreFailed("No backup files found")
    }
    
    /// Restore from a specific backup
    public func restoreFromBackup(_ backup: BackupInfo) throws -> [Task] {
        isRestoring = true
        defer {
            isRestoring = false
            refreshBackupList()
        }
        
        if backup.isZipArchive {
            return try restoreFromZipBackup(backup.url)
        } else {
            return try restoreFromJsonFile(backup.url)
        }
    }
    
    /// Restore from a zip backup (includes screenshots)
    private func restoreFromZipBackup(_ zipUrl: URL) throws -> [Task] {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Extract zip
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", zipUrl.path, tempDir.path]
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw DatabaseError.restoreFailed("Failed to extract backup archive")
        }
        
        // Find the extracted folder (ditto creates a subfolder)
        let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        let extractedDir = contents.first { url in
            var isDir: ObjCBool = false
            return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
        } ?? tempDir
        
        // Read tasks.json
        let tasksJsonUrl = extractedDir.appendingPathComponent("tasks.json")
        guard FileManager.default.fileExists(atPath: tasksJsonUrl.path) else {
            throw DatabaseError.restoreFailed("Backup archive missing tasks.json")
        }
        
        let data = try Data(contentsOf: tasksJsonUrl)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupData.self, from: data)
        
        // Restore screenshots
        let screenshotsBackupDir = extractedDir.appendingPathComponent("screenshots")
        if FileManager.default.fileExists(atPath: screenshotsBackupDir.path) {
            try FileManager.default.createDirectory(at: screenshotsDirectory, withIntermediateDirectories: true)
            
            let screenshotFiles = try FileManager.default.contentsOfDirectory(
                at: screenshotsBackupDir,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "png" }
            
            for screenshotFile in screenshotFiles {
                let destPath = screenshotsDirectory.appendingPathComponent(screenshotFile.lastPathComponent)
                // Remove existing if present
                try? FileManager.default.removeItem(at: destPath)
                try FileManager.default.copyItem(at: screenshotFile, to: destPath)
            }
            
            print("📸 Restored \(screenshotFiles.count) screenshots")
        }
        
        // Restore task data
        return try restoreBackupData(backup)
    }
    
    /// Restore from a JSON file (legacy format, no screenshots)
    private func restoreFromJsonFile(_ url: URL) throws -> [Task] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupData.self, from: data)
        
        print("📦 Restoring from JSON backup: \(url.lastPathComponent) (v\(backup.version), \(backup.tasks.count) tasks)")
        return try restoreBackupData(backup)
    }
    
    /// Restore backup data to database and return tasks
    private func restoreBackupData(_ backup: BackupData) throws -> [Task] {
        let pool = try databaseManager.getPool()
        
        try pool.write { db in
            // Clear existing data
            try TaskMetadataRecord.deleteAll(db)
            try TaskRecord.deleteAll(db)
            
            // Clear calendar events if table exists
            if try db.tableExists("calendar_events") {
                try CalendarEventRecord.deleteAll(db)
            }
            
            // Restore tasks
            for taskRecord in backup.tasks {
                try taskRecord.insert(db)
            }
            
            // Restore metadata
            for metadataRecord in backup.metadata {
                try metadataRecord.insert(db)
            }
            
            // Restore calendar events if present and table exists
            if let calendarEvents = backup.calendarEvents, try db.tableExists("calendar_events") {
                for eventRecord in calendarEvents {
                    try eventRecord.insert(db)
                }
                print("📅 Restored \(calendarEvents.count) calendar events")
            }
        }
        
        // Restore category names to UserDefaults
        if let categoryNames = backup.categoryNames {
            for (key, name) in categoryNames {
                UserDefaults.standard.set(name, forKey: key)
            }
            print("🏷️ Restored \(categoryNames.count) category names")
        }
        
        // Reload calendar events in manager
        CalendarEventManager.shared.loadEvents()
        
        // Return restored tasks
        let tasks = try pool.read { db in
            let taskRecords = try TaskRecord.fetchAll(db)
            return taskRecords.compactMap { taskRecord -> Task? in
                let metadata = try? TaskMetadataRecord
                    .filter(Column("task_id") == taskRecord.id)
                    .fetchOne(db)
                return taskRecord.toTask(with: metadata)
            }
        }
        
        print("✅ Restored \(tasks.count) tasks from backup")
        return tasks
    }
    
    // MARK: - Export/Import
    
    /// Export a backup to a user-selected location
    public func exportBackup(_ backup: BackupInfo, to destination: URL) throws {
        try FileManager.default.copyItem(at: backup.url, to: destination)
        print("✅ Backup exported to: \(destination.path)")
    }
    
    /// Import a backup from a user-selected file
    public func importBackup(from source: URL) throws -> BackupInfo {
        let isZip = source.pathExtension == "zip"
        
        // Validate the backup
        if isZip {
            guard readZipManifest(source) != nil else {
                throw DatabaseError.backupFailed("Invalid backup archive - missing manifest")
            }
        } else {
            let data = try Data(contentsOf: source)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            _ = try decoder.decode(BackupData.self, from: data)
        }
        
        // Copy to backup directory
        try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let ext = isZip ? "zip" : "json"
        let destination = backupDirectory.appendingPathComponent("imported_\(timestamp).\(ext)")
        
        try FileManager.default.copyItem(at: source, to: destination)
        
        refreshBackupList()
        
        guard let imported = availableBackups.first(where: { $0.url == destination }) else {
            throw DatabaseError.backupFailed("Failed to import backup")
        }
        
        print("✅ Backup imported: \(destination.lastPathComponent)")
        return imported
    }
    
    /// Delete a specific backup
    public func deleteBackup(_ backup: BackupInfo) throws {
        try FileManager.default.removeItem(at: backup.url)
        refreshBackupList()
    }

    
    // MARK: - Validation
    
    /// Validate database integrity on startup
    public func validateAndRecover() throws -> Bool {
        do {
            let pool = try databaseManager.getPool()
            
            // Run integrity check
            let result: String? = try pool.read { db in
                try String.fetchOne(db, sql: "PRAGMA integrity_check")
            }
            
            if result == "ok" {
                return true
            }
            
            // Database is corrupted, attempt recovery
            print("⚠️ Database corruption detected, attempting recovery...")
            _ = try restoreFromBackup()
            return true
            
        } catch {
            // Try to restore from backup
            do {
                _ = try restoreFromBackup()
                return true
            } catch {
                throw DatabaseError.corrupted
            }
        }
    }
    
    // MARK: - Daily Backup Scheduling
    
    /// Start daily backup check (runs once per hour to check if daily backup needed)
    public func startDailyBackupSchedule() {
        stopDailyBackupSchedule()
        
        // Check immediately on start
        createDailyBackupIfNeeded()
        
        // Then check every hour
        dailyBackupTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.createDailyBackupIfNeeded()
        }
    }
    
    /// Stop daily backup scheduling
    public func stopDailyBackupSchedule() {
        dailyBackupTimer?.invalidate()
        dailyBackupTimer = nil
    }
    
    // MARK: - Cleanup with Retention Policy
    
    /// Remove old backups according to retention policy:
    /// - Manual backups: keep max 5
    /// - Daily backups: keep one per day for last 14 days
    /// - Pre-migration backups: keep all
    private func cleanupOldBackups() {
        let calendar = Calendar.current
        let now = Date()
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -maxDailyBackupDays, to: now)!
        
        // Group backups by type
        let manualBackups = availableBackups.filter { $0.backupType == .manual }
        let dailyBackups = availableBackups.filter { $0.backupType == .daily }
        // Pre-migration backups are kept indefinitely
        
        // Clean up manual backups (keep newest 5)
        if manualBackups.count > maxManualBackups {
            let toDelete = manualBackups.dropFirst(maxManualBackups)
            for backup in toDelete {
                try? FileManager.default.removeItem(at: backup.url)
                print("🗑️ Deleted old manual backup: \(backup.url.lastPathComponent)")
            }
        }
        
        // Clean up daily backups
        // Keep one per day for last 14 days, delete older ones
        var seenDays = Set<String>()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for backup in dailyBackups {
            let dayKey = dateFormatter.string(from: backup.createdAt)
            
            if backup.createdAt < fourteenDaysAgo {
                // Older than 14 days - delete
                try? FileManager.default.removeItem(at: backup.url)
                print("🗑️ Deleted old daily backup: \(backup.url.lastPathComponent)")
            } else if seenDays.contains(dayKey) {
                // Already have a backup for this day - delete duplicate
                try? FileManager.default.removeItem(at: backup.url)
                print("🗑️ Deleted duplicate daily backup: \(backup.url.lastPathComponent)")
            } else {
                // Keep this one
                seenDays.insert(dayKey)
            }
        }
        
        refreshBackupList()
    }
}

// MARK: - Backup Data Structure

/// Structure for JSON backup files
struct BackupData: Codable {
    let version: Int
    let createdAt: Date
    let tasks: [TaskRecord]
    let metadata: [TaskMetadataRecord]
    let calendarEvents: [CalendarEventRecord]?
    let categoryNames: [String: String]?
    
    init(version: Int, createdAt: Date, tasks: [TaskRecord], metadata: [TaskMetadataRecord], calendarEvents: [CalendarEventRecord]? = nil, categoryNames: [String: String]? = nil) {
        self.version = version
        self.createdAt = createdAt
        self.tasks = tasks
        self.metadata = metadata
        self.calendarEvents = calendarEvents
        self.categoryNames = categoryNames
    }
}
