import SwiftUI

/// Status bar view displayed at the bottom of the main window
/// Per Requirement 9.1, 9.9, 9.10
public struct StatusBarView: View {
    @ObservedObject var statusBarManager: StatusBarManager
    
    public init(statusBarManager: StatusBarManager) {
        self.statusBarManager = statusBarManager
    }
    
    public var body: some View {
        HStack(spacing: CyberpunkTheme.spacingS) {
            // Activity indicator for processing state
            if statusBarManager.currentState.isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: statusBarManager.currentState.color))
                    .scaleEffect(0.7)
                    .frame(width: 16, height: 16)
            } else {
                // Status icon based on state
                statusIcon
                    .frame(width: 16, height: 16)
            }
            
            // Status message
            Text(statusBarManager.currentState.message)
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(statusBarManager.currentState.color)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
        }
        .padding(.horizontal, CyberpunkTheme.spacingM)
        .padding(.vertical, CyberpunkTheme.spacingXS)
        .frame(height: 28)
        .background(
            Rectangle()
                .fill(CyberpunkTheme.backgroundSecondary)
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(statusBarManager.currentState.color.opacity(0.3)),
            alignment: .top
        )
        .animation(.easeInOut(duration: 0.2), value: statusBarManager.currentState)
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch statusBarManager.currentState {
        case .idle:
            Image(systemName: "checkmark.circle")
                .font(.system(size: 12))
                .foregroundColor(statusBarManager.currentState.color)
        case .processing:
            EmptyView() // Handled by ProgressView above
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(statusBarManager.currentState.color)
        case .warning:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundColor(statusBarManager.currentState.color)
        case .error:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(statusBarManager.currentState.color)
        }
    }
}

#if DEBUG
struct StatusBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            // Idle state
            StatusBarView(statusBarManager: {
                let manager = StatusBarManager()
                return manager
            }())
            
            // Processing state
            StatusBarView(statusBarManager: {
                let manager = StatusBarManager()
                manager.setProcessing("Extracting text from image...")
                return manager
            }())
            
            // Success state
            StatusBarView(statusBarManager: {
                let manager = StatusBarManager()
                manager.setSuccess("Task created successfully")
                return manager
            }())
            
            // Warning state
            StatusBarView(statusBarManager: {
                let manager = StatusBarManager()
                manager.setWarning("LLM unavailable - using fallback title")
                return manager
            }())
            
            // Error state
            StatusBarView(statusBarManager: {
                let manager = StatusBarManager()
                manager.setError("Failed to save screenshot")
                return manager
            }())
        }
        .background(CyberpunkTheme.backgroundPrimary)
    }
}
#endif
