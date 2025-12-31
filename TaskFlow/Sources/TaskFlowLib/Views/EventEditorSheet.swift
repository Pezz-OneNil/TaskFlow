import SwiftUI

/// Event editor sheet for creating and editing calendar events
/// Per Requirements 4.2, 4.6, 4.7, 8.4
/// Feature: annual-calendar
public struct EventEditorSheet: View {
    @ObservedObject var categoryManager: EventCategoryManager
    
    @State private var selectedCategoryId: Int
    @State private var label: String
    @State private var startDate: Date
    @State private var endDate: Date
    
    private let existingEvent: CalendarEvent?
    private let onSave: (CalendarEvent) -> Void
    private let onDelete: (() -> Void)?
    private let onCancel: () -> Void
    
    /// Initialize for editing an existing event
    public init(
        event: CalendarEvent,
        categoryManager: EventCategoryManager,
        onSave: @escaping (CalendarEvent) -> Void,
        onDelete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.existingEvent = event
        self.categoryManager = categoryManager
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        
        _selectedCategoryId = State(initialValue: event.categoryId)
        _label = State(initialValue: event.label)
        _startDate = State(initialValue: event.startDate)
        _endDate = State(initialValue: event.endDate)
    }
    
    /// Initialize for creating a new event
    public init(
        startDate: Date,
        endDate: Date,
        categoryManager: EventCategoryManager,
        onSave: @escaping (CalendarEvent) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.existingEvent = nil
        self.categoryManager = categoryManager
        self.onSave = onSave
        self.onDelete = nil
        self.onCancel = onCancel
        
        _selectedCategoryId = State(initialValue: 1)
        _label = State(initialValue: "")
        _startDate = State(initialValue: startDate)
        _endDate = State(initialValue: endDate)
    }
    
    private var isEditing: Bool {
        existingEvent != nil
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
                .background(CyberpunkTheme.accentYellow.opacity(0.3))
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: CyberpunkTheme.spacingL) {
                    // Category picker
                    categoryPicker
                    
                    // Label field
                    labelField
                    
                    // Date pickers
                    datePickers
                }
                .padding(CyberpunkTheme.spacingL)
            }
            
            Divider()
                .background(CyberpunkTheme.accentYellow.opacity(0.3))
            
            // Footer with buttons
            footerView
        }
        .frame(width: 400, height: 500)
        .background(CyberpunkTheme.backgroundPrimary)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Text(isEditing ? "Edit Event" : "New Event")
                .font(CyberpunkTheme.fontTitle)
                .foregroundColor(CyberpunkTheme.accentYellow)
            
            Spacer()
            
            Button(action: onCancel) {
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
    
    // MARK: - Category Picker
    
    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
            Text("Category")
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(CyberpunkTheme.textSecondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: CyberpunkTheme.spacingS) {
                ForEach(categoryManager.categories, id: \.id) { category in
                    CategoryOptionView(
                        category: category,
                        isSelected: selectedCategoryId == category.id,
                        onSelect: { selectedCategoryId = category.id }
                    )
                }
            }
        }
    }
    
    // MARK: - Label Field
    
    private var labelField: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
            Text("Label")
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(CyberpunkTheme.textSecondary)
            
            TextField("Event description...", text: $label)
                .textFieldStyle(.plain)
                .font(CyberpunkTheme.fontBody)
                .foregroundColor(CyberpunkTheme.textPrimary)
                .padding(CyberpunkTheme.spacingS)
                .background(
                    RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                        .fill(CyberpunkTheme.backgroundSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                                .stroke(CyberpunkTheme.textTertiary.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
    
    // MARK: - Date Pickers
    
    private var datePickers: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingM) {
            // Start date
            VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
                Text("Start Date")
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.textSecondary)
                
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .onChange(of: startDate) { newValue in
                        if endDate < newValue {
                            endDate = newValue
                        }
                    }
            }
            
            // End date
            VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
                Text("End Date")
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.textSecondary)
                
                DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
        }
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            // Delete button (only for existing events)
            if isEditing, let onDelete = onDelete {
                Button(action: onDelete) {
                    HStack(spacing: CyberpunkTheme.spacingXS) {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.accentMagenta)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // Cancel button
            Button(action: onCancel) {
                Text("Cancel")
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.textSecondary)
                    .padding(.horizontal, CyberpunkTheme.spacingM)
                    .padding(.vertical, CyberpunkTheme.spacingS)
                    .background(
                        RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                            .stroke(CyberpunkTheme.textTertiary.opacity(0.5), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            
            // Save button
            Button(action: saveEvent) {
                Text(isEditing ? "Save" : "Create")
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
            .keyboardShortcut(.return, modifiers: [])
        }
        .padding(CyberpunkTheme.spacingM)
        .background(CyberpunkTheme.backgroundSecondary)
    }
    
    // MARK: - Actions
    
    private func saveEvent() {
        let event: CalendarEvent
        if let existing = existingEvent {
            event = CalendarEvent(
                id: existing.id,
                categoryId: selectedCategoryId,
                startDate: startDate,
                endDate: endDate,
                label: label,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
        } else {
            event = CalendarEvent(
                categoryId: selectedCategoryId,
                startDate: startDate,
                endDate: endDate,
                label: label
            )
        }
        onSave(event)
    }
}

/// Category option view for the picker
struct CategoryOptionView: View {
    let category: EventCategory
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: CyberpunkTheme.spacingS) {
                // Color swatch
                RoundedRectangle(cornerRadius: 4)
                    .fill(category.color.color)
                    .frame(width: 20, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                    )
                
                // Name
                Text(category.name)
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(isSelected ? CyberpunkTheme.textPrimary : CyberpunkTheme.textSecondary)
                    .lineLimit(1)
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(category.color.color)
                }
            }
            .padding(CyberpunkTheme.spacingS)
            .background(
                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                    .fill(isSelected ? category.color.color.opacity(0.2) : CyberpunkTheme.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                            .stroke(isSelected ? category.color.color : (isHovered ? CyberpunkTheme.textTertiary : Color.clear), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
