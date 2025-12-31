import SwiftUI

// MARK: - Neon Button

/// A button with neon glow effect on hover/press
/// Per Requirements 7.4, 7.5
public struct NeonButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    public init(title: String, color: Color = CyberpunkTheme.accentPurple, action: @escaping () -> Void) {
        self.title = title
        self.color = color
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(CyberpunkTheme.fontHeadline)
                .foregroundColor(isPressed ? CyberpunkTheme.backgroundPrimary : CyberpunkTheme.textPrimary)
                .padding(.horizontal, CyberpunkTheme.spacingM)
                .padding(.vertical, CyberpunkTheme.spacingS)
                .background(
                    RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                        .fill(isPressed ? color : CyberpunkTheme.backgroundSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                                .stroke(color, lineWidth: 2)
                        )
                )
                .shadow(color: color.opacity(isHovered ? 0.8 : 0.4), radius: isHovered ? CyberpunkTheme.glowRadiusIntense : CyberpunkTheme.glowRadius)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Neon Icon Button

/// A circular icon button with neon glow
public struct NeonIconButton: View {
    let systemName: String
    let color: Color
    let size: CGFloat
    let action: () -> Void
    
    @State private var isHovered = false
    
    public init(systemName: String, color: Color = CyberpunkTheme.accentPurple, size: CGFloat = 24, action: @escaping () -> Void) {
        self.systemName = systemName
        self.color = color
        self.size = size
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.5))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(CyberpunkTheme.backgroundSecondary)
                        .overlay(
                            Circle()
                                .stroke(color, lineWidth: 1.5)
                        )
                )
                .shadow(color: color.opacity(isHovered ? 0.8 : 0.3), radius: isHovered ? CyberpunkTheme.glowRadius : CyberpunkTheme.glowRadiusSubtle)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Neon Card

/// A card container with subtle neon border glow
/// Per Requirements 7.4, 7.5
public struct NeonCard<Content: View>: View {
    let color: Color
    let content: Content
    
    @State private var isHovered = false
    
    public init(color: Color = CyberpunkTheme.accentPurple, @ViewBuilder content: () -> Content) {
        self.color = color
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(CyberpunkTheme.spacingM)
            .background(
                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusL)
                    .fill(CyberpunkTheme.backgroundTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusL)
                            .stroke(color.opacity(isHovered ? 0.8 : 0.3), lineWidth: 1)
                    )
            )
            .shadow(color: color.opacity(isHovered ? 0.4 : 0.1), radius: isHovered ? CyberpunkTheme.glowRadius : CyberpunkTheme.glowRadiusSubtle)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Glowing Text

/// Text with neon glow effect
/// Per Requirements 7.4, 7.5
public struct GlowingText: View {
    let text: String
    let color: Color
    let font: Font
    
    public init(_ text: String, color: Color = CyberpunkTheme.accentPurple, font: Font = CyberpunkTheme.fontTitle) {
        self.text = text
        self.color = color
        self.font = font
    }
    
    public var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
            .shadow(color: color.opacity(0.8), radius: CyberpunkTheme.glowRadius)
            .shadow(color: color.opacity(0.4), radius: CyberpunkTheme.glowRadiusIntense)
    }
}

// MARK: - Priority Badge

/// A badge showing task priority with appropriate color
public struct PriorityBadge: View {
    let priority: Priority
    
    public init(priority: Priority) {
        self.priority = priority
    }
    
    public var body: some View {
        Text(priority.displayName)
            .font(CyberpunkTheme.fontCaption)
            .foregroundColor(CyberpunkTheme.textPrimary)
            .padding(.horizontal, CyberpunkTheme.spacingS)
            .padding(.vertical, CyberpunkTheme.spacingXS)
            .background(
                Capsule()
                    .fill(CyberpunkTheme.color(for: priority).opacity(0.3))
                    .overlay(
                        Capsule()
                            .stroke(CyberpunkTheme.color(for: priority), lineWidth: 1)
                    )
            )
            .shadow(color: CyberpunkTheme.color(for: priority).opacity(0.5), radius: CyberpunkTheme.glowRadiusSubtle)
    }
}

// MARK: - Time Estimate Badge

/// A badge showing time estimate
public struct TimeEstimateBadge: View {
    let timeEstimate: TimeEstimate
    
    public init(timeEstimate: TimeEstimate) {
        self.timeEstimate = timeEstimate
    }
    
    public var body: some View {
        HStack(spacing: CyberpunkTheme.spacingXS) {
            Image(systemName: "clock")
                .font(.system(size: 10))
            Text(timeEstimate.displayName)
                .font(CyberpunkTheme.fontCaption)
        }
        .foregroundColor(CyberpunkTheme.textPrimary)
        .padding(.horizontal, CyberpunkTheme.spacingS)
        .padding(.vertical, CyberpunkTheme.spacingXS)
        .background(
            Capsule()
                .fill(CyberpunkTheme.color(for: timeEstimate).opacity(0.3))
                .overlay(
                    Capsule()
                        .stroke(CyberpunkTheme.color(for: timeEstimate), lineWidth: 1)
                )
        )
    }
}

// MARK: - Neon Progress Bar

/// A progress bar with neon glow
public struct NeonProgressBar: View {
    let progress: Double
    let color: Color
    
    public init(progress: Double, color: Color = CyberpunkTheme.accentPurple) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                    .fill(CyberpunkTheme.backgroundSecondary)
                    .frame(height: 8)
                
                // Progress fill
                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                    .fill(color)
                    .frame(width: geometry.size.width * progress, height: 8)
                    .shadow(color: color.opacity(0.8), radius: CyberpunkTheme.glowRadius)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Neon Timer Display

/// Large timer display with neon styling
public struct NeonTimerDisplay: View {
    let timeRemaining: TimeInterval
    let color: Color
    
    public init(timeRemaining: TimeInterval, color: Color = CyberpunkTheme.accentCyan) {
        self.timeRemaining = timeRemaining
        self.color = color
    }
    
    private var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    public var body: some View {
        Text(formattedTime)
            .font(CyberpunkTheme.fontMono)
            .foregroundColor(color)
            .shadow(color: color.opacity(0.8), radius: CyberpunkTheme.glowRadiusIntense)
            .shadow(color: color.opacity(0.4), radius: CyberpunkTheme.glowRadiusIntense * 2)
    }
}

// MARK: - Kanban Column Header

/// Header for Kanban board columns
public struct KanbanColumnHeader: View {
    let column: KanbanColumn
    let count: Int
    
    public init(column: KanbanColumn, count: Int) {
        self.column = column
        self.count = count
    }
    
    public var body: some View {
        HStack {
            Text(column.displayName)
                .font(CyberpunkTheme.fontHeadline)
                .foregroundColor(CyberpunkTheme.color(for: column))
            
            Spacer()
            
            Text("\(count)")
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(CyberpunkTheme.textSecondary)
                .padding(.horizontal, CyberpunkTheme.spacingS)
                .padding(.vertical, CyberpunkTheme.spacingXS)
                .background(
                    Capsule()
                        .fill(CyberpunkTheme.backgroundSecondary)
                )
        }
        .padding(.bottom, CyberpunkTheme.spacingS)
    }
}
