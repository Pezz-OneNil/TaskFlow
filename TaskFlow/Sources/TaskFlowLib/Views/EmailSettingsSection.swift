// ═══════════════════════════════════════════════════════════════════════════════
// TaskFlow - Intelligent Task Management for macOS
// © 2025 Pezz. All rights reserved.
// ═══════════════════════════════════════════════════════════════════════════════

import SwiftUI
import AppKit

/// Settings section for Email drag-and-drop integration
/// Feature: email-drag-drop
/// Per Requirements 7.1, 7.2, 7.3, 7.4, 7.5
public struct EmailSettingsSection: View {
    @ObservedObject var settingsManager: SettingsManager
    
    public init(settingsManager: SettingsManager = .shared) {
        self.settingsManager = settingsManager
    }
    
    public var body: some View {
        NeonCard(color: CyberpunkTheme.accentMagenta) {
            VStack(alignment: .leading, spacing: CyberpunkTheme.spacingM) {
                // Header
                HStack {
                    Image(systemName: "envelope.badge")
                        .foregroundColor(CyberpunkTheme.accentMagenta)
                        .font(.system(size: 20))
                    Text("Email Integration")
                        .font(CyberpunkTheme.fontHeadline)
                        .foregroundColor(CyberpunkTheme.textPrimary)
                    Spacer()
                    
                    // Status indicator
                    statusBadge
                }
                
                // Description
                Text("Drag and drop .eml files into TaskFlow to create tasks with AI-generated summaries.")
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.textSecondary)
                
                Divider()
                    .background(CyberpunkTheme.accentMagenta.opacity(0.3))
                
                // Email Drop Toggle
                HStack {
                    Toggle(isOn: $settingsManager.emailDropEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable Email Drop")
                                .font(CyberpunkTheme.fontBody)
                                .foregroundColor(CyberpunkTheme.textPrimary)
                            Text(settingsManager.emailDropEnabled 
                                 ? "Drag .eml files onto TaskFlow to create tasks"
                                 : "Enable to accept email files via drag and drop")
                                .font(CyberpunkTheme.fontCaption)
                                .foregroundColor(CyberpunkTheme.textTertiary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: CyberpunkTheme.accentMagenta))
                }
                
                // Auto-create toggle (only shown when email drop is enabled)
                if settingsManager.emailDropEnabled {
                    HStack {
                        Toggle(isOn: $settingsManager.emailAutoCreateTasks) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto-create Tasks")
                                    .font(CyberpunkTheme.fontBody)
                                    .foregroundColor(CyberpunkTheme.textPrimary)
                                Text(settingsManager.emailAutoCreateTasks 
                                     ? "Tasks created automatically without confirmation"
                                     : "Show task creation dialog for review before creating")
                                    .font(CyberpunkTheme.fontCaption)
                                    .foregroundColor(CyberpunkTheme.textTertiary)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: CyberpunkTheme.accentCyan))
                    }
                    
                    // Usage instructions
                    usageInstructions
                } else {
                    disabledInfo
                }
            }
        }
    }
    
    // MARK: - Status Badge
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(settingsManager.emailDropEnabled 
                      ? CyberpunkTheme.accentGreen 
                      : CyberpunkTheme.textTertiary)
                .frame(width: 8, height: 8)
            Text(settingsManager.emailDropEnabled ? "Enabled" : "Disabled")
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(settingsManager.emailDropEnabled 
                                 ? CyberpunkTheme.accentGreen 
                                 : CyberpunkTheme.textTertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                .fill((settingsManager.emailDropEnabled 
                       ? CyberpunkTheme.accentGreen 
                       : CyberpunkTheme.textTertiary).opacity(0.15))
        )
    }
    
    // MARK: - Usage Instructions
    
    private var usageInstructions: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(CyberpunkTheme.accentCyan)
                Text("How to Use")
                    .font(CyberpunkTheme.fontBody)
                    .foregroundColor(CyberpunkTheme.accentCyan)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                instructionStep(1, "Export an email as .eml from your mail client")
                instructionStep(2, "Drag the .eml file onto the TaskFlow window")
                instructionStep(3, "TaskFlow will parse the email and generate a task summary")
                instructionStep(4, "Review and confirm the task details")
            }
            .padding(CyberpunkTheme.spacingS)
            .background(
                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                    .fill(CyberpunkTheme.backgroundSecondary)
            )
            
            // Supported mail clients
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(CyberpunkTheme.accentGreen)
                    .font(.system(size: 12))
                Text("Works with Apple Mail, Outlook, Gmail (exported), and other mail clients")
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.textTertiary)
            }
        }
    }
    
    // MARK: - Disabled Info
    
    private var disabledInfo: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb")
                    .foregroundColor(CyberpunkTheme.textTertiary)
                Text("Enable email drop to create tasks from emails")
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.textTertiary)
            }
            
            // Features list
            VStack(alignment: .leading, spacing: 4) {
                featureItem("Drag and drop .eml files to create tasks")
                featureItem("AI-generated task titles and descriptions")
                featureItem("Automatic email thread parsing")
                featureItem("Works with any mail client that exports .eml")
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func instructionStep(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(CyberpunkTheme.accentMagenta)
                .frame(width: 16, alignment: .trailing)
            Text(text)
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(CyberpunkTheme.textSecondary)
        }
    }
    
    private func featureItem(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle")
                .foregroundColor(CyberpunkTheme.accentGreen.opacity(0.6))
                .font(.system(size: 12))
            Text(text)
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(CyberpunkTheme.textTertiary)
        }
    }
}
