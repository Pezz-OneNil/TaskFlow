import SwiftUI

/// Event block view displaying a colored event indicator with drag and resize support
/// Per Requirements 4.4, 5.1, 5.3, 5.4, 8.2
/// Feature: annual-calendar
public struct EventBlockView: View {
    let event: CalendarEvent
    let category: EventCategory?
    let isCompact: Bool
    let onTap: () -> Void
    var onMove: ((CalendarEvent, Date) -> Void)?
    var onResize: ((CalendarEvent, Date) -> Void)?
    
    @State private var isHovered = false
    @State private var isDragging = false
    @State private var isResizing = false
    @State private var dragOffset: CGSize = .zero
    @State private var resizeDelta: Int = 0  // Days to add/remove
    
    // Day cell height for calculating drag distance
    private let dayCellHeight: CGFloat = DayCellView.cellHeight
    
    public init(
        event: CalendarEvent,
        category: EventCategory?,
        isCompact: Bool = false,
        onTap: @escaping () -> Void,
        onMove: ((CalendarEvent, Date) -> Void)? = nil,
        onResize: ((CalendarEvent, Date) -> Void)? = nil
    ) {
        self.event = event
        self.category = category
        self.isCompact = isCompact
        self.onTap = onTap
        self.onMove = onMove
        self.onResize = onResize
    }
    
    private var categoryColor: Color {
        category?.color.color ?? CyberpunkTheme.textTertiary
    }
    
    private var textColor: Color {
        category?.color.textColor ?? CyberpunkTheme.textPrimary
    }
    
    private var durationDays: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: event.startDate, to: event.endDate).day ?? 0
        return days + 1  // Include both start and end day
    }
    
    public var body: some View {
        if isCompact {
            compactView
        } else {
            fullView
        }
    }
    
    private var compactView: some View {
        HStack(spacing: 0) {
            // Main event block - draggable to move
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(categoryColor.opacity(0.85))
                
                // Event label
                Text(event.label.isEmpty ? (category?.name ?? "Event") : event.label)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
                    .padding(.trailing, 12)  // Leave room for resize handle
                
                // Duration indicator for multi-day events
                if durationDays > 1 {
                    Text("\(durationDays + resizeDelta)d")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(textColor.opacity(0.7))
                        .padding(.trailing, 14)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                // Border
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isHovered || isDragging || isResizing ? Color.white.opacity(0.8) : categoryColor.opacity(0.5), lineWidth: isHovered || isResizing ? 1.5 : 1)
            }
            .frame(minWidth: 24, maxWidth: .infinity, minHeight: 18, maxHeight: 18)
            .shadow(color: isHovered || isResizing ? categoryColor.opacity(0.7) : categoryColor.opacity(0.3), radius: isHovered ? 4 : 2)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        guard !isResizing else { return }
                        isDragging = true
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        guard !isResizing else { return }
                        isDragging = false
                        dragOffset = .zero
                        // Calculate new date based on vertical drag distance
                        if let onMove = onMove {
                            let daysMoved = Int(round(value.translation.height / dayCellHeight))
                            if daysMoved != 0 {
                                let calendar = Calendar.current
                                if let newStartDate = calendar.date(byAdding: .day, value: daysMoved, to: event.startDate) {
                                    onMove(event, newStartDate)
                                }
                            }
                        }
                    }
            )
            .onTapGesture {
                if !isDragging && !isResizing {
                    onTap()
                }
            }
            
            // Resize handle on the right edge
            ResizeHandleCompact(
                color: categoryColor,
                isActive: isResizing || isHovered,
                onDrag: { delta in
                    isResizing = true
                    // Calculate days based on vertical drag (since calendar is vertical)
                    let daysChange = Int(round(delta / dayCellHeight))
                    resizeDelta = daysChange
                },
                onDragEnd: { delta in
                    isResizing = false
                    let daysChange = Int(round(delta / dayCellHeight))
                    if daysChange != 0, let onResize = onResize {
                        let calendar = Calendar.current
                        if let newEndDate = calendar.date(byAdding: .day, value: daysChange, to: event.endDate) {
                            // Ensure end date is not before start date
                            if newEndDate >= event.startDate {
                                onResize(event, newEndDate)
                            }
                        }
                    }
                    resizeDelta = 0
                }
            )
            .frame(width: 10, height: 18)
        }
        .offset(y: isDragging ? dragOffset.height : 0)
        .opacity(isDragging ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isDragging)
        .onHover { hovering in
            isHovered = hovering
        }
        .help("\(event.label.isEmpty ? (category?.name ?? "Event") : event.label)\n\(durationDays) day(s)\nDrag to move • Drag right edge up/down to resize")
    }
    
    private var fullView: some View {
        HStack(spacing: CyberpunkTheme.spacingXS) {
            // Color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(categoryColor)
                .frame(width: 4)
            
            // Label
            Text(event.label.isEmpty ? (category?.name ?? "Event") : event.label)
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(textColor)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, CyberpunkTheme.spacingS)
        .padding(.vertical, CyberpunkTheme.spacingXS)
        .background(
            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                .fill(categoryColor.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                .stroke(isHovered ? categoryColor : categoryColor.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: isHovered ? categoryColor.opacity(0.5) : categoryColor.opacity(0.3), radius: CyberpunkTheme.glowRadiusSubtle)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onTap()
        }
    }
}

/// Compact resize handle for event blocks - drag vertically to resize
struct ResizeHandleCompact: View {
    let color: Color
    let isActive: Bool
    let onDrag: (CGFloat) -> Void
    let onDragEnd: (CGFloat) -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            // Handle background
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(isActive || isDragging ? 1.0 : 0.6))
            
            // Grip indicator (vertical lines)
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(isActive || isDragging ? 0.9 : 0.5))
                        .frame(width: 2, height: 2)
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 3)
                .onChanged { value in
                    isDragging = true
                    onDrag(value.translation.height)
                }
                .onEnded { value in
                    isDragging = false
                    onDragEnd(value.translation.height)
                }
        )
        .onHover { hovering in
            if hovering {
                NSCursor.resizeUpDown.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

/// Draggable event overlay that spans multiple days with resize handle
public struct DraggableEventOverlay: View {
    let event: CalendarEvent
    let category: EventCategory?
    let dayHeight: CGFloat
    let startDayOffset: Int  // Days from start of visible range
    let durationDays: Int
    let onTap: () -> Void
    let onMove: (CalendarEvent, Date) -> Void
    let onResize: (CalendarEvent, Date) -> Void
    
    @State private var isHovered = false
    @State private var isDragging = false
    @State private var isResizing = false
    @State private var dragOffset: CGSize = .zero
    @State private var resizeOffset: CGFloat = 0
    
    private let resizeHandleHeight: CGFloat = 8
    
    private var categoryColor: Color {
        category?.color.color ?? CyberpunkTheme.textTertiary
    }
    
    private var textColor: Color {
        category?.color.textColor ?? CyberpunkTheme.textPrimary
    }
    
    private var eventHeight: CGFloat {
        CGFloat(durationDays) * dayHeight + resizeOffset
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Main event body
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(categoryColor.opacity(0.85))
                
                // Border
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isHovered || isDragging ? Color.white.opacity(0.8) : categoryColor, lineWidth: isHovered ? 2 : 1)
                
                // Label
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.label.isEmpty ? (category?.name ?? "Event") : event.label)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(textColor)
                        .lineLimit(2)
                    
                    if durationDays > 1 {
                        Text("\(durationDays) days")
                            .font(.system(size: 8))
                            .foregroundColor(textColor.opacity(0.8))
                    }
                }
                .padding(6)
            }
            .frame(height: max(eventHeight - resizeHandleHeight, dayHeight - resizeHandleHeight))
            .shadow(color: categoryColor.opacity(isHovered ? 0.6 : 0.4), radius: isHovered ? 6 : 3)
            
            // Resize handle at bottom
            ResizeHandle(color: categoryColor, isActive: isResizing || isHovered)
                .frame(height: resizeHandleHeight)
                .gesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { value in
                            isResizing = true
                            // Snap to day increments
                            let snappedOffset = round(value.translation.height / dayHeight) * dayHeight
                            resizeOffset = snappedOffset
                        }
                        .onEnded { value in
                            isResizing = false
                            let daysChanged = Int(round(value.translation.height / dayHeight))
                            if daysChanged != 0 {
                                let calendar = Calendar.current
                                if let newEndDate = calendar.date(byAdding: .day, value: daysChanged, to: event.endDate) {
                                    // Ensure end date is not before start date
                                    if newEndDate >= event.startDate {
                                        onResize(event, newEndDate)
                                    }
                                }
                            }
                            resizeOffset = 0
                        }
                )
        }
        .frame(height: eventHeight)
        .offset(y: isDragging ? dragOffset.height : 0)
        .opacity(isDragging ? 0.8 : 1.0)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
            if hovering && !isResizing {
                NSCursor.openHand.push()
            } else if !isResizing {
                NSCursor.pop()
            }
        }
        .onTapGesture {
            onTap()
        }
        .gesture(
            DragGesture(minimumDistance: 5)
                .onChanged { value in
                    guard !isResizing else { return }
                    isDragging = true
                    dragOffset = value.translation
                }
                .onEnded { value in
                    guard !isResizing else { return }
                    isDragging = false
                    let daysMoved = Int(round(value.translation.height / dayHeight))
                    if daysMoved != 0 {
                        let calendar = Calendar.current
                        if let newStartDate = calendar.date(byAdding: .day, value: daysMoved, to: event.startDate) {
                            onMove(event, newStartDate)
                        }
                    }
                    dragOffset = .zero
                }
        )
        .animation(.easeInOut(duration: 0.15), value: isDragging)
        .animation(.easeInOut(duration: 0.1), value: isResizing)
        .help("\(event.label.isEmpty ? (category?.name ?? "Event") : event.label)\nDrag to move • Drag bottom edge to resize")
    }
}

/// Resize handle component
struct ResizeHandle: View {
    let color: Color
    let isActive: Bool
    
    var body: some View {
        ZStack {
            // Handle background
            Rectangle()
                .fill(color.opacity(isActive ? 0.9 : 0.7))
            
            // Grip lines
            VStack(spacing: 1) {
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(Color.white.opacity(isActive ? 0.8 : 0.5))
                        .frame(width: 20, height: 1.5)
                }
            }
        }
        .cornerRadius(2, corners: [.bottomLeft, .bottomRight])
        .onHover { hovering in
            if hovering {
                NSCursor.resizeUpDown.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

/// Extension to apply corner radius to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

/// Custom shape for specific corner rounding
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topLeft = corners.contains(.topLeft) ? radius : 0
        let topRight = corners.contains(.topRight) ? radius : 0
        let bottomLeft = corners.contains(.bottomLeft) ? radius : 0
        let bottomRight = corners.contains(.bottomRight) ? radius : 0
        
        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + topRight),
                         control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY),
                         control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - bottomLeft),
                         control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        path.addQuadCurve(to: CGPoint(x: rect.minX + topLeft, y: rect.minY),
                         control: CGPoint(x: rect.minX, y: rect.minY))
        
        return path
    }
}

/// UIRectCorner equivalent for macOS
public struct UIRectCorner: OptionSet, Sendable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let topLeft = UIRectCorner(rawValue: 1 << 0)
    public static let topRight = UIRectCorner(rawValue: 1 << 1)
    public static let bottomLeft = UIRectCorner(rawValue: 1 << 2)
    public static let bottomRight = UIRectCorner(rawValue: 1 << 3)
    public static let allCorners: UIRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}
