// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "MyClicky",
    platforms: [.macOS(.v14)],
    targets: [
        // Pure logic, models and storage (Foundation only). Checked by MyClickyChecks.
        .target(name: "MyClickyCore", path: "Sources/MyClickyCore"),
        .executableTarget(name: "MyClicky", dependencies: ["MyClickyCore"], path: "Sources/MyClicky"),
        // `swift run MyClickyChecks`: XCTest/Swift Testing don't build with Command Line Tools only.
        .executableTarget(name: "MyClickyChecks", dependencies: ["MyClickyCore"], path: "Sources/MyClickyChecks"),
    ]
)
