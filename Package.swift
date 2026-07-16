// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "SwiftGridView",
    platforms: [
        .iOS(.v15)
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
            path: "Tests",
            resources: [
                .process("Assets/SwiftGridTestNibCell.xib")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
