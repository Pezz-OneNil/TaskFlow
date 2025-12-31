import SwiftUI

/// Month column view displaying all days in a month
/// Per Requirements 2.1, 2.2
/// Feature: annual-calendar
public struct MonthColumnView: View {
    let year: Int
    let month: Int
    let events: [CalendarEvent]
    let activityStats: [Date: TaskActivityStats]
    let categoryManager: EventCategoryManager
    let selectedDate: Date?
    let onDayTap: (Date) -> Void
    let onEventTap: (CalendarEvent) -> Void
    var onEventMove: ((CalendarEvent, Date) -> Void)?
    var onEventResize: ((CalendarEvent, Date) -> Void)?
    
    private let calendar = Calendar.current
    private let monthNames = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                              "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    
    public init(
        year: Int,
        month: Int,
        events: [CalendarEvent],
        activityStats: [Date: TaskActivityStats],
        categoryManager: EventCategoryManager,
        selectedDate: Date? = nil,
        onDayTap: @escaping (Date) -> Void,
        onEventTap: @escaping (CalendarEvent) -> Void,
        onEventMove: ((CalendarEvent, Date) -> Void)? = nil,
        onEventResize: ((CalendarEvent, Date) -> Void)? = nil
    ) {
        self.year = year
        self.month = month
        self.events = events
        self.activityStats = activityStats
        self.categoryManager = categoryManager
        self.selectedDate = selectedDate
        self.onDayTap = onDayTap
        self.onEventTap = onEventTap
        self.onEventMove = onEventMove
        self.onEventResize = onEventResize
    }
    
    private var daysInMonth: Int {
        let dateComponents = DateComponents(year: year, month: month)
        guard let date = calendar.date(from: dateComponents),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 30
        }
        return range.count
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Month header
            Text(monthNames[month])
                .font(CyberpunkTheme.fontHeadline)
                .foregroundColor(CyberpunkTheme.accentYellow)
                .frame(width: DayCellView.cellWidth)
                .padding(.vertical, CyberpunkTheme.spacingS)
                .background(CyberpunkTheme.backgroundSecondary)
            
            // Days
            VStack(spacing: 1) {
                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = dateFor(day: day)
                    let dayEvents = eventsForDay(day)
                    let stats = statsForDay(day)
                    let isSelected = isDateSelected(date)
                    
                    DayCellView(
                        date: date,
                        day: day,
                        events: dayEvents,
                        stats: stats,
                        categoryManager: categoryManager,
                        isSelected: isSelected,
                        onTap: { onDayTap(date) },
                        onEventTap: onEventTap,
                        onEventMove: onEventMove,
                        onEventResize: onEventResize
                    )
                }
            }
        }
        .background(CyberpunkTheme.backgroundTertiary.opacity(0.3))
        .cornerRadius(CyberpunkTheme.cornerRadiusS)
    }
    
    private func dateFor(day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
    
    private func eventsForDay(_ day: Int) -> [CalendarEvent] {
        let date = dateFor(day: day)
        return events.filter { $0.contains(date: date) }
    }
    
    private func statsForDay(_ day: Int) -> TaskActivityStats? {
        let date = dateFor(day: day)
        let normalizedDate = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: date))!
        return activityStats[normalizedDate]
    }
    
    private func isDateSelected(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selected)
    }
}
