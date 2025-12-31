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
    
    @State private var isHovered = false
    
    private let calendar = Calendar.current
    private let dayOfWeekNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    public init(
        date: Date,
        day: Int,
        events: [CalendarEvent],
        stats: TaskActivityStats?,
        categoryManager: EventCategoryManager,
        isSelected: Bool = false,
        onTap: @escaping () -> Void,
        onEventTap: @escaping (CalendarEvent) -> Void
    ) {
        self.date = date
        self.day = day
        self.events = events
        self.stats = stats
        self.categoryManager = categoryManager
        self.isSelected = isSelected
        self.onTap = onTap
        self.onEventTap = onEventTap
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
            // Background
            Rectangle()
                .fill(backgroundColor)
                .frame(width: 70, height: 24)
            
            // Event blocks (stacked)
            HStack(spacing: 1) {
                ForEach(events.prefix(3), id: \.id) { event in
                    EventBlockView(
                        event: event,
                        category: categoryManager.category(for: event.categoryId),
                        isCompact: true,
                        onTap: { onEventTap(event) }
                    )
                }
                
                if events.count > 3 {
                    Text("+\(events.count - 3)")
                        .font(.system(size: 8))
                        .foregroundColor(CyberpunkTheme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 2)
            
            // Day number and weekday
            HStack(spacing: 2) {
                Text("\(day)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isWeekend ? CyberpunkTheme.accentMagenta : CyberpunkTheme.textPrimary)
                
                Text(dayOfWeek)
                    .font(.system(size: 7))
                    .foregroundColor(CyberpunkTheme.textTertiary)
            }
            .padding(.leading, 2)
            .padding(.top, 2)
            
            // Activity indicators (top right corner)
            if let stats = stats, stats.hasActivity {
                HStack(spacing: 2) {
                    if stats.tasksAdded > 0 {
                        HStack(spacing: 0) {
                            Text("↑")
                                .font(.system(size: 7))
                                .foregroundColor(CyberpunkTheme.accentCyan)
                            Text("\(stats.tasksAdded)")
                                .font(.system(size: 7))
                                .foregroundColor(CyberpunkTheme.accentCyan)
                        }
                    }
                    
                    if stats.tasksCompleted > 0 {
                        HStack(spacing: 0) {
                            Text("↓")
                                .font(.system(size: 7))
                                .foregroundColor(CyberpunkTheme.accentPurple)
                            Text("\(stats.tasksCompleted)")
                                .font(.system(size: 7))
                                .foregroundColor(CyberpunkTheme.accentPurple)
                        }
                    }
                }
                .padding(.trailing, 2)
                .padding(.top, 2)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(width: 70, height: 24)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onTap()
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
        return Color.clear
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return CyberpunkTheme.accentYellow.opacity(0.2)
        }
        
        if !events.isEmpty {
            // Show first event's category color as subtle background
            if let firstEvent = events.first,
               let category = categoryManager.category(for: firstEvent.categoryId) {
                return category.color.color.opacity(0.15)
            }
        }
        
        if isHovered {
            return CyberpunkTheme.backgroundSecondary
        }
        
        return isWeekend ? CyberpunkTheme.backgroundTertiary.opacity(0.5) : CyberpunkTheme.backgroundPrimary
    }
}
