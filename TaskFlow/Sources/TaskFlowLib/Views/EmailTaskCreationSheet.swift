// ═══════════════════════════════════════════════════════════════════════════════
// TaskFlow - Intelligent Task Management for macOS
// © 2025 Pezz. All rights reserved.
// ═══════════════════════════════════════════════════════════════════════════════

import SwiftUI

/// Sheet for creating a task from a dropped email
/// Per Requirements 5.1-5.7
public struct EmailTaskCreationSheet: View {
    let result: EmailDropResult
    @ObservedObject var taskManager: TaskManager
    let onDismiss: () -> Void
    
    @State private var title: String = ""
    @State private var taskDescription: String = ""
    @State private var priority: Priority = .medium
    @State private var timeEstimate: TimeEstimate = .twenty
    @State private var showEmailDetails = true
    
    @Environment(\.dismiss) private var dismiss
    
    public init(result: EmailDropResult, taskManager: TaskManager, onDismiss: @escaping () -> Void) {
        self.result = result
        self.taskManager = taskManager
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
                .background(CyberpunkTheme.accentPurple.opacity(0.3))
            
            ScrollView {
                VStack(alignment: .leading, spacing: CyberpunkTheme.spacingL) {
                    // Email metadata section
                    if let email = result.parsedEmail {
                        emailMetadataSection(email: email)
                    }
                    
                    // Task details section
                    taskDetailsSection
                    
                    // Priority section
                    prioritySection
                    
                    // Time estimate section
                    timeEstimateSection
                }
                .padding(CyberpunkTheme.spacingL)
            }
            
            Divider()
                .background(CyberpunkTheme.accentPurple.opacity(0.3))
            
            // Action buttons
            actionButtons
        }
        .frame(width: 550, height: 650)
        .background(CyberpunkTheme.backgroundPrimary)
        .onAppear {
            // Initialize with suggested values
            title = result.suggestedTitle ?? result.parsedEmail?.subject ?? ""
            taskDescription = result.suggestedDescription ?? ""
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 24))
                .foregroundColor(CyberpunkTheme.accentMagenta)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Create Task from Email")
                    .font(CyberpunkTheme.fontTitle)
                    .foregroundColor(CyberpunkTheme.textPrimary)
                
                Text(result.fileURL.lastPathComponent)
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.textTertiary)
            }
            
            Spacer()
            
            Button(action: { 
                dismiss()
                onDismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(CyberpunkTheme.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(CyberpunkTheme.spacingM)
        .background(CyberpunkTheme.backgroundSecondary)
    }
    
    // MARK: - Email Metadata Section
    
    private func emailMetadataSection(email: ParsedEmail) -> some View {
        NeonCard(color: CyberpunkTheme.accentCyan) {
            VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
                // Collapsible header
                Button(action: {
                    withAnimation {
                        showEmailDetails.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(CyberpunkTheme.accentCyan)
                        Text("Email Details")
                            .font(CyberpunkTheme.fontHeadline)
                            .foregroundColor(CyberpunkTheme.textPrimary)
                        Spacer()
                        Image(systemName: showEmailDetails ? "chevron.up" : "chevron.down")
                            .foregroundColor(CyberpunkTheme.textTertiary)
                    }
                }
                .buttonStyle(.plain)
                
                if showEmailDetails {
                    Divider()
                        .background(CyberpunkTheme.accentCyan.opacity(0.3))
                    
                    // From
                    metadataRow(label: "From", value: email.sender.displayString)
                    
                    // To
                    if !email.recipients.isEmpty {
                        metadataRow(label: "To", value: email.recipients.map { $0.displayString }.joined(separator: ", "))
                    }
                    
                    // Subject
                    metadataRow(label: "Subject", value: email.subject)
                    
                    // Date
                    metadataRow(label: "Date", value: formatDate(email.date))
                    
                    // Thread info
                    if email.messages.count > 1 {
                        metadataRow(label: "Thread", value: "\(email.messages.count) messages")
                    }
                }
            }
        }
    }
    
    private func metadataRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: CyberpunkTheme.spacingS) {
            Text(label + ":")
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(CyberpunkTheme.textTertiary)
                .frame(width: 60, alignment: .trailing)
            
            Text(value)
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(CyberpunkTheme.textSecondary)
                .lineLimit(2)
            
            Spacer()
        }
    }
    
    // MARK: - Task Details Section
    
    private var taskDetailsSection: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingM) {
            // Title
            VStack(alignment: .leading, spacing: CyberpunkTheme.spacingXS) {
                Text("Task Title")
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.textSecondary)
                
                TextField("Enter task title", text: $title)
                    .textFieldStyle(.plain)
                    .font(CyberpunkTheme.fontBody)
                    .foregroundColor(CyberpunkTheme.textPrimary)
                    .padding(CyberpunkTheme.spacingS)
                    .background(
                        RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                            .fill(CyberpunkTheme.backgroundSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                                    .stroke(CyberpunkTheme.accentPurple.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            
            // Description
            VStack(alignment: .leading, spacing: CyberpunkTheme.spacingXS) {
                Text("Description")
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.textSecondary)
                
                TextEditor(text: $taskDescription)
                    .font(CyberpunkTheme.fontBody)
                    .foregroundColor(CyberpunkTheme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100, maxHeight: 150)
                    .padding(CyberpunkTheme.spacingS)
                    .background(
                        RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                            .fill(CyberpunkTheme.backgroundSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                                    .stroke(CyberpunkTheme.accentPurple.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
        }
    }
    
    // MARK: - Priority Section
    
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingXS) {
            Text("Priority")
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(CyberpunkTheme.textSecondary)
            
            HStack(spacing: CyberpunkTheme.spacingS) {
                ForEach(Priority.allCases, id: \.self) { p in
                    EmailPriorityButton(
                        priority: p,
                        isSelected: priority == p
                    ) {
                        priority = p
                    }
                }
            }
        }
    }
    
    // MARK: - Time Estimate Section
    
    private var timeEstimateSection: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingXS) {
            Text("Time Estimate")
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(CyberpunkTheme.textSecondary)
            
            HStack(spacing: CyberpunkTheme.spacingS) {
                ForEach(TimeEstimate.allCases, id: \.self) { estimate in
                    EmailTimeEstimateButton(
                        estimate: estimate,
                        isSelected: timeEstimate == estimate
                    ) {
                        timeEstimate = estimate
                    }
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: CyberpunkTheme.spacingM) {
            // Cancel button
            Button(action: {
                dismiss()
                onDismiss()
            }) {
                Text("Cancel")
                    .font(CyberpunkTheme.fontBody)
                    .foregroundColor(CyberpunkTheme.textSecondary)
                    .padding(.horizontal, CyberpunkTheme.spacingL)
                    .padding(.vertical, CyberpunkTheme.spacingS)
                    .background(
                        RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                            .stroke(CyberpunkTheme.textTertiary, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Create button
            Button(action: createTaskFromEmail) {
                HStack(spacing: CyberpunkTheme.spacingXS) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Task")
                }
                .font(CyberpunkTheme.fontBody)
                .foregroundColor(.white)
                .padding(.horizontal, CyberpunkTheme.spacingL)
                .padding(.vertical, CyberpunkTheme.spacingS)
                .background(
                    RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                        .fill(CyberpunkTheme.accentPurple)
                )
            }
            .buttonStyle(.plain)
            .disabled(title.isEmpty)
        }
        .padding(CyberpunkTheme.spacingM)
        .background(CyberpunkTheme.backgroundSecondary)
    }
    
    // MARK: - Actions
    
    private func createTaskFromEmail() {
        var task = taskManager.createTask(
            title: title,
            description: taskDescription,
            timeEstimate: timeEstimate,
            priority: priority
        )
        
        // Add email metadata and body content
        if let email = result.parsedEmail {
            task.metadata.sender = email.sender.displayString
            task.metadata.subject = email.subject
            task.furtherDetails = email.body
        }
        
        _ = taskManager.updateTask(task)
        
        dismiss()
        onDismiss()
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Email Priority Button

private struct EmailPriorityButton: View {
    let priority: Priority
    let isSelected: Bool
    let action: () -> Void
    
    private var priorityColor: Color {
        switch priority {
        case .low: return CyberpunkTheme.accentGreen
        case .medium: return CyberpunkTheme.accentCyan
        case .mega: return CyberpunkTheme.accentMagenta
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)
                Text(priority.displayName)
                    .font(CyberpunkTheme.fontCaption)
            }
            .foregroundColor(isSelected ? CyberpunkTheme.textPrimary : CyberpunkTheme.textTertiary)
            .padding(.horizontal, CyberpunkTheme.spacingS)
            .padding(.vertical, CyberpunkTheme.spacingXS)
            .background(
                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                    .fill(isSelected ? priorityColor.opacity(0.2) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                            .stroke(isSelected ? priorityColor : CyberpunkTheme.textTertiary.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Email Time Estimate Button

private struct EmailTimeEstimateButton: View {
    let estimate: TimeEstimate
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(estimate.displayName)
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(isSelected ? CyberpunkTheme.textPrimary : CyberpunkTheme.textTertiary)
                .padding(.horizontal, CyberpunkTheme.spacingS)
                .padding(.vertical, CyberpunkTheme.spacingXS)
                .background(
                    RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                        .fill(isSelected ? CyberpunkTheme.accentCyan.opacity(0.2) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                                .stroke(isSelected ? CyberpunkTheme.accentCyan : CyberpunkTheme.textTertiary.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
