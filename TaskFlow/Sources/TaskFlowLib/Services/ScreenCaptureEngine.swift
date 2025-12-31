import Foundation
import AppKit
import ScreenCaptureKit

/// Protocol for screen capture functionality
public protocol ScreenCaptureEngineProtocol {
    func captureScreen() async throws -> NSImage
    func captureSelectedRegion(rect: CGRect) async throws -> NSImage
    func checkPermission() -> Bool
    func requestPermission() async -> Bool
}

/// Errors that can occur during screen capture
public enum ScreenCaptureError: Error, LocalizedError {
    case permissionDenied
    case captureFailure(String)
    case noDisplaysAvailable
    case invalidRegion
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Screen recording permission denied. Please enable in System Settings > Privacy & Security > Screen Recording."
        case .captureFailure(let message):
            return "Screen capture failed: \(message)"
        case .noDisplaysAvailable:
            return "No displays available for capture."
        case .invalidRegion:
            return "Invalid capture region specified."
        }
    }
}

/// Engine for capturing screen content
/// Uses CGWindowListCreateImage for macOS 13+ compatibility
/// Per Requirements 2.1, 8.2, 8.3
public final class ScreenCaptureEngine: ScreenCaptureEngineProtocol {
    
    public init() {}
    
    // MARK: - Permission Handling
    
    /// Check if screen recording permission is granted
    /// Per Requirement 8.2
    public func checkPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }
    
    /// Request screen recording permission
    /// Per Requirement 8.3
    public func requestPermission() async -> Bool {
        // This will prompt the user if not already granted
        return CGRequestScreenCaptureAccess()
    }
    
    // MARK: - Screen Capture
    
    /// Capture the entire main screen
    /// Per Requirement 2.1
    public func captureScreen() async throws -> NSImage {
        guard checkPermission() else {
            throw ScreenCaptureError.permissionDenied
        }
        
        guard let mainDisplay = NSScreen.main else {
            throw ScreenCaptureError.noDisplaysAvailable
        }
        
        let displayBounds = mainDisplay.frame
        
        // Use CGWindowListCreateImage for macOS 13 compatibility
        guard let cgImage = CGWindowListCreateImage(
            displayBounds,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else {
            throw ScreenCaptureError.captureFailure("Failed to create screen image")
        }
        
        let nsImage = NSImage(cgImage: cgImage, size: displayBounds.size)
        return nsImage
    }
    
    /// Capture a specific region of the screen
    /// Per Requirement 2.1
    public func captureSelectedRegion(rect: CGRect) async throws -> NSImage {
        print("ScreenCaptureEngine: captureSelectedRegion called with rect \(rect)")
        
        let hasPermission = checkPermission()
        print("ScreenCaptureEngine: Permission check result: \(hasPermission)")
        
        guard hasPermission else {
            print("ScreenCaptureEngine: Permission denied, requesting...")
            _ = await requestPermission()
            throw ScreenCaptureError.permissionDenied
        }
        
        guard rect.width > 0 && rect.height > 0 else {
            print("ScreenCaptureEngine: Invalid region - width: \(rect.width), height: \(rect.height)")
            throw ScreenCaptureError.invalidRegion
        }
        
        print("ScreenCaptureEngine: Calling CGWindowListCreateImage...")
        // Use CGWindowListCreateImage for macOS 13 compatibility
        guard let cgImage = CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else {
            print("ScreenCaptureEngine: CGWindowListCreateImage returned nil")
            throw ScreenCaptureError.captureFailure("Failed to create region image")
        }
        
        print("ScreenCaptureEngine: CGImage created successfully, size: \(cgImage.width)x\(cgImage.height)")
        let nsImage = NSImage(cgImage: cgImage, size: rect.size)
        print("ScreenCaptureEngine: NSImage created, size: \(nsImage.size)")
        return nsImage
    }
    
    /// Get list of available windows for capture
    @available(macOS 13.0, *)
    public func getAvailableWindows() async throws -> [SCWindow] {
        let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
        return content.windows
    }
    
    /// Capture a specific window by window ID
    public func captureWindow(windowID: CGWindowID) async throws -> NSImage {
        guard checkPermission() else {
            throw ScreenCaptureError.permissionDenied
        }
        
        // Get window bounds
        guard let windowInfo = CGWindowListCopyWindowInfo([.optionIncludingWindow], windowID) as? [[String: Any]],
              let info = windowInfo.first,
              let boundsDict = info[kCGWindowBounds as String] as? [String: CGFloat],
              let x = boundsDict["X"],
              let y = boundsDict["Y"],
              let width = boundsDict["Width"],
              let height = boundsDict["Height"] else {
            throw ScreenCaptureError.captureFailure("Failed to get window bounds")
        }
        
        let bounds = CGRect(x: x, y: y, width: width, height: height)
        
        // Capture the specific window
        guard let cgImage = CGWindowListCreateImage(
            bounds,
            .optionIncludingWindow,
            windowID,
            .bestResolution
        ) else {
            throw ScreenCaptureError.captureFailure("Failed to capture window")
        }
        
        let nsImage = NSImage(cgImage: cgImage, size: bounds.size)
        return nsImage
    }
    
    /// Get list of window IDs with their titles
    public func getWindowList() -> [(windowID: CGWindowID, title: String?, ownerName: String?)] {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        
        return windowList.compactMap { info in
            guard let windowID = info[kCGWindowNumber as String] as? CGWindowID else {
                return nil
            }
            let title = info[kCGWindowName as String] as? String
            let ownerName = info[kCGWindowOwnerName as String] as? String
            return (windowID, title, ownerName)
        }
    }
}
