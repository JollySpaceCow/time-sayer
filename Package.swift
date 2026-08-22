// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TimeSayer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TimeSayer", targets: ["TimeSayer"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "TimeSayer",
            dependencies: [],
            path: "Sources/TimeSayer"
        )
    ]
)
