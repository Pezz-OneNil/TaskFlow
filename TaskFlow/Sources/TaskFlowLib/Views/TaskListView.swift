import SwiftUI

/// Main task list view showing active tasks in priority order
/// Per Requirements 3.4, 4.2
public struct TaskListView: View {
    @ObservedObject var taskManager: TaskManager
    let searchQuery: String
    let filterTasks: ([Task]) -> [Task]
    let onComplete: (Task) -> Void
    let onDelete: (Task) -> Void
    let onMoveToKanban: (Task) -> Void
    let onCopySearchTerms: (Task) -> Void
    let onEdit: (Task) -> Void
    
    public init(
        taskManager: TaskManager,
        searchQuery: String = "",
        filterTasks: @escaping ([Task]) -> [Task] = { $0 },
        onComplete: @escaping (Task) -> Void = { _ in },
        onDelete: @escaping (Task) -> Void = { _ in },
        onMoveToKanban: @escaping (Task) -> Void = { _ in },
        onCopySearchTerms: @escaping (Task) -> Void = { _ in },
        onEdit: @escaping (Task) -> Void = { _ in }
    ) {
        self.taskManager = taskManager
        self.searchQuery = searchQuery
        self.filterTasks = filterTasks
        self.onComplete = onComplete
        self.onDelete = onDelete
        self.onMoveToKanban = onMoveToKanban
        self.onCopySearchTerms = onCopySearchTerms
        self.onEdit = onEdit
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingM) {
            // Search results indicator
            if !searchQuery.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(CyberpunkTheme.accentCyan)
                    Text("Showing results for \"\(searchQuery)\"")
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textSecondary)
                    Text("(\(sortedTasks.count) found)")
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.accentCyan)
                }
                .padding(.horizontal, CyberpunkTheme.spacingM)
                .padding(.top, CyberpunkTheme.spacingS)
            }
            
            // Task list
            ScrollView {
                LazyVStack(spacing: CyberpunkTheme.spacingS) {
                    ForEach(sortedTasks) { task in
                        TaskRowView(
                            task: task,
                            onComplete: { onComplete(task) },
                            onDelete: { onDelete(task) },
                            onMoveToKanban: { onMoveToKanban(task) },
                            onCopySearchTerms: { onCopySearchTerms(task) },
                            onEdit: { onEdit(task) }
                        )
                    }
                }
                .padding(.horizontal, CyberpunkTheme.spacingM)
                .padding(.top, CyberpunkTheme.spacingS)
            }
        }
        .background(CyberpunkTheme.backgroundPrimary)
    }
    
    private var sortedTasks: [Task] {
        let scheduler = PriorityScheduler()
        let activeTasks = taskManager.getActiveTasks()
        let filtered = filterTasks(activeTasks)
        return scheduler.sortByPriority(filtered)
    }
}

/// Individual task row in the list
public struct TaskRowView: View {
    let task: Task
    let onComplete: () -> Void
    let onDelete: () -> Void
    let onMoveToKanban: () -> Void
    let onCopySearchTerms: () -> Void
    let onEdit: () -> Void
    
    @State private var isHovered = false
    
    public init(
        task: Task,
        onComplete: @escaping () -> Void,
        onDelete: @escaping () -> Void = {},
        onMoveToKanban: @escaping () -> Void,
        onCopySearchTerms: @escaping () -> Void,
        onEdit: @escaping () -> Void
    ) {
        self.task = task
        self.onComplete = onComplete
        self.onDelete = onDelete
        self.onMoveToKanban = onMoveToKanban
        self.onCopySearchTerms = onCopySearchTerms
        self.onEdit = onEdit
    }
    
    public var body: some View {
        NeonCard(color: CyberpunkTheme.color(for: task.priority)) {
            HStack(spacing: CyberpunkTheme.spacingM) {
                // Priority indicator
                Rectangle()
                    .fill(CyberpunkTheme.color(for: task.priority))
                    .frame(width: 4)
                    .cornerRadius(2)
                
                // Task content
                VStack(alignment: .leading, spacing: CyberpunkTheme.spacingXS) {
                    Text(task.title)
                        .font(CyberpunkTheme.fontHeadline)
                        .foregroundColor(CyberpunkTheme.textPrimary)
                        .lineLimit(1)
                    
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(CyberpunkTheme.fontCaption)
                            .foregroundColor(CyberpunkTheme.textSecondary)
                            .lineLimit(2)
                    }
                    
                    // Badges
                    HStack(spacing: CyberpunkTheme.spacingS) {
                        TimeEstimateBadge(timeEstimate: task.timeEstimate)
                        PriorityBadge(priority: task.priority)
                        
                        if let assignedTo = task.assignedTo, !assignedTo.isEmpty {
                            HStack(spacing: 2) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 10))
                                Text(assignedTo)
                                    .font(CyberpunkTheme.fontCaption)
                            }
                            .foregroundColor(CyberpunkTheme.accentGreen)
                        }
                        
                        if let sourceApp = task.metadata.sourceApp {
                            Text(sourceApp)
                                .font(CyberpunkTheme.fontCaption)
                                .foregroundColor(CyberpunkTheme.textTertiary)
                        }
                        
                        // LLM indicator
                        if task.metadata.llmGeneratedTitle {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                                .foregroundColor(CyberpunkTheme.accentCyan)
                                .help("Title generated by AI")
                        }
                        
                        // Screenshot indicator
                        if task.screenshotId != nil {
                            Image(systemName: "photo")
                                .font(.system(size: 10))
                                .foregroundColor(CyberpunkTheme.accentPurple)
                                .help("Has screenshot")
                        }
                    }
                }
                
                Spacer()
                
                // Quick actions (visible on hover)
                if isHovered {
                    HStack(spacing: CyberpunkTheme.spacingS) {
                        NeonIconButton(systemName: "checkmark", color: CyberpunkTheme.accentGreen, action: onComplete)
                        NeonIconButton(systemName: "trash", color: CyberpunkTheme.accentMagenta, action: onDelete)
                        NeonIconButton(systemName: "rectangle.3.group", color: CyberpunkTheme.accentPurple, action: onMoveToKanban)
                        NeonIconButton(systemName: "doc.on.clipboard", color: CyberpunkTheme.accentCyan, action: onCopySearchTerms)
                        NeonIconButton(systemName: "pencil", color: CyberpunkTheme.textSecondary, action: onEdit)
                    }
                    .transition(.opacity)
                }
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture(count: 2) {
            onEdit()
        }
    }
}

/// Empty state view when no tasks exist
public struct EmptyTasksView: View {
    let onCreateTask: () -> Void
    
    public init(onCreateTask: @escaping () -> Void) {
        self.onCreateTask = onCreateTask
    }
    
    public var body: some View {
        VStack(spacing: CyberpunkTheme.spacingL) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundColor(CyberpunkTheme.accentGreen.opacity(0.5))
            
            Text("No tasks yet")
                .font(CyberpunkTheme.fontTitle)
                .foregroundColor(CyberpunkTheme.textSecondary)
            
            Text("Capture your screen or create a task to get started")
                .font(CyberpunkTheme.fontBody)
                .foregroundColor(CyberpunkTheme.textTertiary)
                .multilineTextAlignment(.center)
            
            NeonButton(title: "Create Task", color: CyberpunkTheme.accentPurple, action: onCreateTask)
        }
        .padding(CyberpunkTheme.spacingXL)
    }
}
