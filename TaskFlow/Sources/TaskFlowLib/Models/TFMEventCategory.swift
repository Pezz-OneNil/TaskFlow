import Foundation
import SwiftUI

/// Preset color options for calendar event categories
/// Per Requirements 3.1, 3.6 - 10 cyberpunk-style colors
public enum TFMCategoryColor: Int, Codable, CaseIterable, Equatable {
    case neonPink = 1
    case electricBlue = 2
    case acidGreen = 3
    case hotOrange = 4
    case deepPurple = 5
    case goldenYellow = 6
    case crimsonRed = 7
    case mintGreen = 8
    case skyBlue = 9
    case lavender = 10
    
    /// The SwiftUI Color for this category
    public var color: Color {
        switch self {
        case .neonPink: return Color(hex: "FF006E")
        case .electricBlue: return Color(hex: "00F5FF")
        case .acidGreen: return Color(hex: "39FF14")
        case .hotOrange: return Color(hex: "FF6B35")
        case .deepPurple: return Color(hex: "9D4EDD")
        case .goldenYellow: return Color(hex: "FFE66D")
        case .crimsonRed: return Color(hex: "DC143C")
        case .mintGreen: return Color(hex: "00FF7F")
        case .skyBlue: return Color(hex: "87CEEB")
        case .lavender: return Color(hex: "E6E6FA")
        }
    }
    
    /// Text color for readability against the background
    public var textColor: Color {
        switch self {
        case .goldenYellow, .mintGreen, .skyBlue, .lavender:
            return Color.black
        default:
            return Color.white
        }
    }
    
    /// Default display name for the color
    public var defaultName: String {
        switch self {
        case .neonPink: return "Neon Pink"
        case .electricBlue: return "Electric Blue"
        case .acidGreen: return "Acid Green"
        case .hotOrange: return "Hot Orange"
        case .deepPurple: return "Deep Purple"
        case .goldenYellow: return "Golden Yellow"
        case .crimsonRed: return "Crimson Red"
        case .mintGreen: return "Mint Green"
        case .skyBlue: return "Sky Blue"
        case .lavender: return "Lavender"
        }
    }
}

/// A named category for calendar events with a preset color
/// Per Requirements 3.1, 3.2, 3.3
public struct TFMEventCategory: Identifiable, Codable, Equatable {
    /// Category ID (1-10, corresponds to TFMCategoryColor rawValue)
    public let id: Int
    
    /// User-editable name for the category
    public var name: String
    
    /// The preset color for this category
    public let color: TFMCategoryColor
    
    public init(id: Int, name: String, color: TFMCategoryColor) {
        self.id = id
        self.name = name
        self.color = color
    }
    
    /// Create a category with default name from color
    public init(color: TFMCategoryColor) {
        self.id = color.rawValue
        self.name = "Category \(color.rawValue)"
        self.color = color
    }
}

// MARK: - Backward Compatibility

@available(*, deprecated, renamed: "TFMCategoryColor")
public typealias CategoryColor = TFMCategoryColor

@available(*, deprecated, renamed: "TFMEventCategory")
public typealias EventCategory = TFMEventCategory
