// ═══════════════════════════════════════════════════════════════════════════════
// TaskFlow - Intelligent Task Management for macOS
// © 2025 Pezz. All rights reserved.
//
// This software is protected by copyright law and international treaties.
// Unauthorized reproduction or distribution of this software, or any portion
// of it, may result in severe civil and criminal penalties.
// ═══════════════════════════════════════════════════════════════════════════════

import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// View for managing backups and restoration
/// Per Requirement 20 (Data Migration and Upgrade Safety)
public struct BackupRestoreView: View {
    @ObservedObject var backupManager: BackupManager
    @ObservedObject var taskManager: TaskManager
    
    @State private var showingRestoreConfirmation = false
    @State private var selectedBackup: BackupInfo?
    @State private var showingExportPanel = false
    @State private var showingImportPanel = false
    @State private var alertMessage: String?
    @State private var showingAlert = false
    @State private var isSuccess = true
    
    public init(backupManager: BackupManager, taskManager: TaskManager) {
        self.backupManager = backupManager
        self.taskManager = taskManager
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingL) {
            // Header
            HStack {
                GlowingText("Backup & Restore", color: CyberpunkTheme.accentPurple, font: CyberpunkTheme.fontTitle)
                Spacer()
            }
            
            // Status section
            statusSection
            
            Divider()
                .background(CyberpunkTheme.accentPurple.opacity(0.3))
            
            // Actions section
            actionsSection
            
            Divider()
                .background(CyberpunkTheme.accentPurple.opacity(0.3))
            
            // Backup list
            backupListSection
            
            Spacer()
            
            // About section
            aboutSection
        }
        .padding(CyberpunkTheme.spacingL)
        .frame(minWidth: 500, minHeight: 400)
        .background(CyberpunkTheme.backgroundPrimary)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(isSuccess ? "Success" : "Error"),
                message: Text(alertMessage ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
        .confirmationDialog(
            "Restore from Backup?",
            isPresented: $showingRestoreConfirmation,
            titleVisibility: .visible
        ) {
            Button("Restore", role: .destructive) {
                performRestore()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will replace all current tasks with the backup data. This action cannot be undone.")
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        NeonCard(color: CyberpunkTheme.accentCyan) {
            VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
                HStack {
                    Image(systemName: "externaldrive.badge.checkmark")
                        .foregroundColor(CyberpunkTheme.accentCyan)
                    Text("Database Status")
                        .font(CyberpunkTheme.fontHeadline)
                        .foregroundColor(CyberpunkTheme.textPrimary)
                }
                
                HStack(spacing: CyberpunkTheme.spacingL) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Schema Version")
                            .font(CyberpunkTheme.fontCaption)
                            .foregroundColor(CyberpunkTheme.textTertiary)
                        Text("v\(CURRENT_SCHEMA_VERSION)")
                            .font(CyberpunkTheme.fontBody)
                            .foregroundColor(CyberpunkTheme.accentGreen)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Backup")
                            .font(CyberpunkTheme.fontCaption)
                            .foregroundColor(CyberpunkTheme.textTertiary)
                        if let lastBackup = backupManager.lastBackupDate {
                            Text(formatDate(lastBackup))
                                .font(CyberpunkTheme.fontBody)
                                .foregroundColor(CyberpunkTheme.textPrimary)
                        } else {
                            Text("Never")
                                .font(CyberpunkTheme.fontBody)
                                .foregroundColor(CyberpunkTheme.accentMagenta)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Tasks")
                            .font(CyberpunkTheme.fontCaption)
                            .foregroundColor(CyberpunkTheme.textTertiary)
                        Text("\(taskManager.getAllTasks().count)")
                            .font(CyberpunkTheme.fontBody)
                            .foregroundColor(CyberpunkTheme.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Backups Available")
                            .font(CyberpunkTheme.fontCaption)
                            .foregroundColor(CyberpunkTheme.textTertiary)
                        Text("\(backupManager.availableBackups.count)")
                            .font(CyberpunkTheme.fontBody)
                            .foregroundColor(CyberpunkTheme.textPrimary)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        HStack(spacing: CyberpunkTheme.spacingM) {
            // Create Backup button
            NeonButton(
                title: backupManager.isCreatingBackup ? "Creating..." : "Create Backup",
                color: CyberpunkTheme.accentGreen
            ) {
                createBackup()
            }
            .disabled(backupManager.isCreatingBackup)
            
            // Import button
            NeonButton(title: "Import Backup", color: CyberpunkTheme.accentCyan) {
                importBackup()
            }
            
            Spacer()
            
            // Open backup folder button
            Button(action: openBackupFolder) {
                HStack(spacing: 4) {
                    Image(systemName: "folder")
                    Text("Open Backup Folder")
                }
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(CyberpunkTheme.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Backup List Section
    
    private var backupListSection: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
            Text("Available Backups")
                .font(CyberpunkTheme.fontHeadline)
                .foregroundColor(CyberpunkTheme.textSecondary)
            
            if backupManager.availableBackups.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: CyberpunkTheme.spacingS) {
                        Image(systemName: "doc.badge.clock")
                            .font(.system(size: 32))
                            .foregroundColor(CyberpunkTheme.textTertiary)
                        Text("No backups available")
                            .font(CyberpunkTheme.fontBody)
                            .foregroundColor(CyberpunkTheme.textTertiary)
                        Text("Create your first backup to protect your data")
                            .font(CyberpunkTheme.fontCaption)
                            .foregroundColor(CyberpunkTheme.textTertiary)
                    }
                    .padding(CyberpunkTheme.spacingL)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: CyberpunkTheme.spacingS) {
                        ForEach(backupManager.availableBackups) { backup in
                            BackupRowView(
                                backup: backup,
                                onRestore: {
                                    selectedBackup = backup
                                    showingRestoreConfirmation = true
                                },
                                onExport: {
                                    exportBackup(backup)
                                },
                                onDelete: {
                                    deleteBackup(backup)
                                }
                            )
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(spacing: CyberpunkTheme.spacingS) {
            Divider()
                .background(CyberpunkTheme.accentPurple.opacity(0.3))
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(AppInfo.name) v\(AppInfo.version)")
                        .font(CyberpunkTheme.fontBody)
                        .foregroundColor(CyberpunkTheme.accentPurple)
                    Text(AppInfo.copyright)
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textTertiary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(CyberpunkTheme.accentPurple)
                    .font(.system(size: 24))
            }
        }
    }
    
    // MARK: - Actions
    
    private func createBackup() {
        do {
            let url = try backupManager.createBackup()
            alertMessage = "Backup created successfully:\n\(url.lastPathComponent)"
            isSuccess = true
            showingAlert = true
        } catch {
            alertMessage = "Failed to create backup: \(error.localizedDescription)"
            isSuccess = false
            showingAlert = true
        }
    }
    
    private func performRestore() {
        guard let backup = selectedBackup else { return }
        
        do {
            let tasks = try backupManager.restoreFromBackup(backup)
            taskManager.reloadTasks()
            alertMessage = "Successfully restored \(tasks.count) tasks from backup."
            isSuccess = true
            showingAlert = true
        } catch {
            alertMessage = "Failed to restore: \(error.localizedDescription)"
            isSuccess = false
            showingAlert = true
        }
    }
    
    private func exportBackup(_ backup: BackupInfo) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = backup.isZipArchive ? [.zip] : [.json]
        panel.nameFieldStringValue = backup.url.lastPathComponent
        panel.title = "Export Backup"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try backupManager.exportBackup(backup, to: url)
                alertMessage = "Backup exported successfully."
                isSuccess = true
                showingAlert = true
            } catch {
                alertMessage = "Failed to export: \(error.localizedDescription)"
                isSuccess = false
                showingAlert = true
            }
        }
    }
    
    private func importBackup() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json, .zip]
        panel.allowsMultipleSelection = false
        panel.title = "Import Backup"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let imported = try backupManager.importBackup(from: url)
                alertMessage = "Backup imported successfully:\n\(imported.url.lastPathComponent)"
                isSuccess = true
                showingAlert = true
            } catch {
                alertMessage = "Failed to import: \(error.localizedDescription)"
                isSuccess = false
                showingAlert = true
            }
        }
    }
    
    private func deleteBackup(_ backup: BackupInfo) {
        do {
            try backupManager.deleteBackup(backup)
        } catch {
            alertMessage = "Failed to delete backup: \(error.localizedDescription)"
            isSuccess = false
            showingAlert = true
        }
    }
    
    private func openBackupFolder() {
        NSWorkspace.shared.open(backupManager.backupDirectory)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Row view for a single backup
struct BackupRowView: View {
    let backup: BackupInfo
    let onRestore: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    private var typeColor: Color {
        switch backup.backupType {
        case .manual: return CyberpunkTheme.accentPurple
        case .daily: return CyberpunkTheme.accentCyan
        case .preMigration: return CyberpunkTheme.accentMagenta
        }
    }
    
    private var iconName: String {
        backup.isZipArchive ? "doc.zipper" : "doc.text"
    }
    
    var body: some View {
        HStack(spacing: CyberpunkTheme.spacingM) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(typeColor)
                .frame(width: 32)
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: CyberpunkTheme.spacingS) {
                    Text(backup.formattedDate)
                        .font(CyberpunkTheme.fontBody)
                        .foregroundColor(CyberpunkTheme.textPrimary)
                    
                    // Backup type badge
                    Text(backup.typeLabel)
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(typeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(typeColor.opacity(0.2))
                        )
                }
                
                HStack(spacing: CyberpunkTheme.spacingS) {
                    Text(backup.formattedSize)
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textTertiary)
                    
                    if let taskCount = backup.taskCount {
                        Text("•")
                            .foregroundColor(CyberpunkTheme.textTertiary)
                        Text("\(taskCount) tasks")
                            .font(CyberpunkTheme.fontCaption)
                            .foregroundColor(CyberpunkTheme.textTertiary)
                    }
                    
                    if backup.screenshotCount > 0 {
                        Text("•")
                            .foregroundColor(CyberpunkTheme.textTertiary)
                        HStack(spacing: 2) {
                            Image(systemName: "photo")
                                .font(.system(size: 10))
                            Text("\(backup.screenshotCount)")
                        }
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            // Actions (visible on hover)
            if isHovered {
                HStack(spacing: CyberpunkTheme.spacingS) {
                    Button(action: onRestore) {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(CyberpunkTheme.accentGreen)
                    }
                    .buttonStyle(.plain)
                    .help("Restore from this backup")
                    
                    Button(action: onExport) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(CyberpunkTheme.accentCyan)
                    }
                    .buttonStyle(.plain)
                    .help("Export backup")
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(CyberpunkTheme.accentMagenta)
                    }
                    .buttonStyle(.plain)
                    .help("Delete backup")
                }
            }
        }
        .padding(CyberpunkTheme.spacingS)
        .background(
            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                .fill(isHovered ? CyberpunkTheme.backgroundSecondary : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
