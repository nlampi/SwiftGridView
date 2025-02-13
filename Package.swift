// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "SwiftGridView",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(name: "SwiftGridView", targets: ["SwiftGridView"])
    ],
    targets: [
        .target(
            name: "SwiftGridView",
            path: "Sources"
        ),
        .testTarget(
            name: "SwiftGridViewTests",
            dependencies: ["SwiftGridView"],
            path: "Tests"
        )
    ]
)
