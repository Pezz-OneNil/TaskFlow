import Foundation

/// Simple property-based testing utilities
public struct PropertyTest {
    
    /// Run a property test with the given number of iterations
    public static func check(
        _ name: String,
        iterations: Int = 100,
        property: () -> Bool
    ) -> PropertyTestResult {
        var failures: [Int] = []
        
        for i in 1...iterations {
            if !property() {
                failures.append(i)
            }
        }
        
        return PropertyTestResult(
            name: name,
            iterations: iterations,
            failures: failures
        )
    }
    
    /// Run all property tests and print results
    public static func runAll(_ tests: [() -> PropertyTestResult]) {
        print("Running \(tests.count) property tests...\n")
        
        var passed = 0
        var failed = 0
        
        for test in tests {
            let result = test()
            if result.passed {
                print("✅ \(result.name): PASSED (\(result.iterations) iterations)")
                passed += 1
            } else {
                print("❌ \(result.name): FAILED at iterations \(result.failures)")
                failed += 1
            }
        }
        
        print("\n---")
        print("Results: \(passed) passed, \(failed) failed")
    }
}

public struct PropertyTestResult {
    public let name: String
    public let iterations: Int
    public let failures: [Int]
    
    public var passed: Bool { failures.isEmpty }
}
