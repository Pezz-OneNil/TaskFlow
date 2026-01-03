import SwiftUI

/// Kanban board view with five columns (including Deleted) and multi-select support
/// Per Requirements 1.5, 1.7, 2.1-2.6, 5.1, 5.2, 5.8
public struct KanbanBoardView: View {
    @ObservedObject var taskManager: TaskManager
    @ObservedObject private var selectionManager = SelectionManager.shared
    let searchQuery: String
    let filterTasks: ([TFMTask]) -> [TFMTask]
    let onMoveColumn: (TFMTask, TFMKanbanColumn) -> Void
    let onMoveToActive: (TFMTask) -> Void
    let onComplete: (TFMTask) -> Void
    let onRestore: (TFMTask) -> Void
    let onPermanentDelete: (TFMTask) -> Void
    let onEdit: (TFMTask) -> Void
    let onStatusMessage: ((String) -> Void)?
    
    @State private var showingDeleteConfirmation = false
    
    public init(
        taskManager: TaskManager,
        searchQuery: String = "",
        filterTasks: @escaping ([TFMTask]) -> [TFMTask] = { $0 },
        onMoveColumn: @escaping (TFMTask, TFMKanbanColumn) -> Void = { _, _ in },
        onMoveToActive: @escaping (TFMTask) -> Void = { _ in },
        onComplete: @escaping (TFMTask) -> Void = { _ in },
        onRestore: @escaping (TFMTask) -> Void = { _ in },
        onPermanentDelete: @escaping (TFMTask) -> Void = { _ in },
        onEdit: @escaping (TFMTask) -> Void = { _ in },
        onStatusMessage: ((String) -> Void)? = nil
    ) {
        self.taskManager = taskManager
        self.searchQuery = searchQuery
        self.filterTasks = filterTasks
        self.onMoveColumn = onMoveColumn
        self.onMoveToActive = onMoveToActive
        self.onComplete = onComplete
        self.onRestore = onRestore
        self.onPermanentDelete = onPermanentDelete
        self.onEdit = onEdit
        self.onStatusMessage = onStatusMessage
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingM) {
            // Selection indicator bar
            if selectionManager.hasSelection {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(CyberpunkTheme.accentCyan)
                    Text("\(selectionManager.selectionCount) card(s) selected")
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textSecondary)
                    
                    Spacer()
                    
                    Button(action: { showingDeleteConfirmation = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.accentMagenta)
                    }
                    .buttonStyle(.plain)
                    .help("Delete selected cards (⌫)")
                    
                    Button(action: { selectionManager.clearSelection() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                            Text("Clear")
                        }
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .help("Clear selection (Esc)")
                }
                .padding(.horizontal, CyberpunkTheme.spacingM)
                .padding(.vertical, CyberpunkTheme.spacingS)
                .background(CyberpunkTheme.backgroundSecondary.opacity(0.8))
            }
            
            // Search results indicator
            if !searchQuery.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(CyberpunkTheme.accentCyan)
                    Text("Filtering Kanban for \"\(searchQuery)\"")
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textSecondary)
                }
                .padding(.horizontal, CyberpunkTheme.spacingM)
                .padding(.top, CyberpunkTheme.spacingS)
            }
            
            // Columns - use GeometryReader for equal width distribution
            GeometryReader { geometry in
                let columnCount = CGFloat(TFMKanbanColumn.allCases.count)
                let totalSpacing = CyberpunkTheme.spacingM * (columnCount - 1) + CyberpunkTheme.spacingM * 2 // spacing between + padding
                let availableWidth = geometry.size.width - totalSpacing
                let columnWidth = max(140, availableWidth / columnCount) // Minimum 140px per column
                
                HStack(alignment: .top, spacing: CyberpunkTheme.spacingM) {
                    ForEach(TFMKanbanColumn.allCases, id: \.self) { column in
                        KanbanColumnView(
                            column: column,
                            tasks: tasksForColumn(column),
                            taskManager: taskManager,
                            onMoveColumn: onMoveColumn,
                            onMoveToActive: onMoveToActive,
                            onComplete: onComplete,
                            onRestore: onRestore,
                            onPermanentDelete: onPermanentDelete,
                            onEdit: onEdit
                        )
                        .frame(width: columnWidth)
                    }
                }
                .padding(.horizontal, CyberpunkTheme.spacingM)
            }
            .padding(.top, CyberpunkTheme.spacingS)
        }
        .background(CyberpunkTheme.backgroundPrimary)
        .contentShape(Rectangle()) // Make entire area clickable for deselection
        .onTapGesture {
            // Click on empty space clears selection
            // Per Requirement 1.5
            selectionManager.clearSelection()
        }
        .background(
            KeyboardEventHandler(
                onDelete: {
                    // Delete key: trigger bulk deletion
                    // Per Requirement 2.1
                    if selectionManager.hasSelection {
                        showingDeleteConfirmation = true
                    }
                },
                onEscape: {
                    // Escape key: clear selection
                    // Per Requirement 1.7
                    selectionManager.clearSelection()
                }
            )
        )
        .alert("Delete \(selectionManager.selectionCount) Task(s)?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                performBulkDeletion()
            }
        } message: {
            Text("The selected tasks will be moved to the Deleted column.")
        }
    }
    
    private func tasksForColumn(_ column: TFMKanbanColumn) -> [TFMTask] {
        let columnTasks = taskManager.getAllKanbanTasks().filter { $0.kanbanColumn == column }
        return filterTasks(columnTasks)
    }
    
    /// Perform bulk deletion of selected tasks
    /// Per Requirements 2.1, 2.3, 2.4, 2.6
    private func performBulkDeletion() {
        let selectedIds = selectionManager.getSelectedTaskIds()
        var deletedCount = 0
        
        for taskId in selectedIds {
            if let task = taskManager.getAllKanbanTasks().first(where: { $0.id == taskId }) {
                taskManager.softDeleteTask(task)
                deletedCount += 1
            }
        }
        
        // Clear selection after deletion
        selectionManager.clearSelection()
        
        // Show status message
        if deletedCount > 0 {
            onStatusMessage?("Deleted \(deletedCount) task(s)")
        }
    }
}

/// Individual Kanban column
/// Per Requirements 5.5, 5.9, 5.10
public struct KanbanColumnView: View {
    let column: TFMKanbanColumn
    let tasks: [TFMTask]
    let taskManager: TaskManager
    let onMoveColumn: (TFMTask, TFMKanbanColumn) -> Void
    let onMoveToActive: (TFMTask) -> Void
    let onComplete: (TFMTask) -> Void
    let onRestore: (TFMTask) -> Void
    let onPermanentDelete: (TFMTask) -> Void
    let onEdit: (TFMTask) -> Void
    
    @State private var isTargeted = false
    
    public init(
        column: TFMKanbanColumn,
        tasks: [TFMTask],
        taskManager: TaskManager,
        onMoveColumn: @escaping (TFMTask, TFMKanbanColumn) -> Void,
        onMoveToActive: @escaping (TFMTask) -> Void,
        onComplete: @escaping (TFMTask) -> Void,
        onRestore: @escaping (TFMTask) -> Void = { _ in },
        onPermanentDelete: @escaping (TFMTask) -> Void = { _ in },
        onEdit: @escaping (TFMTask) -> Void = { _ in }
    ) {
        self.column = column
        self.tasks = tasks
        self.taskManager = taskManager
        self.onMoveColumn = onMoveColumn
        self.onMoveToActive = onMoveToActive
        self.onComplete = onComplete
        self.onRestore = onRestore
        self.onPermanentDelete = onPermanentDelete
        self.onEdit = onEdit
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column header
            KanbanColumnHeader(column: column, count: tasks.count)
                .padding(.horizontal, CyberpunkTheme.spacingS)
                .padding(.top, CyberpunkTheme.spacingS)
            
            // Tasks
            ScrollView {
                LazyVStack(spacing: CyberpunkTheme.spacingS) {
                    ForEach(tasks) { task in
                        if column == .deleted {
                            DeletedTaskCard(
                                task: task,
                                onRestore: onRestore,
                                onPermanentDelete: onPermanentDelete
                            )
                            .draggable(task.id.uuidString)
                        } else {
                            KanbanTaskCard(
                                task: task,
                                onMoveColumn: onMoveColumn,
                                onMoveToActive: onMoveToActive,
                                onComplete: onComplete,
                                onEdit: onEdit
                            )
                            .draggable(task.id.uuidString)
                        }
                    }
                }
                .padding(CyberpunkTheme.spacingS)
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusL)
                .fill(CyberpunkTheme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusL)
                        .stroke(
                            isTargeted ? CyberpunkTheme.color(for: column) : CyberpunkTheme.color(for: column).opacity(0.2),
                            lineWidth: isTargeted ? 2 : 1
                        )
                )
        )
        .shadow(color: isTargeted ? CyberpunkTheme.color(for: column).opacity(0.5) : .clear, radius: CyberpunkTheme.glowRadiusIntense)
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
        .dropDestination(for: String.self) { items, _ in
            guard let taskIdString = items.first,
                  let taskId = UUID(uuidString: taskIdString) else {
                print("KanbanDrop: Invalid task ID")
                return false
            }
            
            // Find the task in the task manager
            guard let task = taskManager.getAllKanbanTasks().first(where: { $0.id == taskId }) else {
                print("KanbanDrop: Task not found with ID: \(taskId)")
                return false
            }
            
            // Don't move if already in this column
            if task.kanbanColumn == column {
                print("KanbanDrop: Task already in column \(column.displayName)")
                return false
            }
            
            // Move the task to this column
            print("KanbanDrop: Moving task '\(task.title)' to column \(column.displayName)")
            onMoveColumn(task, column)
            return true
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.15)) {
                isTargeted = targeted
            }
        }
    }
}

/// Task card for Kanban board with multi-select support
/// Per Requirements 1.1-1.4, 5.11
public struct KanbanTaskCard: View {
    let task: TFMTask
    let onMoveColumn: (TFMTask, TFMKanbanColumn) -> Void
    let onMoveToActive: (TFMTask) -> Void
    let onComplete: (TFMTask) -> Void
    let onEdit: (TFMTask) -> Void
    
    @ObservedObject private var selectionManager = SelectionManager.shared
    @State private var isHovered = false
    @State private var showingMenu = false
    
    /// Whether this card is currently selected
    private var isSelected: Bool {
        selectionManager.isSelected(task.id)
    }
    
    public init(
        task: TFMTask,
        onMoveColumn: @escaping (TFMTask, TFMKanbanColumn) -> Void,
        onMoveToActive: @escaping (TFMTask) -> Void,
        onComplete: @escaping (TFMTask) -> Void,
        onEdit: @escaping (TFMTask) -> Void = { _ in }
    ) {
        self.task = task
        self.onMoveColumn = onMoveColumn
        self.onMoveToActive = onMoveToActive
        self.onComplete = onComplete
        self.onEdit = onEdit
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingXS) {
            // Title
            Text(task.title)
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(CyberpunkTheme.textPrimary)
                .lineLimit(2)
            
            // Assigned To
            if let assignedTo = task.assignedTo, !assignedTo.isEmpty {
                HStack(spacing: 2) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 9))
                    Text(assignedTo)
                        .font(.system(size: 10))
                }
                .foregroundColor(CyberpunkTheme.accentGreen)
            }
            
            // Badges
            HStack(spacing: CyberpunkTheme.spacingXS) {
                // Priority dot
                Circle()
                    .fill(CyberpunkTheme.color(for: task.priority))
                    .frame(width: 8, height: 8)
                
                Text(task.timeEstimate.displayName)
                    .font(.system(size: 10))
                    .foregroundColor(CyberpunkTheme.textTertiary)
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(CyberpunkTheme.accentCyan)
                }
                
                // Quick actions on hover
                if isHovered && !isSelected {
                    HStack(spacing: 4) {
                        Button(action: { onMoveToActive(task) }) {
                            Image(systemName: "arrow.left.circle")
                                .font(.system(size: 12))
                                .foregroundColor(CyberpunkTheme.accentCyan)
                        }
                        .buttonStyle(.plain)
                        .help("Move to active tasks")
                        
                        Button(action: { onComplete(task) }) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 12))
                                .foregroundColor(CyberpunkTheme.accentGreen)
                        }
                        .buttonStyle(.plain)
                        .help("Mark complete")
                    }
                }
            }
        }
        .padding(CyberpunkTheme.spacingS)
        .background(
            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                .fill(isSelected ? CyberpunkTheme.backgroundTertiary.opacity(0.9) : CyberpunkTheme.backgroundTertiary)
                .overlay(
                    RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                        .stroke(
                            isSelected ? CyberpunkTheme.accentCyan : CyberpunkTheme.color(for: task.priority).opacity(isHovered ? 0.5 : 0.2),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        )
        .shadow(
            color: isSelected ? CyberpunkTheme.accentCyan.opacity(0.4) : (isHovered ? CyberpunkTheme.color(for: task.priority).opacity(0.2) : .clear),
            radius: isSelected ? CyberpunkTheme.glowRadiusIntense : CyberpunkTheme.glowRadiusSubtle
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            TapGesture()
                .modifiers(.command)
                .onEnded { _ in
                    // Command+click: toggle selection
                    selectionManager.handleCardClick(task.id, commandKeyPressed: true)
                }
        )
        .onTapGesture {
            // Check if we should handle as selection or edit
            // If there's already a selection, regular click adds to selection behavior
            if selectionManager.hasSelection {
                // Regular click when selection exists: replace selection with this card
                selectionManager.selectOnly(task.id)
            } else {
                // No selection: open edit view
                onEdit(task)
            }
        }
        .contextMenu {
            Button("View Details") {
                onEdit(task)
            }
            
            if selectionManager.hasSelection {
                Divider()
                
                Button("Clear Selection") {
                    selectionManager.clearSelection()
                }
            }
            
            Divider()
            
            ForEach(TFMKanbanColumn.allCases, id: \.self) { column in
                if column != task.kanbanColumn {
                    Button("Move to \(column.displayName)") {
                        onMoveColumn(task, column)
                    }
                }
            }
            
            Divider()
            
            Button("Move to Active Tasks") {
                onMoveToActive(task)
            }
            
            Button("Mark Complete") {
                onComplete(task)
            }
        }
    }
}

/// Empty state for Kanban board
public struct EmptyKanbanView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: CyberpunkTheme.spacingM) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 48))
                .foregroundColor(CyberpunkTheme.accentPurple.opacity(0.5))
            
            Text("No tasks in Kanban")
                .font(CyberpunkTheme.fontHeadline)
                .foregroundColor(CyberpunkTheme.textSecondary)
            
            Text("Move tasks here to organize overflow work")
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(CyberpunkTheme.textTertiary)
        }
        .padding(CyberpunkTheme.spacingXL)
    }
}

/// Task card for Deleted column with restore/permanent delete actions and multi-select support
/// Per Requirements 1.6, 5.7
public struct DeletedTaskCard: View {
    let task: TFMTask
    let onRestore: (TFMTask) -> Void
    let onPermanentDelete: (TFMTask) -> Void
    
    @ObservedObject private var selectionManager = SelectionManager.shared
    @State private var isHovered = false
    @State private var showingDeleteConfirmation = false
    
    /// Whether this card is currently selected
    private var isSelected: Bool {
        selectionManager.isSelected(task.id)
    }
    
    public init(
        task: TFMTask,
        onRestore: @escaping (TFMTask) -> Void,
        onPermanentDelete: @escaping (TFMTask) -> Void
    ) {
        self.task = task
        self.onRestore = onRestore
        self.onPermanentDelete = onPermanentDelete
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingXS) {
            // Title (muted for deleted tasks)
            Text(task.title)
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(CyberpunkTheme.textTertiary)
                .lineLimit(2)
            
            // Badges
            HStack(spacing: CyberpunkTheme.spacingXS) {
                // Priority dot (muted)
                Circle()
                    .fill(CyberpunkTheme.color(for: task.priority).opacity(0.5))
                    .frame(width: 8, height: 8)
                
                Text(task.timeEstimate.displayName)
                    .font(.system(size: 10))
                    .foregroundColor(CyberpunkTheme.textTertiary.opacity(0.7))
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(CyberpunkTheme.accentCyan)
                }
                
                // Actions on hover
                if isHovered && !isSelected {
                    HStack(spacing: 4) {
                        Button(action: { onRestore(task) }) {
                            Image(systemName: "arrow.uturn.backward.circle")
                                .font(.system(size: 12))
                                .foregroundColor(CyberpunkTheme.accentCyan)
                        }
                        .buttonStyle(.plain)
                        .help("Restore task")
                        
                        Button(action: { showingDeleteConfirmation = true }) {
                            Image(systemName: "trash.circle")
                                .font(.system(size: 12))
                                .foregroundColor(CyberpunkTheme.accentMagenta)
                        }
                        .buttonStyle(.plain)
                        .help("Permanently delete")
                    }
                }
            }
        }
        .padding(CyberpunkTheme.spacingS)
        .background(
            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                .fill(CyberpunkTheme.backgroundTertiary.opacity(isSelected ? 0.8 : 0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                        .stroke(
                            isSelected ? CyberpunkTheme.accentCyan : CyberpunkTheme.kanbanDeleted.opacity(isHovered ? 0.5 : 0.2),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        )
        .shadow(
            color: isSelected ? CyberpunkTheme.accentCyan.opacity(0.4) : .clear,
            radius: isSelected ? CyberpunkTheme.glowRadiusIntense : 0
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            TapGesture()
                .modifiers(.command)
                .onEnded { _ in
                    // Command+click: toggle selection
                    selectionManager.handleCardClick(task.id, commandKeyPressed: true)
                }
        )
        .onTapGesture {
            // Check if we should handle as selection
            if selectionManager.hasSelection {
                // Regular click when selection exists: replace selection with this card
                selectionManager.selectOnly(task.id)
            }
            // No default action for deleted cards (no edit view)
        }
        .contextMenu {
            Button("Restore to Backlog") {
                onRestore(task)
            }
            
            if selectionManager.hasSelection {
                Divider()
                
                Button("Clear Selection") {
                    selectionManager.clearSelection()
                }
            }
            
            Divider()
            
            Button("Permanently Delete", role: .destructive) {
                showingDeleteConfirmation = true
            }
        }
        .alert("Permanently Delete Task?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onPermanentDelete(task)
            }
        } message: {
            Text("This action cannot be undone. The task '\(task.title)' will be permanently removed.")
        }
    }
}


/// Helper view for handling keyboard events in SwiftUI (macOS 13+ compatible)
/// Per Requirements 1.7, 2.1
struct KeyboardEventHandler: NSViewRepresentable {
    let onDelete: () -> Void
    let onEscape: () -> Void
    
    func makeNSView(context: Context) -> KeyboardEventNSView {
        let view = KeyboardEventNSView()
        view.onDelete = onDelete
        view.onEscape = onEscape
        return view
    }
    
    func updateNSView(_ nsView: KeyboardEventNSView, context: Context) {
        nsView.onDelete = onDelete
        nsView.onEscape = onEscape
    }
}

/// NSView that captures keyboard events
class KeyboardEventNSView: NSView {
    var onDelete: (() -> Void)?
    var onEscape: (() -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 51, 117: // Delete (backspace) or Forward Delete
            onDelete?()
        case 53: // Escape
            onEscape?()
        default:
            super.keyDown(with: event)
        }
    }
}
