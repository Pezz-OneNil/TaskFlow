import SwiftUI

/// Year selector dropdown for Annual Calendar
/// Per Requirements 2.5, 2.6, 2.7, 2.8
/// Feature: annual-calendar
public struct YearSelectorView: View {
    @Binding var selectedYear: Int
    let yearRange: ClosedRange<Int>
    
    public init(selectedYear: Binding<Int>, yearRange: ClosedRange<Int>) {
        self._selectedYear = selectedYear
        self.yearRange = yearRange
    }
    
    public var body: some View {
        HStack(spacing: CyberpunkTheme.spacingS) {
            // Previous year button
            Button(action: {
                if selectedYear > yearRange.lowerBound {
                    selectedYear -= 1
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(selectedYear > yearRange.lowerBound ? CyberpunkTheme.accentYellow : CyberpunkTheme.textTertiary)
            }
            .buttonStyle(.plain)
            .disabled(selectedYear <= yearRange.lowerBound)
            
            // Year picker
            Picker("Year", selection: $selectedYear) {
                ForEach(Array(yearRange), id: \.self) { year in
                    Text(String(year))
                        .tag(year)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)
            .foregroundColor(CyberpunkTheme.accentYellow)
            .font(CyberpunkTheme.fontHeadline)
            
            // Next year button
            Button(action: {
                if selectedYear < yearRange.upperBound {
                    selectedYear += 1
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(selectedYear < yearRange.upperBound ? CyberpunkTheme.accentYellow : CyberpunkTheme.textTertiary)
            }
            .buttonStyle(.plain)
            .disabled(selectedYear >= yearRange.upperBound)
        }
        .padding(.horizontal, CyberpunkTheme.spacingM)
        .padding(.vertical, CyberpunkTheme.spacingS)
        .background(
            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                .fill(CyberpunkTheme.backgroundPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusM)
                        .stroke(CyberpunkTheme.accentYellow.opacity(0.5), lineWidth: 1)
                )
        )
    }
}
