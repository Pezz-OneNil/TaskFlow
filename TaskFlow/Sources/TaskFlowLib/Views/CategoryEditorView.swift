import SwiftUI

/// Category editor view for editing category names
/// Per Requirements 3.2, 3.3
/// Feature: annual-calendar
public struct CategoryEditorView: View {
    @ObservedObject var categoryManager: EventCategoryManager
    let onDismiss: () -> Void
    
    @State private var editingCategoryId: Int?
    @State private var editingName: String = ""
    
    public init(categoryManager: EventCategoryManager, onDismiss: @escaping () -> Void) {
        self.categoryManager = categoryManager
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
                .background(CyberpunkTheme.accentYellow.opacity(0.3))
            
            // Category list
            ScrollView {
                VStack(spacing: CyberpunkTheme.spacingS) {
                    ForEach(categoryManager.categories, id: \.id) { category in
                        CategoryEditorRow(
                            category: category,
                            isEditing: editingCategoryId == category.id,
                            editingName: editingCategoryId == category.id ? $editingName : .constant(category.name),
                            onStartEdit: {
                                editingCategoryId = category.id
                                editingName = category.name
                            },
                            onSave: {
                                categoryManager.updateCategoryName(id: category.id, name: editingName)
                                editingCategoryId = nil
                            },
                            onCancel: {
                                editingCategoryId = nil
                            }
                        )
                    }
                }
                .padding(CyberpunkTheme.spacingM)
            }
            
            Divider()
                .background(CyberpunkTheme.accentYellow.opacity(0.3))
            
            // Footer
            footerView
        }
        .frame(width: 350, height: 500)
        .background(CyberpunkTheme.backgroundPrimary)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Text("Edit Categories")
                .font(CyberpunkTheme.fontTitle)
                .foregroundColor(CyberpunkTheme.accentYellow)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(CyberpunkTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(CyberpunkTheme.spacingM)
        .background(CyberpunkTheme.backgroundSecondary)
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            Button(action: {
                categoryManager.resetToDefaults()
            }) {
                Text("Reset to Defaults")
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.accentMagenta)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: onDismiss) {
                Text("Done")
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.backgroundPrimary)
                    .padding(.horizontal, CyberpunkTheme.spacingM)
                    .padding(.vertical, CyberpunkTheme.spacingS)
                    .background(
                        RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                            .fill(CyberpunkTheme.accentYellow)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(CyberpunkTheme.spacingM)
        .background(CyberpunkTheme.backgroundSecondary)
    }
}

/// Row for editing a single category
struct CategoryEditorRow: View {
    let category: EventCategory
    let isEditing: Bool
    @Binding var editingName: String
    let onStartEdit: () -> Void
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: CyberpunkTheme.spacingM) {
            // Color swatch
            RoundedRectangle(cornerRadius: 4)
                .fill(category.color.color)
                .frame(width: 24, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            
            // Name (editable or display)
            if isEditing {
                TextField("Category name", text: $editingName)
                    .textFieldStyle(.plain)
                    .font(CyberpunkTheme.fontBody)
                    .foregroundColor(CyberpunkTheme.textPrimary)
                    .padding(.horizontal, CyberpunkTheme.spacingS)
                    .padding(.vertical, CyberpunkTheme.spacingXS)
                    .background(
                        RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                            .fill(CyberpunkTheme.backgroundPrimary)
                            .overlay(
                                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                                    .stroke(CyberpunkTheme.accentYellow, lineWidth: 1)
                            )
                    )
                    .onSubmit {
                        onSave()
                    }
                
                // Save/Cancel buttons
                HStack(spacing: CyberpunkTheme.spacingXS) {
                    Button(action: onSave) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(CyberpunkTheme.accentGreen)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(CyberpunkTheme.accentMagenta)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text(category.name)
                    .font(CyberpunkTheme.fontBody)
                    .foregroundColor(CyberpunkTheme.textPrimary)
                
                Spacer()
                
                // Edit button (visible on hover)
                if isHovered {
                    Button(action: onStartEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(CyberpunkTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(CyberpunkTheme.spacingS)
        .background(
            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                .fill(isHovered || isEditing ? CyberpunkTheme.backgroundSecondary : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
