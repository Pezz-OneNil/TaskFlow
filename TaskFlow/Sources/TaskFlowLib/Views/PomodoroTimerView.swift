import SwiftUI

/// Pomodoro timer view with large countdown and task display
/// Per Requirements 4.1, 4.6
public struct PomodoroTimerView: View {
    @ObservedObject var engine: PomodoroEngine
    let onStartSession: (TimeInterval) -> Void
    let onEdit: (Task) -> Void
    
    @State private var selectedDuration: TimeInterval = 25 * 60 // 25 minutes default
    
    public init(
        engine: PomodoroEngine,
        onStartSession: @escaping (TimeInterval) -> Void = { _ in },
        onEdit: @escaping (Task) -> Void = { _ in }
    ) {
        self.engine = engine
        self.onStartSession = onStartSession
        self.onEdit = onEdit
    }
    
    public var body: some View {
        GeometryReader { geometry in
            VStack(spacing: CyberpunkTheme.spacingL) {
                Spacer()
                
                if engine.isRunning {
                    activeSessionView
                } else {
                    sessionConfigView
                }
                
                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .padding(CyberpunkTheme.spacingL)
        }
        .background(CyberpunkTheme.backgroundPrimary)
    }
    
    // MARK: - Active Session View
    
    private var activeSessionView: some View {
        VStack(spacing: CyberpunkTheme.spacingXL) {
            // Timer display
            VStack(spacing: CyberpunkTheme.spacingS) {
                NeonTimerDisplay(
                    timeRemaining: engine.remainingTime,
                    color: timerColor
                )
                
                // Progress bar
                NeonProgressBar(
                    progress: 1 - (engine.remainingTime / engine.sessionDuration),
                    color: timerColor
                )
                .frame(width: 200)
            }
            
            // Current task
            if let currentTask = engine.currentTask {
                currentTaskCard(currentTask)
            } else {
                Text("No tasks available")
                    .font(CyberpunkTheme.fontBody)
                    .foregroundColor(CyberpunkTheme.textSecondary)
            }
            
            // Controls
            HStack(spacing: CyberpunkTheme.spacingM) {
                if engine.isPaused {
                    NeonButton(title: "Resume", color: CyberpunkTheme.accentGreen) {
                        engine.resumeSession()
                    }
                } else {
                    NeonButton(title: "Pause", color: CyberpunkTheme.accentYellow) {
                        engine.pauseSession()
                    }
                }
                
                NeonButton(title: "Stop", color: CyberpunkTheme.accentMagenta) {
                    engine.stopSession()
                }
            }
            
            // Task actions
            if engine.currentTask != nil {
                HStack(spacing: CyberpunkTheme.spacingM) {
                    NeonButton(title: "Complete Task", color: CyberpunkTheme.accentGreen) {
                        engine.completeCurrentTask()
                    }
                    
                    NeonButton(title: "Skip", color: CyberpunkTheme.textSecondary) {
                        engine.skipCurrentTask()
                    }
                }
            }
            
            // Upcoming tasks
            if !engine.upcomingTasks.isEmpty {
                upcomingTasksView
            }
        }
    }
    
    private func currentTaskCard(_ task: Task) -> some View {
        NeonCard(color: CyberpunkTheme.color(for: task.priority)) {
            VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
                HStack {
                    Text("Current Task")
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textSecondary)
                    Spacer()
                    PriorityBadge(priority: task.priority)
                }
                
                Text(task.title)
                    .font(CyberpunkTheme.fontHeadline)
                    .foregroundColor(CyberpunkTheme.textPrimary)
                    .lineLimit(2)
                
                HStack {
                    TimeEstimateBadge(timeEstimate: task.timeEstimate)
                    Spacer()
                    Text("Double-click to edit")
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textTertiary)
                }
            }
        }
        .frame(maxWidth: 400)
        .onTapGesture(count: 2) {
            onEdit(task)
        }
    }
    
    private var upcomingTasksView: some View {
        VStack(alignment: .leading, spacing: CyberpunkTheme.spacingS) {
            Text("Up Next")
                .font(CyberpunkTheme.fontHeadline)
                .foregroundColor(CyberpunkTheme.textSecondary)
            
            ForEach(engine.upcomingTasks.prefix(3)) { task in
                HStack {
                    Rectangle()
                        .fill(CyberpunkTheme.color(for: task.priority))
                        .frame(width: 3)
                        .cornerRadius(1.5)
                    
                    Text(task.title)
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(task.timeEstimate.displayName)
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textTertiary)
                }
                .padding(.vertical, CyberpunkTheme.spacingXS)
            }
        }
        .padding(CyberpunkTheme.spacingM)
        .background(
            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                .fill(CyberpunkTheme.backgroundSecondary)
        )
        .frame(maxWidth: 400)
    }
    
    private var timerColor: Color {
        if engine.remainingTime < 60 {
            return CyberpunkTheme.accentMagenta
        } else if engine.remainingTime < 5 * 60 {
            return CyberpunkTheme.accentYellow
        } else {
            return CyberpunkTheme.accentCyan
        }
    }
    
    // MARK: - Session Configuration View
    
    private var sessionConfigView: some View {
        VStack(spacing: CyberpunkTheme.spacingXL) {
            // Duration selection
            VStack(spacing: CyberpunkTheme.spacingM) {
                Text("Session Duration")
                    .font(CyberpunkTheme.fontHeadline)
                    .foregroundColor(CyberpunkTheme.textSecondary)
                
                HStack(spacing: CyberpunkTheme.spacingS) {
                    ForEach([15, 25, 45, 60], id: \.self) { minutes in
                        DurationButton(
                            minutes: minutes,
                            isSelected: selectedDuration == TimeInterval(minutes * 60)
                        ) {
                            selectedDuration = TimeInterval(minutes * 60)
                        }
                    }
                }
            }
            
            // Preview timer
            NeonTimerDisplay(
                timeRemaining: selectedDuration,
                color: CyberpunkTheme.accentCyan.opacity(0.5)
            )
            
            // Estimated tasks
            VStack(spacing: CyberpunkTheme.spacingS) {
                Text("Estimated tasks: \(engine.estimatedTaskCount())")
                    .font(CyberpunkTheme.fontBody)
                    .foregroundColor(CyberpunkTheme.textSecondary)
                
                let workTime = engine.estimatedWorkTime()
                Text("Work time: \(Int(workTime / 60)) min")
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.textTertiary)
            }
            
            // Start button
            NeonButton(title: "Start Session", color: CyberpunkTheme.accentGreen) {
                engine.startSession(duration: selectedDuration)
                onStartSession(selectedDuration)
            }
        }
    }
}

/// Button for selecting session duration
struct DurationButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(minutes) min")
                .font(CyberpunkTheme.fontHeadline)
                .foregroundColor(isSelected ? CyberpunkTheme.backgroundPrimary : CyberpunkTheme.textPrimary)
                .padding(.horizontal, CyberpunkTheme.spacingM)
                .padding(.vertical, CyberpunkTheme.spacingS)
                .background(
                    RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                        .fill(isSelected ? CyberpunkTheme.accentCyan : CyberpunkTheme.backgroundSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                                .stroke(CyberpunkTheme.accentCyan, lineWidth: isSelected ? 0 : 1)
                        )
                )
                .shadow(color: isSelected ? CyberpunkTheme.accentCyan.opacity(0.5) : .clear, radius: CyberpunkTheme.glowRadius)
        }
        .buttonStyle(.plain)
    }
}
