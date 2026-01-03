import Foundation
import AppKit

/// Manages system permissions required by the app
/// Per Requirements 8.2, 8.3
public final class TFMPermissionManager: ObservableObject {
    
    @Published public private(set) var screenRecordingGranted: Bool = false
    @Published public private(set) var accessibilityGranted: Bool = false
    
    public init() {
        checkPermissions()
    }
    
    // MARK: - Permission Checks
    
    /// Check all required permissions
    public func checkPermissions() {
        screenRecordingGranted = checkScreenRecordingPermission()
        accessibilityGranted = checkAccessibilityPermission()
    }
    
    /// Check if screen recording permission is granted
    /// Per Requirement 8.2
    public func checkScreenRecordingPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }
    
    /// Check if accessibility permission is granted
    public func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    // MARK: - Permission Requests
    
    /// Request screen recording permission
    /// Per Requirement 8.3
    @discardableResult
    public func requestScreenRecordingPermission() -> Bool {
        let granted = CGRequestScreenCaptureAccess()
        screenRecordingGranted = granted
        return granted
    }
    
    /// Request accessibility permission (opens System Settings)
    public func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Re-check after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.accessibilityGranted = self?.checkAccessibilityPermission() ?? false
        }
    }
    
    // MARK: - System Settings Navigation
    
    /// Open Screen Recording settings in System Settings
    public func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Open Accessibility settings in System Settings
    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Permission Status
    
    /// Returns true if all required permissions are granted
    public var allPermissionsGranted: Bool {
        return screenRecordingGranted
        // Note: Accessibility is optional for basic functionality
    }
    
    /// Get human-readable status for screen recording permission
    public var screenRecordingStatus: String {
        if screenRecordingGranted {
            return "Granted"
        } else {
            return "Not Granted - Required for screen capture"
        }
    }
    
    /// Get human-readable status for accessibility permission
    public var accessibilityStatus: String {
        if accessibilityGranted {
            return "Granted"
        } else {
            return "Not Granted - Optional for enhanced features"
        }
    }
    
    /// Get instructions for granting screen recording permission
    public var screenRecordingInstructions: String {
        """
        To enable screen capture:
        1. Open System Settings
        2. Go to Privacy & Security > Screen Recording
        3. Find TaskFlow in the list
        4. Toggle the switch to enable
        5. You may need to restart the app
        """
    }
    
    /// Get instructions for granting accessibility permission
    public var accessibilityInstructions: String {
        """
        To enable accessibility features:
        1. Open System Settings
        2. Go to Privacy & Security > Accessibility
        3. Find TaskFlow in the list
        4. Toggle the switch to enable
        """
    }
}


// MARK: - Backward Compatibility

@available(*, deprecated, renamed: "TFMPermissionManager")
public typealias PermissionManager = TFMPermissionManager
