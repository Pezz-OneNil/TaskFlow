import Foundation
import SwiftUI

/// State of the status bar
/// Per Requirement 9
public enum StatusBarState: Equatable {
    case idle
    case processing(message: String)
    case success(message: String)
    case warning(message: String)
    case error(message: String)
    
    public var message: String {
        switch self {
        case .idle:
            return "Ready"
        case .processing(let message),
             .success(let message),
             .warning(let message),
             .error(let message):
            return message
        }
    }
    
    public var color: Color {
        switch self {
        case .idle:
            return CyberpunkTheme.textSecondary
        case .processing:
            return CyberpunkTheme.accentCyan
        case .success:
            return Color.green
        case .warning:
            return Color.yellow
        case .error:
            return Color.red
        }
    }
    
    public var isProcessing: Bool {
        if case .processing = self {
            return true
        }
        return false
    }
}

/// Protocol for status bar management
public protocol StatusBarManagerProtocol: ObservableObject {
    var currentState: StatusBarState { get }
    
    func setProcessing(_ message: String)
    func setSuccess(_ message: String)
    func setWarning(_ message: String)
    func setError(_ message: String)
    func clearStatus()
    func clearAfterDelay(_ seconds: TimeInterval)
}

/// Manager for the status bar state
/// Per Requirement 9.1, 9.7, 9.10
public final class StatusBarManager: ObservableObject, StatusBarManagerProtocol {
    @Published public private(set) var currentState: StatusBarState = .idle
    
    private var clearTask: _Concurrency.Task<Void, Never>?
    
    public init() {}
    
    /// Set status to processing with a message
    /// Per Requirement 9.2, 9.3, 9.4, 9.6
    public func setProcessing(_ message: String) {
        clearTask?.cancel()
        DispatchQueue.main.async { [weak self] in
            self?.currentState = .processing(message: message)
        }
    }
    
    /// Set status to success with a message
    /// Per Requirement 9.7
    public func setSuccess(_ message: String) {
        clearTask?.cancel()
        DispatchQueue.main.async { [weak self] in
            self?.currentState = .success(message: message)
        }
    }
    
    /// Set status to warning with a message
    /// Per Requirement 9.5
    public func setWarning(_ message: String) {
        clearTask?.cancel()
        DispatchQueue.main.async { [weak self] in
            self?.currentState = .warning(message: message)
        }
    }
    
    /// Set status to error with a message
    /// Per Requirement 9.8
    public func setError(_ message: String) {
        clearTask?.cancel()
        DispatchQueue.main.async { [weak self] in
            self?.currentState = .error(message: message)
        }
    }
    
    /// Clear the status back to idle
    /// Per Requirement 9.7, 9.10
    public func clearStatus() {
        clearTask?.cancel()
        DispatchQueue.main.async { [weak self] in
            self?.currentState = .idle
        }
    }
    
    /// Clear the status after a delay
    /// Per Requirement 9.7
    public func clearAfterDelay(_ seconds: TimeInterval) {
        clearTask?.cancel()
        clearTask = _Concurrency.Task { @MainActor [weak self] in
            try? await _Concurrency.Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            if !_Concurrency.Task.isCancelled {
                self?.currentState = .idle
            }
        }
    }
}
