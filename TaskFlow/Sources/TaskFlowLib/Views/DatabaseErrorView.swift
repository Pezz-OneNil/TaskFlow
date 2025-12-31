import SwiftUI
import AppKit

/// View displayed when database errors occur
/// Per Requirement 20.5, 20.11 (User notification on errors)
public struct DatabaseErrorView: View {
    let error: DatabaseError
    let migrationResult: DatabaseManager.MigrationResult?
    let onRetry: () -> Void
    let onRestoreFromBackup: () -> Void
    let onOpenBackupFolder: () -> Void
    let onQuit: () -> Void
    
    public init(
        error: DatabaseError,
        migrationResult: DatabaseManager.MigrationResult? = nil,
        onRetry: @escaping () -> Void,
        onRestoreFromBackup: @escaping () -> Void,
        onOpenBackupFolder: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.error = error
        self.migrationResult = migrationResult
        self.onRetry = onRetry
        self.onRestoreFromBackup = onRestoreFromBackup
        self.onOpenBackupFolder = onOpenBackupFolder
        self.onQuit = onQuit
    }
    
    public var body: some View {
        VStack(spacing: CyberpunkTheme.spacingL) {
            // Error icon
            Image(systemName: errorIcon)
                .font(.system(size: 64))
                .foregroundColor(CyberpunkTheme.accentMagenta)
            
            // Title
            Text(errorTitle)
                .font(CyberpunkTheme.fontTitle)
                .foregroundColor(CyberpunkTheme.textPrimary)
            
            // Description
            Text(errorDescription)
                .font(CyberpunkTheme.fontBody)
                .foregroundColor(CyberpunkTheme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            
            // Migration details if available
            if let result = migrationResult, !result.success {
                migrationDetailsView(result)
            }
            
            // Recovery options
            VStack(spacing: CyberpunkTheme.spacingM) {
                Text("Recovery Options")
                    .font(CyberpunkTheme.fontHeadline)
                    .foregroundColor(CyberpunkTheme.textSecondary)
                
                HStack(spacing: CyberpunkTheme.spacingM) {
                    // Retry button
                    NeonButton(title: "Retry", color: CyberpunkTheme.accentCyan) {
                        onRetry()
                    }
                    
                    // Restore from backup
                    NeonButton(title: "Restore from Backup", color: CyberpunkTheme.accentGreen) {
                        onRestoreFromBackup()
                    }
                }
                
                HStack(spacing: CyberpunkTheme.spacingM) {
                    // Open backup folder
                    Button(action: onOpenBackupFolder) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                            Text("Open Backup Folder")
                        }
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    
                    // Quit
                    Button(action: onQuit) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                            Text("Quit TaskFlow")
                        }
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.accentMagenta)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, CyberpunkTheme.spacingM)
            
            // Backup location info
            VStack(spacing: 4) {
                Text("Backups are stored at:")
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.textTertiary)
                Text("~/Library/Application Support/TaskFlow/Backups/")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CyberpunkTheme.textTertiary)
            }
            .padding(.top, CyberpunkTheme.spacingM)
        }
        .padding(CyberpunkTheme.spacingXL)
        .frame(minWidth: 500, minHeight: 400)
        .background(CyberpunkTheme.backgroundPrimary)
    }
    
    private var errorIcon: String {
        switch error {
        case .corrupted:
            return "exclamationmark.triangle.fill"
        case .migrationFailed:
            return "arrow.triangle.2.circlepath.circle.fill"
        default:
            return "xmark.circle.fill"
        }
    }
    
    private var errorTitle: String {
        switch error {
        case .corrupted:
            return "Database Corrupted"
        case .migrationFailed:
            return "Migration Failed"
        case .notInitialized:
            return "Database Not Initialized"
        default:
            return "Database Error"
        }
    }
    
    private var errorDescription: String {
        switch error {
        case .corrupted:
            return "The TaskFlow database appears to be corrupted. Your data may be recoverable from a backup."
        case .migrationFailed(let message):
            return "Failed to upgrade the database schema: \(message)\n\nA backup was created before the migration attempt."
        case .notInitialized:
            return "The database could not be initialized. Please try restarting the application."
        default:
            return error.localizedDescription
        }
    }
    
    @ViewBuilder
    private func migrationDetailsView(_ result: DatabaseManager.MigrationResult) -> some View {
        NeonCard(color: CyberpunkTheme.accentMagenta) {
            VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(CyberpunkTheme.accentMagenta)
                    Text("Migration Details")
                        .font(CyberpunkTheme.fontHeadline)
                        .foregroundColor(CyberpunkTheme.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("From version: \(result.fromVersion)")
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textSecondary)
                    Text("To version: \(result.toVersion)")
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textSecondary)
                    
                    if let backupPath = result.backupPath {
                        Text("Pre-migration backup: \(backupPath.lastPathComponent)")
                            .font(CyberpunkTheme.fontCaption)
                            .foregroundColor(CyberpunkTheme.accentGreen)
                    }
                    
                    if let error = result.error {
                        Text("Error: \(error.localizedDescription)")
                            .font(CyberpunkTheme.fontCaption)
                            .foregroundColor(CyberpunkTheme.accentMagenta)
                    }
                }
            }
        }
        .frame(maxWidth: 400)
    }
}

/// Alert for showing migration success
public struct MigrationSuccessAlert: View {
    let result: DatabaseManager.MigrationResult
    let onDismiss: () -> Void
    
    public var body: some View {
        VStack(spacing: CyberpunkTheme.spacingM) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(CyberpunkTheme.accentGreen)
            
            Text("Database Upgraded")
                .font(CyberpunkTheme.fontTitle)
                .foregroundColor(CyberpunkTheme.textPrimary)
            
            Text("TaskFlow has been upgraded from v\(result.fromVersion) to v\(result.toVersion)")
                .font(CyberpunkTheme.fontBody)
                .foregroundColor(CyberpunkTheme.textSecondary)
                .multilineTextAlignment(.center)
            
            if !result.migrationsApplied.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Migrations applied:")
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textTertiary)
                    ForEach(result.migrationsApplied, id: \.self) { migration in
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10))
                                .foregroundColor(CyberpunkTheme.accentGreen)
                            Text(migration)
                                .font(CyberpunkTheme.fontCaption)
                                .foregroundColor(CyberpunkTheme.textSecondary)
                        }
                    }
                }
            }
            
            if let backupPath = result.backupPath {
                Text("A backup was created: \(backupPath.lastPathComponent)")
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.accentCyan)
            }
            
            NeonButton(title: "Continue", color: CyberpunkTheme.accentGreen) {
                onDismiss()
            }
            .padding(.top, CyberpunkTheme.spacingS)
        }
        .padding(CyberpunkTheme.spacingL)
        .frame(minWidth: 350)
        .background(CyberpunkTheme.backgroundPrimary)
    }
}
