import Foundation

/// A tiny test harness: `swift run MyClickyChecks`. XCTest and Swift Testing don't build with Command Line Tools
/// only (verified 2026-09-24), so checks are plain functions grouped by area.
enum Check {
    nonisolated(unsafe) static var passed = 0
    nonisolated(unsafe) static var failed: [String] = []
    nonisolated(unsafe) static var currentGroup = ""

    static func group(_ name: String, _ body: () throws -> Void) {
        currentGroup = name
        let before = (passed, failed.count)
        do { try body() } catch { fail("threw \(error)") }
        let ok = passed - before.0, bad = failed.count - before.1
        print(bad == 0 ? "✓ \(name) (\(ok))" : "✗ \(name) (\(ok) passed, \(bad) failed)")
    }

    static func expect(_ condition: Bool, _ message: @autoclosure () -> String = "", file: String = #fileID, line: Int = #line) {
        if condition { passed += 1 } else { fail("\(message()) [\(file):\(line)]") }
    }

    static func equal<T: Equatable>(_ actual: T, _ expected: T, _ message: @autoclosure () -> String = "",
                                    file: String = #fileID, line: Int = #line) {
        if actual == expected { passed += 1 } else {
            fail("\(message()) expected \(expected), got \(actual) [\(file):\(line)]")
        }
    }

    static func near(_ actual: Double, _ expected: Double, tolerance: Double = 1e-9, _ message: @autoclosure () -> String = "",
                     file: String = #fileID, line: Int = #line) {
        if abs(actual - expected) <= tolerance { passed += 1 } else {
            fail("\(message()) expected ≈\(expected), got \(actual) [\(file):\(line)]")
        }
    }

    private static func fail(_ message: String) {
        failed.append("\(currentGroup): \(message)")
    }

    /// Prints the summary and exits with status 1 if anything failed.
    static func finish() -> Never {
        print("")
        if failed.isEmpty {
            print("All \(passed) checks passed")
            exit(0)
        }
        failed.forEach { print("  FAILED \($0)") }
        print("\(failed.count) failed, \(passed) passed")
        exit(1)
    }

    /// A fresh temporary folder for store checks.
    static func tempPaths() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("MyClickyChecks-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
