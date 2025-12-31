import SwiftUI

/// Day cell view displaying a single day with events and activity indicators
/// Per Requirements 2.3, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 8.1, 8.3
/// Feature: annual-calendar
public struct DayCellView: View {
    let date: Date
    let day: Int
    let events: [CalendarEvent]
    let stats: TaskActivityStats?
    let categoryManager: EventCategoryManager
    let isSelected: Bool
    let onTap: () -> Void
    let onEventTap: (CalendarEvent) -> Void
    var onEventMove: ((CalendarEvent, Date) -> Void)?
    var onEventResize: ((CalendarEvent, Date) -> Void)?
    
    @State private var isHovered = false
    
    private let calendar = Calendar.current
    private let dayOfWeekNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    // Increased cell dimensions for better visibility
    static let cellWidth: CGFloat = 80
    static let cellHeight: CGFloat = 32
    
    public init(
        date: Date,
        day: Int,
        events: [CalendarEvent],
        stats: TaskActivityStats?,
        categoryManager: EventCategoryManager,
        isSelected: Bool = false,
        onTap: @escaping () -> Void,
        onEventTap: @escaping (CalendarEvent) -> Void,
        onEventMove: ((CalendarEvent, Date) -> Void)? = nil,
        onEventResize: ((CalendarEvent, Date) -> Void)? = nil
    ) {
        self.date = date
        self.day = day
        self.events = events
        self.stats = stats
        self.categoryManager = categoryManager
        self.isSelected = isSelected
        self.onTap = onTap
        self.onEventTap = onEventTap
        self.onEventMove = onEventMove
        self.onEventResize = onEventResize
    }
    
    private var dayOfWeek: String {
        let weekday = calendar.component(.weekday, from: date)
        return dayOfWeekNames[weekday - 1]
    }
    
    private var isWeekend: Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            // Background - clickable area for creating new events
            Rectangle()
                .fill(backgroundColor)
                .frame(width: Self.cellWidth, height: Self.cellHeight)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }
            
            // Day info overlay (top-left)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 2) {
                    Text("\(day)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isWeekend ? CyberpunkTheme.accentMagenta : CyberpunkTheme.textPrimary)
                    
                    Text(dayOfWeek)
                        .font(.system(size: 8))
                        .foregroundColor(CyberpunkTheme.textTertiary)
                }
                .padding(.leading, 3)
                .padding(.top, 2)
            }
            
            // Activity indicators (top right corner)
            if let stats = stats, stats.hasActivity {
                HStack(spacing: 3) {
                    if stats.tasksAdded > 0 {
                        HStack(spacing: 1) {
                            Text("↑")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(CyberpunkTheme.accentCyan)
                            Text("\(stats.tasksAdded)")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(CyberpunkTheme.accentCyan)
                        }
                    }
                    
                    if stats.tasksCompleted > 0 {
                        HStack(spacing: 1) {
                            Text("↓")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(CyberpunkTheme.accentPurple)
                            Text("\(stats.tasksCompleted)")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(CyberpunkTheme.accentPurple)
                        }
                    }
                }
                .padding(.trailing, 3)
                .padding(.top, 2)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // Event blocks (bottom area) - larger and more visible
            if !events.isEmpty {
                VStack(spacing: 1) {
                    Spacer()
                    
                    HStack(spacing: 2) {
                        ForEach(events.prefix(2), id: \.id) { event in
                            EventBlockView(
                                event: event,
                                category: categoryManager.category(for: event.categoryId),
                                isCompact: true,
                                onTap: { onEventTap(event) },
                                onMove: onEventMove,
                                onResize: onEventResize
                            )
                            .frame(maxWidth: .infinity)
                        }
                        
                        if events.count > 2 {
                            Text("+\(events.count - 2)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(CyberpunkTheme.accentYellow)
                                .padding(.horizontal, 3)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.bottom, 2)
                }
            }
        }
        .frame(width: Self.cellWidth, height: Self.cellHeight)
        .onHover { hovering in
            isHovered = hovering
        }
        .overlay(
            Rectangle()
                .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
        )
    }
    
    private var borderColor: Color {
        if isSelected {
            return CyberpunkTheme.accentYellow
        } else if isHovered {
            return CyberpunkTheme.accentYellow.opacity(0.5)
        }
        return CyberpunkTheme.backgroundTertiary.opacity(0.5)
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return CyberpunkTheme.accentYellow.opacity(0.2)
        }
        
        if isHovered {
            return CyberpunkTheme.backgroundSecondary
        }
        
        return isWeekend ? CyberpunkTheme.backgroundTertiary.opacity(0.5) : CyberpunkTheme.backgroundPrimary
    }
}
