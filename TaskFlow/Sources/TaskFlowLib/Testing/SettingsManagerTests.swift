import Foundation

/// Property-based tests for SettingsManager
/// Feature: multi-select-outlook-integration
public struct SettingsManagerTests {
    
    // MARK: - Property 7: Outlook Integration Setting Persistence
    
    /// Property 7: Outlook Integration Setting Persistence
    /// *For any* boolean value set for outlookIntegrationEnabled, the setting SHALL persist
    /// across SettingsManager accesses and return the same value.
    /// **Validates: Requirements 3.3**
    public static func testOutlookIntegrationSettingPersistence() -> PropertyTestResult {
        PropertyTest.check("Property 7: Outlook Integration Setting Persistence", iterations: 100) {
            let manager = SettingsManager.shared
            
            // Generate random boolean value
            let testValue = Bool.random()
            
            // Set the value
            manager.outlookIntegrationEnabled = testValue
            
            // Verify the value is immediately accessible
            guard manager.outlookIntegrationEnabled == testValue else { return false }
            
            // Verify UserDefaults was updated (simulating persistence)
            let persistedValue = UserDefaults.standard.bool(forKey: "outlookIntegrationEnabled")
            guard persistedValue == testValue else { return false }
            
            return true
        }
    }
    
    // MARK: - Run All Tests
    
    /// Run all SettingsManager property tests
    public static func runAllTests() {
        PropertyTest.runAll([
            testOutlookIntegrationSettingPersistence
        ])
    }
}
