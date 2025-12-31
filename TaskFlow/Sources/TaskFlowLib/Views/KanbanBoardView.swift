import SwiftUI

/// Kanban board view with five columns (including Deleted)
/// Per Requirements 5.1, 5.2, 5.8
public struct KanbanBoardView: View {
    @ObservedObject var taskManager: TaskManager
    let searchQuery: String
    let filterTasks: ([Task]) -> [Task]
    let onMoveColumn: (Task, KanbanColumn) -> Void
    let onMoveToActive: (Task) -> Void
    let onComplete: (Task) -> Void
    let onRestore: (Task) -> Void
    let onPermanentDelete: (Task) -> Void
    let onEdit: (Task) -> Void
    
    public init(
        taskManager: TaskManager,
        searchQuery: String = "",
        filterTasks: @escaping ([Task]) -> [Task] = { $0 },
        onMoveColumn: @escaping (Task, KanbanColumn) -> Void = { _, _ in },
        onMoveToActive: @escaping (Task) -> Void = { _ in },
        onComplete: @escaping (Task) -> Void = { _ in },
        onRestore: @escaping (Task) -> Void = { _ in },
        onPermanentDelete: @escaping (Task) -> Void = { _ in },
        onEdit: @escaping (Task) -> Void = { _ in }
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
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingM) {
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
            
            // Columns
            HStack(alignment: .top, spacing: CyberpunkTheme.spacingM) {
                ForEach(KanbanColumn.allCases, id: \.self) { column in
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
                }
            }
            .padding(.horizontal, CyberpunkTheme.spacingM)
            .padding(.top, CyberpunkTheme.spacingS)
        }
        .background(CyberpunkTheme.backgroundPrimary)
    }
    
    private func tasksForColumn(_ column: KanbanColumn) -> [Task] {
        let columnTasks = taskManager.getAllKanbanTasks().filter { $0.kanbanColumn == column }
        return filterTasks(columnTasks)
    }
}

/// Individual Kanban column
/// Per Requirements 5.5, 5.9, 5.10
public struct KanbanColumnView: View {
    let column: KanbanColumn
    let tasks: [Task]
    let taskManager: TaskManager
    let onMoveColumn: (Task, KanbanColumn) -> Void
    let onMoveToActive: (Task) -> Void
    let onComplete: (Task) -> Void
    let onRestore: (Task) -> Void
    let onPermanentDelete: (Task) -> Void
    let onEdit: (Task) -> Void
    
    @State private var isTargeted = false
    
    public init(
        column: KanbanColumn,
        tasks: [Task],
        taskManager: TaskManager,
        onMoveColumn: @escaping (Task, KanbanColumn) -> Void,
        onMoveToActive: @escaping (Task) -> Void,
        onComplete: @escaping (Task) -> Void,
        onRestore: @escaping (Task) -> Void = { _ in },
        onPermanentDelete: @escaping (Task) -> Void = { _ in },
        onEdit: @escaping (Task) -> Void = { _ in }
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
        .frame(minWidth: 180, maxWidth: .infinity)
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

/// Task card for Kanban board
public struct KanbanTaskCard: View {
    let task: Task
    let onMoveColumn: (Task, KanbanColumn) -> Void
    let onMoveToActive: (Task) -> Void
    let onComplete: (Task) -> Void
    let onEdit: (Task) -> Void
    
    @State private var isHovered = false
    @State private var showingMenu = false
    
    public init(
        task: Task,
        onMoveColumn: @escaping (Task, KanbanColumn) -> Void,
        onMoveToActive: @escaping (Task) -> Void,
        onComplete: @escaping (Task) -> Void,
        onEdit: @escaping (Task) -> Void = { _ in }
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
                
                // Quick actions on hover
                if isHovered {
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
                .fill(CyberpunkTheme.backgroundTertiary)
                .overlay(
                    RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                        .stroke(CyberpunkTheme.color(for: task.priority).opacity(isHovered ? 0.5 : 0.2), lineWidth: 1)
                )
        )
        .shadow(color: isHovered ? CyberpunkTheme.color(for: task.priority).opacity(0.2) : .clear, radius: CyberpunkTheme.glowRadiusSubtle)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onEdit(task)
        }
        .contextMenu {
            Button("View Details") {
                onEdit(task)
            }
            
            Divider()
            
            ForEach(KanbanColumn.allCases, id: \.self) { column in
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

/// Task card for Deleted column with restore/permanent delete actions
/// Per Requirement 5.7
public struct DeletedTaskCard: View {
    let task: Task
    let onRestore: (Task) -> Void
    let onPermanentDelete: (Task) -> Void
    
    @State private var isHovered = false
    @State private var showingDeleteConfirmation = false
    
    public init(
        task: Task,
        onRestore: @escaping (Task) -> Void,
        onPermanentDelete: @escaping (Task) -> Void
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
                
                // Actions on hover
                if isHovered {
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
                .fill(CyberpunkTheme.backgroundTertiary.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                        .stroke(CyberpunkTheme.kanbanDeleted.opacity(isHovered ? 0.5 : 0.2), lineWidth: 1)
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button("Restore to Backlog") {
                onRestore(task)
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
