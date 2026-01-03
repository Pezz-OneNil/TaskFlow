import Foundation

// Feature: naming-conflict-resolution
// Property 8: Documentation Completeness
// For any type that was renamed, the NAMING_CONVENTIONS.md documentation
// should contain an entry mapping the old name to the new name.
// Validates: Requirements 11.3

/// Tests for documentation completeness of naming conventions
public struct DocumentationCompletenessTests {
    
    /// Known renamed types in TaskFlowMac (TFM prefix)
    public static let tfmRenamedTypes: [(original: String, renamed: String)] = [
        // Models
        ("Task", "TFMTask"),
        ("CalendarEvent", "TFMCalendarEvent"),
        ("EventCategory", "TFMEventCategory"),
        ("TaskActivityStats", "TFMTaskActivityStats"),
        ("TextExtraction", "TFMTextExtraction"),
        
        // Services
        ("TaskManager", "TFMTaskManager"),
        ("SettingsManager", "TFMSettingsManager"),
        ("MenuBarManager", "TFMMenuBarManager"),
        ("CalendarEventManager", "TFMCalendarEventManager"),
        ("AssigneeManager", "TFMAssigneeManager"),
        ("PersistenceManager", "TFMPersistenceManager"),
        ("DatabaseManager", "TFMDatabaseManager"),
        ("BackupManager", "TFMBackupManager"),
        ("EmailCaptureEngine", "TFMEmailCaptureEngine"),
        ("EmailDropHandler", "TFMEmailDropHandler"),
        ("EMLParser", "TFMEMLParser"),
        ("ScreenCaptureEngine", "TFMScreenCaptureEngine"),
        ("ScreenshotManager", "TFMScreenshotManager"),
        ("PomodoroEngine", "TFMPomodoroEngine"),
        ("PriorityScheduler", "TFMPriorityScheduler"),
        ("SearchTermGenerator", "TFMSearchTermGenerator"),
        ("OllamaClient", "TFMOllamaClient"),
        ("LLMSummarizer", "TFMLLMSummarizer"),
        ("PermissionManager", "TFMPermissionManager"),
        ("SelectionManager", "TFMSelectionManager"),
        ("TextExtractor", "TFMTextExtractor"),
        ("URLSchemeHandler", "TFMURLSchemeHandler"),
        ("StatusBarManager", "TFMStatusBarManager"),
        ("EventCategoryManager", "TFMEventCategoryManager"),
        
        // Protocols
        ("TaskManagerProtocol", "TFMTaskManagerProtocol"),
        ("PersistenceManagerProtocol", "TFMPersistenceManagerProtocol"),
        ("ScreenshotManagerProtocol", "TFMScreenshotManagerProtocol"),
        ("LLMSummarizerProtocol", "TFMLLMSummarizerProtocol"),
        ("PomodoroEngineProtocol", "TFMPomodoroEngineProtocol"),
        ("PrioritySchedulerProtocol", "TFMPrioritySchedulerProtocol"),
        
        // Persistence Records
        ("TaskRecord", "TFMTaskRecord"),
        ("CalendarEventRecord", "TFMCalendarEventRecord"),
        ("BackupInfo", "TFMBackupInfo"),
        ("BackupData", "TFMBackupData"),
    ]
    
    /// Known renamed types in TaskFlowTurbo (TFT prefix)
    public static let tftRenamedTypes: [(original: String, renamed: String)] = [
        // Models
        ("Task", "TFTTask"),
        ("CalendarEvent", "TFTCalendarEvent"),
        ("EventCategory", "TFTEventCategory"),
        ("TaskActivityStats", "TFTTaskActivityStats"),
        ("TextExtraction", "TFTTextExtraction"),
        
        // Services
        ("TaskManager", "TFTTaskManager"),
        ("SettingsManager", "TFTSettingsManager"),
        ("MenuBarManager", "TFTMenuBarManager"),
        ("CalendarEventManager", "TFTCalendarEventManager"),
        ("AssigneeManager", "TFTAssigneeManager"),
        ("PersistenceManager", "TFTPersistenceManager"),
        ("DatabaseManager", "TFTDatabaseManager"),
        ("BackupManager", "TFTBackupManager"),
        ("EmailCaptureEngine", "TFTEmailCaptureEngine"),
        ("EmailDropHandler", "TFTEmailDropHandler"),
        ("EMLParser", "TFTEMLParser"),
        ("ScreenCaptureEngine", "TFTScreenCaptureEngine"),
        ("ScreenshotManager", "TFTScreenshotManager"),
        ("PomodoroEngine", "TFTPomodoroEngine"),
        ("PriorityScheduler", "TFTPriorityScheduler"),
        ("SearchTermGenerator", "TFTSearchTermGenerator"),
        ("OllamaClient", "TFTOllamaClient"),
        ("LLMSummarizer", "TFTLLMSummarizer"),
        ("PermissionManager", "TFTPermissionManager"),
        ("SelectionManager", "TFTSelectionManager"),
        ("TextExtractor", "TFTTextExtractor"),
        ("URLSchemeHandler", "TFTURLSchemeHandler"),
        ("StatusBarManager", "TFTStatusBarManager"),
        ("EventCategoryManager", "TFTEventCategoryManager"),
        
        // Protocols
        ("TaskManagerProtocol", "TFTTaskManagerProtocol"),
        ("PersistenceManagerProtocol", "TFTPersistenceManagerProtocol"),
        ("ScreenshotManagerProtocol", "TFTScreenshotManagerProtocol"),
        ("LLMSummarizerProtocol", "TFTLLMSummarizerProtocol"),
        ("PomodoroEngineProtocol", "TFTPomodoroEngineProtocol"),
        ("PrioritySchedulerProtocol", "TFTPrioritySchedulerProtocol"),
        
        // Persistence Records
        ("TaskRecord", "TFTTaskRecord"),
        ("CalendarEventRecord", "TFTCalendarEventRecord"),
        ("BackupInfo", "TFTBackupInfo"),
        ("BackupData", "TFTBackupData"),
    ]
    
    /// Property test: All TFM renamed types are documented
    /// Feature: naming-conflict-resolution, Property 8: Documentation Completeness
    public static func testTFMTypesDocumented(documentationContent: String) -> PropertyTestResult {
        return PropertyTest.check(
            "Property 8: TFM types documented in NAMING_CONVENTIONS.md",
            iterations: tfmRenamedTypes.count
        ) {
            // Check each renamed type is mentioned in documentation
            for (original, renamed) in tfmRenamedTypes {
                if !documentationContent.contains(original) || !documentationContent.contains(renamed) {
                    return false
                }
            }
            return true
        }
    }
    
    /// Property test: All TFT renamed types are documented
    /// Feature: naming-conflict-resolution, Property 8: Documentation Completeness
    public static func testTFTTypesDocumented(documentationContent: String) -> PropertyTestResult {
        return PropertyTest.check(
            "Property 8: TFT types documented in NAMING_CONVENTIONS.md",
            iterations: tftRenamedTypes.count
        ) {
            // Check each renamed type is mentioned in documentation
            for (original, renamed) in tftRenamedTypes {
                if !documentationContent.contains(original) || !documentationContent.contains(renamed) {
                    return false
                }
            }
            return true
        }
    }
    
    /// Property test: Documentation contains both original and renamed names
    /// Feature: naming-conflict-resolution, Property 8: Documentation Completeness
    public static func testDocumentationMappingCompleteness(documentationContent: String) -> PropertyTestResult {
        let allTypes = tfmRenamedTypes + tftRenamedTypes
        var missingMappings: [String] = []
        
        for (original, renamed) in allTypes {
            // Check that both the original and renamed appear in the same table row
            // This is a simplified check - in practice, we'd parse the markdown table
            if !documentationContent.contains(original) {
                missingMappings.append("Missing original: \(original)")
            }
            if !documentationContent.contains(renamed) {
                missingMappings.append("Missing renamed: \(renamed)")
            }
        }
        
        return PropertyTestResult(
            name: "Property 8: All type mappings documented",
            iterations: allTypes.count * 2,
            failures: missingMappings.isEmpty ? [] : [1]
        )
    }
    
    /// Verify documentation file exists and contains required sections
    public static func verifyDocumentationStructure(documentationContent: String) -> PropertyTestResult {
        let requiredSections = [
            "## Prefix Convention",
            "## When to Apply Prefixes",
            "## Renamed Types Reference",
            "### Models",
            "### Services",
            "### Protocols",
            "## Creating New Types",
            "## UserDefaults Key Prefixing",
        ]
        
        var missingSections: [String] = []
        
        for section in requiredSections {
            if !documentationContent.contains(section) {
                missingSections.append(section)
            }
        }
        
        return PropertyTestResult(
            name: "Documentation structure completeness",
            iterations: requiredSections.count,
            failures: missingSections.isEmpty ? [] : Array(1...missingSections.count)
        )
    }
    
    /// Run all documentation completeness tests
    public static func runAllTests(documentationPath: String) {
        guard let content = try? String(contentsOfFile: documentationPath, encoding: .utf8) else {
            print("❌ Could not read documentation file at: \(documentationPath)")
            return
        }
        
        print("Running Documentation Completeness Tests...")
        print("Feature: naming-conflict-resolution")
        print("Property 8: Documentation Completeness\n")
        
        let tests: [PropertyTestResult] = [
            testTFMTypesDocumented(documentationContent: content),
            testTFTTypesDocumented(documentationContent: content),
            testDocumentationMappingCompleteness(documentationContent: content),
            verifyDocumentationStructure(documentationContent: content),
        ]
        
        var passed = 0
        var failed = 0
        
        for result in tests {
            if result.passed {
                print("✅ \(result.name): PASSED")
                passed += 1
            } else {
                print("❌ \(result.name): FAILED")
                failed += 1
            }
        }
        
        print("\n---")
        print("Results: \(passed) passed, \(failed) failed")
    }
}
