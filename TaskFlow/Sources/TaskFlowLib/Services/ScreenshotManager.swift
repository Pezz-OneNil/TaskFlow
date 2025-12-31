import Foundation
import AppKit
import GRDB

/// Stored screenshot with metadata
public struct StoredScreenshot: Equatable {
    public let id: UUID
    public let image: NSImage
    public let capturedAt: Date
    public let width: Int
    public let height: Int
    
    public init(id: UUID, image: NSImage, capturedAt: Date, width: Int, height: Int) {
        self.id = id
        self.image = image
        self.capturedAt = capturedAt
        self.width = width
        self.height = height
    }
}

/// Protocol for screenshot management operations
public protocol ScreenshotManagerProtocol {
    func saveScreenshot(_ image: NSImage) throws -> UUID
    func loadScreenshot(id: UUID) -> StoredScreenshot?
    func deleteScreenshot(id: UUID) throws
    func getScreenshotPath(id: UUID) -> URL?
    func cropScreenshot(id: UUID, to rect: CGRect) throws -> UUID
}

/// Manages screenshot storage, retrieval, and cropping
/// Per Requirements 2A.1, 2A.2, 2A.3, 2A.4
public final class ScreenshotManager: ScreenshotManagerProtocol {
    
    private let databaseManager: DatabaseManager
    private let screenshotsDirectory: URL
    
    public init(databaseManager: DatabaseManager = .shared) {
        self.databaseManager = databaseManager
        
        // Create screenshots directory in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.screenshotsDirectory = appSupport.appendingPathComponent("TaskFlow/Screenshots", isDirectory: true)
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: screenshotsDirectory, withIntermediateDirectories: true)
    }
    
    /// Initialize with custom directory (for testing)
    public init(databaseManager: DatabaseManager, screenshotsDirectory: URL) {
        self.databaseManager = databaseManager
        self.screenshotsDirectory = screenshotsDirectory
        try? FileManager.default.createDirectory(at: screenshotsDirectory, withIntermediateDirectories: true)
    }
    
    /// Save screenshot to disk and database
    /// Returns the UUID of the saved screenshot
    public func saveScreenshot(_ image: NSImage) throws -> UUID {
        let id = UUID()
        let capturedAt = Date()
        
        // Get image dimensions
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ScreenshotError.invalidImage
        }
        let width = cgImage.width
        let height = cgImage.height
        
        // Save to disk as PNG
        let filePath = screenshotsDirectory.appendingPathComponent("\(id.uuidString).png")
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw ScreenshotError.encodingFailed
        }
        
        try pngData.write(to: filePath)
        
        // Save record to database
        let record = ScreenshotRecord(
            id: id,
            filePath: filePath.path,
            capturedAt: capturedAt,
            width: width,
            height: height
        )
        
        let pool = try databaseManager.getPool()
        try pool.write { db in
            try record.save(db)
        }
        
        return id
    }
    
    /// Load screenshot by ID
    public func loadScreenshot(id: UUID) -> StoredScreenshot? {
        do {
            let pool = try databaseManager.getPool()
            
            let record = try pool.read { db -> ScreenshotRecord? in
                try ScreenshotRecord
                    .filter(Column("id") == id.uuidString)
                    .fetchOne(db)
            }
            
            guard let record = record else { return nil }
            
            // Load image from disk
            let fileURL = URL(fileURLWithPath: record.filePath)
            guard let image = NSImage(contentsOf: fileURL) else { return nil }
            
            let capturedAt = ISO8601DateFormatter().date(from: record.capturedAt) ?? Date()
            
            return StoredScreenshot(
                id: id,
                image: image,
                capturedAt: capturedAt,
                width: record.originalWidth,
                height: record.originalHeight
            )
        } catch {
            return nil
        }
    }
    
    /// Delete screenshot from disk and database
    public func deleteScreenshot(id: UUID) throws {
        let pool = try databaseManager.getPool()
        
        // Get file path before deleting record
        let record = try pool.read { db -> ScreenshotRecord? in
            try ScreenshotRecord
                .filter(Column("id") == id.uuidString)
                .fetchOne(db)
        }
        
        // Delete from database
        _ = try pool.write { db in
            try ScreenshotRecord
                .filter(Column("id") == id.uuidString)
                .deleteAll(db)
        }
        
        // Delete file from disk
        if let record = record {
            try? FileManager.default.removeItem(atPath: record.filePath)
        }
    }
    
    /// Get the file path for a screenshot
    public func getScreenshotPath(id: UUID) -> URL? {
        do {
            let pool = try databaseManager.getPool()
            
            let record = try pool.read { db -> ScreenshotRecord? in
                try ScreenshotRecord
                    .filter(Column("id") == id.uuidString)
                    .fetchOne(db)
            }
            
            guard let record = record else { return nil }
            return URL(fileURLWithPath: record.filePath)
        } catch {
            return nil
        }
    }
    
    /// Crop screenshot and save as new image
    /// Returns the UUID of the new cropped screenshot
    public func cropScreenshot(id: UUID, to rect: CGRect) throws -> UUID {
        // Load original screenshot
        guard let original = loadScreenshot(id: id) else {
            throw ScreenshotError.notFound
        }
        
        // Get CGImage for cropping
        guard let cgImage = original.image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ScreenshotError.invalidImage
        }
        
        // Validate crop rect
        let imageRect = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        guard imageRect.contains(rect) else {
            throw ScreenshotError.invalidCropRect
        }
        
        // Perform crop
        guard let croppedCGImage = cgImage.cropping(to: rect) else {
            throw ScreenshotError.cropFailed
        }
        
        // Create NSImage from cropped CGImage
        let croppedImage = NSImage(cgImage: croppedCGImage, size: NSSize(width: rect.width, height: rect.height))
        
        // Save as new screenshot
        return try saveScreenshot(croppedImage)
    }
}

/// Screenshot-specific errors
public enum ScreenshotError: Error, LocalizedError {
    case invalidImage
    case encodingFailed
    case notFound
    case invalidCropRect
    case cropFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image data"
        case .encodingFailed:
            return "Failed to encode image as PNG"
        case .notFound:
            return "Screenshot not found"
        case .invalidCropRect:
            return "Crop rectangle is outside image bounds"
        case .cropFailed:
            return "Failed to crop image"
        }
    }
}
