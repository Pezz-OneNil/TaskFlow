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

/// Settings section navigation
public enum SettingsSection: String, CaseIterable, Identifiable {
    case backup = "Backup & Restore"
    case integrations = "Integrations"
    case about = "About"
    
    public var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .backup: return "externaldrive"
        case .integrations: return "puzzlepiece.extension"
        case .about: return "info.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .backup: return CyberpunkTheme.accentCyan
        case .integrations: return CyberpunkTheme.accentMagenta
        case .about: return CyberpunkTheme.accentPurple
        }
    }
}

/// View for managing backups and restoration
/// Per Requirement 20 (Data Migration and Upgrade Safety)
public struct BackupRestoreView: View {
    @ObservedObject var backupManager: BackupManager
    @ObservedObject var taskManager: TaskManager
    
    @State private var selectedSection: SettingsSection = .backup
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
        HStack(spacing: 0) {
            // Sidebar navigation
            settingsSidebar
            
            Divider()
                .background(CyberpunkTheme.accentPurple.opacity(0.3))
            
            // Content area
            ScrollView {
                VStack(alignment: .leading, spacing: CyberpunkTheme.spacingL) {
                    switch selectedSection {
                    case .backup:
                        backupContent
                    case .integrations:
                        integrationsContent
                    case .about:
                        aboutContent
                    }
                }
                .padding(CyberpunkTheme.spacingL)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
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
    
    // MARK: - Settings Sidebar
    
    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingXS) {
            Text("Settings")
                .font(CyberpunkTheme.fontHeadline)
                .foregroundColor(CyberpunkTheme.textPrimary)
                .padding(.horizontal, CyberpunkTheme.spacingM)
                .padding(.top, CyberpunkTheme.spacingM)
                .padding(.bottom, CyberpunkTheme.spacingS)
            
            ForEach(SettingsSection.allCases) { section in
                SettingsSidebarButton(
                    section: section,
                    isSelected: selectedSection == section
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedSection = section
                    }
                }
            }
            
            Spacer()
        }
        .frame(width: 160)
        .background(CyberpunkTheme.backgroundSecondary)
    }
    
    // MARK: - Backup Content
    
    private var backupContent: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingL) {
            // Section header
            HStack {
                Image(systemName: "externaldrive")
                    .foregroundColor(CyberpunkTheme.accentCyan)
                    .font(.system(size: 20))
                Text("Backup & Restore")
                    .font(CyberpunkTheme.fontTitle)
                    .foregroundColor(CyberpunkTheme.textPrimary)
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
        }
    }
    
    // MARK: - Integrations Content
    
    private var integrationsContent: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingL) {
            // Section header
            HStack {
                Image(systemName: "puzzlepiece.extension")
                    .foregroundColor(CyberpunkTheme.accentMagenta)
                    .font(.system(size: 20))
                Text("Integrations")
                    .font(CyberpunkTheme.fontTitle)
                    .foregroundColor(CyberpunkTheme.textPrimary)
            }
            
            Text("Connect TaskFlow with external applications to enhance your workflow.")
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(CyberpunkTheme.textSecondary)
            
            // Email Integration (drag and drop .eml files)
            EmailSettingsSection(settingsManager: SettingsManager.shared)
        }
    }
    
    // MARK: - About Content
    
    private var aboutContent: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingL) {
            // Section header
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(CyberpunkTheme.accentPurple)
                    .font(.system(size: 20))
                Text("About")
                    .font(CyberpunkTheme.fontTitle)
                    .foregroundColor(CyberpunkTheme.textPrimary)
            }
            
            aboutSection
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
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingM) {
            // App info card
            NeonCard(color: CyberpunkTheme.accentPurple) {
                VStack(alignment: .leading, spacing: CyberpunkTheme.spacingM) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(AppInfo.name)
                                .font(CyberpunkTheme.fontHeadline)
                                .foregroundColor(CyberpunkTheme.textPrimary)
                            Text("Version \(AppInfo.version)")
                                .font(CyberpunkTheme.fontBody)
                                .foregroundColor(CyberpunkTheme.accentPurple)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(CyberpunkTheme.accentPurple)
                            .font(.system(size: 32))
                    }
                    
                    Divider()
                        .background(CyberpunkTheme.accentPurple.opacity(0.3))
                    
                    Text(AppInfo.copyright)
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textTertiary)
                    
                    // Database info
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
                            Text("Total Tasks")
                                .font(CyberpunkTheme.fontCaption)
                                .foregroundColor(CyberpunkTheme.textTertiary)
                            Text("\(taskManager.getAllTasks().count)")
                                .font(CyberpunkTheme.fontBody)
                                .foregroundColor(CyberpunkTheme.textPrimary)
                        }
                    }
                }
            }
            
            // How to Use section
            howToUseSection
        }
    }
    
    // MARK: - How to Use Section
    
    private var howToUseSection: some View {
        NeonCard(color: CyberpunkTheme.accentCyan) {
            VStack(alignment: .leading, spacing: CyberpunkTheme.spacingM) {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(CyberpunkTheme.accentCyan)
                    Text("How to Use TaskFlow")
                        .font(CyberpunkTheme.fontHeadline)
                        .foregroundColor(CyberpunkTheme.textPrimary)
                }
                
                Divider()
                    .background(CyberpunkTheme.accentCyan.opacity(0.3))
                
                VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
                    // Screen Capture
                    featureRow(
                        icon: "camera.viewfinder",
                        title: "Screen Capture",
                        shortcut: "⌘⇧C",
                        description: "Capture any part of your screen to create a task. OCR extracts text automatically, and AI can generate a title.",
                        color: CyberpunkTheme.accentPurple
                    )
                    
                    // Email Drag & Drop
                    featureRow(
                        icon: "envelope.badge.fill",
                        title: "Email Drag & Drop",
                        shortcut: nil,
                        description: "Drag .eml files from Finder or your email client directly into TaskFlow to create tasks from emails.",
                        color: CyberpunkTheme.accentMagenta
                    )
                    
                    // Pomodoro Timer
                    featureRow(
                        icon: "timer",
                        title: "Pomodoro Timer",
                        shortcut: nil,
                        description: "Use the Pomodoro tab to focus on tasks with timed work sessions. Select a task and start a focused session.",
                        color: CyberpunkTheme.accentCyan
                    )
                    
                    // Kanban Board
                    featureRow(
                        icon: "rectangle.3.group",
                        title: "Kanban Board",
                        shortcut: nil,
                        description: "Organize tasks visually across Backlog, In Progress, Blocked, and Done columns. Drag tasks between columns.",
                        color: CyberpunkTheme.accentGreen
                    )
                    
                    // Task Management
                    featureRow(
                        icon: "checklist",
                        title: "Task Management",
                        shortcut: nil,
                        description: "Set priorities, time estimates, and assignees. Use the search bar to filter tasks. Click any task to view details.",
                        color: CyberpunkTheme.accentPurple
                    )
                }
            }
        }
    }
    
    private func featureRow(icon: String, title: String, shortcut: String?, description: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: CyberpunkTheme.spacingS) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: CyberpunkTheme.spacingS) {
                    Text(title)
                        .font(CyberpunkTheme.fontBody)
                        .foregroundColor(CyberpunkTheme.textPrimary)
                    
                    if let shortcut = shortcut {
                        Text(shortcut)
                            .font(CyberpunkTheme.fontCaption)
                            .foregroundColor(color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(color.opacity(0.2))
                            )
                    }
                }
                
                Text(description)
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
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

/// Sidebar button for settings navigation
struct SettingsSidebarButton: View {
    let section: SettingsSection
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: CyberpunkTheme.spacingS) {
                Image(systemName: section.icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                Text(section.rawValue)
                    .font(CyberpunkTheme.fontCaption)
                Spacer()
            }
            .foregroundColor(isSelected ? section.color : CyberpunkTheme.textSecondary)
            .padding(.horizontal, CyberpunkTheme.spacingM)
            .padding(.vertical, CyberpunkTheme.spacingS)
            .background(
                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                    .fill(isSelected ? section.color.opacity(0.15) : (isHovered ? CyberpunkTheme.backgroundPrimary.opacity(0.5) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                    .stroke(isSelected ? section.color.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, CyberpunkTheme.spacingXS)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
