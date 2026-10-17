// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KotobaCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "KotobaCore", targets: ["KotobaCore"])],
    targets: [
        .target(name: "KotobaCore", resources: [.process("Resources")]),
        .testTarget(name: "KotobaCoreTests", dependencies: ["KotobaCore"])
    ]
)
