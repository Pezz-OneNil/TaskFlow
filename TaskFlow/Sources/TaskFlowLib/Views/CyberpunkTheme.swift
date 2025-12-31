import SwiftUI

/// Cyberpunk-inspired color theme for TaskFlow
/// Per Requirements 7.1, 7.2, 7.3, 7.6
public struct CyberpunkTheme {
    
    // MARK: - Background Colors
    
    /// Primary dark background (#0D0D0D)
    public static let backgroundPrimary = Color(hex: "0D0D0D")
    
    /// Secondary dark background (#1A1A2E)
    public static let backgroundSecondary = Color(hex: "1A1A2E")
    
    /// Tertiary background for cards (#16213E)
    public static let backgroundTertiary = Color(hex: "16213E")
    
    /// Surface color for elevated elements
    public static let surface = Color(hex: "1F1F3D")
    
    // MARK: - Neon Accent Colors
    
    /// Primary purple accent (#9D4EDD)
    public static let accentPurple = Color(hex: "9D4EDD")
    
    /// Cyan accent (#00F5FF)
    public static let accentCyan = Color(hex: "00F5FF")
    
    /// Magenta accent (#FF006E)
    public static let accentMagenta = Color(hex: "FF006E")
    
    /// Green accent for success states (#39FF14)
    public static let accentGreen = Color(hex: "39FF14")
    
    /// Yellow accent for warnings (#FFE66D)
    public static let accentYellow = Color(hex: "FFE66D")
    
    // MARK: - Text Colors
    
    /// Primary text color (high contrast white)
    public static let textPrimary = Color(hex: "FFFFFF")
    
    /// Secondary text color (muted)
    public static let textSecondary = Color(hex: "B8B8D1")
    
    /// Tertiary text color (subtle)
    public static let textTertiary = Color(hex: "6B6B8D")
    
    // MARK: - Priority Colors (Per Requirement 7.3)
    
    /// Low priority color (cyan)
    public static let priorityLow = accentCyan
    
    /// Medium priority color (purple)
    public static let priorityMedium = accentPurple
    
    /// Mega priority color (magenta)
    public static let priorityMega = accentMagenta
    
    /// Get color for priority level
    public static func color(for priority: Priority) -> Color {
        switch priority {
        case .low:
            return priorityLow
        case .medium:
            return priorityMedium
        case .mega:
            return priorityMega
        }
    }
    
    // MARK: - Status Colors
    
    /// Pending status color
    public static let statusPending = textSecondary
    
    /// In progress status color
    public static let statusInProgress = accentPurple
    
    /// Completed status color
    public static let statusCompleted = accentGreen
    
    /// Deferred status color
    public static let statusDeferred = accentYellow
    
    /// Deleted status color (muted gray)
    public static let statusDeleted = Color(hex: "4A4A5A")
    
    /// Get color for task status
    public static func color(for status: TaskStatus) -> Color {
        switch status {
        case .pending:
            return statusPending
        case .inProgress:
            return statusInProgress
        case .completed:
            return statusCompleted
        case .deferred:
            return statusDeferred
        case .deleted:
            return statusDeleted
        }
    }
    
    // MARK: - Kanban Column Colors
    
    /// Backlog column color
    public static let kanbanBacklog = textSecondary
    
    /// In Progress column color
    public static let kanbanInProgress = accentPurple
    
    /// Blocked column color
    public static let kanbanBlocked = accentMagenta
    
    /// Done column color
    public static let kanbanDone = accentGreen
    
    /// Deleted column color (muted gray)
    public static let kanbanDeleted = Color(hex: "4A4A5A")
    
    /// Get color for Kanban column
    public static func color(for column: KanbanColumn) -> Color {
        switch column {
        case .backlog:
            return kanbanBacklog
        case .inProgress:
            return kanbanInProgress
        case .blocked:
            return kanbanBlocked
        case .done:
            return kanbanDone
        case .deleted:
            return kanbanDeleted
        }
    }
    
    // MARK: - Time Estimate Colors
    
    /// Get color for time estimate (gradient from green to red)
    public static func color(for timeEstimate: TimeEstimate) -> Color {
        switch timeEstimate {
        case .ten:
            return accentGreen
        case .twenty:
            return accentCyan
        case .forty:
            return accentPurple
        case .sixty:
            return accentYellow
        case .overSixty:
            return accentMagenta
        }
    }
    
    // MARK: - Glow Effects
    
    /// Standard glow radius
    public static let glowRadius: CGFloat = 8
    
    /// Intense glow radius (for hover/active states)
    public static let glowRadiusIntense: CGFloat = 15
    
    /// Subtle glow radius
    public static let glowRadiusSubtle: CGFloat = 4
    
    // MARK: - Typography
    
    /// Large title font
    public static let fontLargeTitle = Font.system(size: 34, weight: .bold, design: .default)
    
    /// Title font
    public static let fontTitle = Font.system(size: 28, weight: .semibold, design: .default)
    
    /// Headline font
    public static let fontHeadline = Font.system(size: 17, weight: .semibold, design: .default)
    
    /// Body font
    public static let fontBody = Font.system(size: 15, weight: .regular, design: .default)
    
    /// Caption font
    public static let fontCaption = Font.system(size: 12, weight: .regular, design: .default)
    
    /// Monospace font for timers/numbers
    public static let fontMono = Font.system(size: 48, weight: .bold, design: .monospaced)
    
    // MARK: - Spacing
    
    /// Extra small spacing
    public static let spacingXS: CGFloat = 4
    
    /// Small spacing
    public static let spacingS: CGFloat = 8
    
    /// Medium spacing
    public static let spacingM: CGFloat = 16
    
    /// Large spacing
    public static let spacingL: CGFloat = 24
    
    /// Extra large spacing
    public static let spacingXL: CGFloat = 32
    
    // MARK: - Corner Radius
    
    /// Small corner radius
    public static let cornerRadiusS: CGFloat = 4
    
    /// Medium corner radius
    public static let cornerRadiusM: CGFloat = 8
    
    /// Large corner radius
    public static let cornerRadiusL: CGFloat = 12
    
    /// Extra large corner radius
    public static let cornerRadiusXL: CGFloat = 16
}

// MARK: - Color Extension

extension Color {
    /// Initialize Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
