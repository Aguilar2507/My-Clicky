// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "MyClicky",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "MyClicky", path: "Sources/MyClicky")
    ]
)
