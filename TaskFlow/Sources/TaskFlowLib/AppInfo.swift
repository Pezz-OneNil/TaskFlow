// ═══════════════════════════════════════════════════════════════════════════════
// TaskFlow - Intelligent Task Management for macOS
// © 2025 Pezz. All rights reserved.
//
// This software is protected by copyright law and international treaties.
// Unauthorized reproduction or distribution of this software, or any portion
// of it, may result in severe civil and criminal penalties.
// ═══════════════════════════════════════════════════════════════════════════════

import Foundation

/// Application information and copyright
public struct AppInfo {
    /// Application name
    public static let name = "TaskFlow"
    
    /// Current version (Semantic Versioning: MAJOR.MINOR.PATCH)
    /// - MAJOR: Breaking changes
    /// - MINOR: New features (backwards compatible)
    /// - PATCH: Bug fixes (backwards compatible)
    public static let version = "1.1.0"
    
    /// Build number (increments with each build)
    public static let build = "6"
    
    /// Copyright year
    public static let copyrightYear = "2025"
    
    /// Author/Owner
    public static let author = "Pezz"
    
    /// Full copyright notice
    public static let copyright = "© \(copyrightYear) \(author). All rights reserved."
    
    /// Short copyright for UI
    public static let shortCopyright = "© \(copyrightYear) \(author)"
    
    /// Bundle identifier
    public static let bundleIdentifier = "com.pezz.taskflow"
    
    /// Full version string
    public static var fullVersion: String {
        "\(version) (\(build))"
    }
    
    /// Legal notice
    public static let legalNotice = """
        TaskFlow is proprietary software.
        
        This software is protected by copyright law and international treaties. \
        Unauthorized copying, modification, distribution, or use of this software \
        is strictly prohibited and may result in severe civil and criminal penalties.
        """
}
