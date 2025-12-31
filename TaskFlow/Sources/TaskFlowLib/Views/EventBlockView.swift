import SwiftUI

/// Event block view displaying a colored event indicator
/// Per Requirements 4.4, 5.1, 5.3, 5.4, 8.2
/// Feature: annual-calendar
public struct EventBlockView: View {
    let event: CalendarEvent
    let category: EventCategory?
    let isCompact: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    public init(
        event: CalendarEvent,
        category: EventCategory?,
        isCompact: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.event = event
        self.category = category
        self.isCompact = isCompact
        self.onTap = onTap
    }
    
    private var categoryColor: Color {
        category?.color.color ?? CyberpunkTheme.textTertiary
    }
    
    private var textColor: Color {
        category?.color.textColor ?? CyberpunkTheme.textPrimary
    }
    
    public var body: some View {
        if isCompact {
            compactView
        } else {
            fullView
        }
    }
    
    private var compactView: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(categoryColor)
            .frame(width: 8, height: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isHovered ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1)
            )
            .shadow(color: isHovered ? categoryColor.opacity(0.6) : .clear, radius: 4)
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                onTap()
            }
            .help(event.label.isEmpty ? (category?.name ?? "Event") : event.label)
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
                .fill(categoryColor.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusS)
                .stroke(isHovered ? categoryColor : Color.clear, lineWidth: 1)
        )
        .shadow(color: isHovered ? categoryColor.opacity(0.4) : .clear, radius: CyberpunkTheme.glowRadiusSubtle)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onTap()
        }
    }
}
