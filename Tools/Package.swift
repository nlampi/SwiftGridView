// swift-tools-version:6.0

// Side-car tools manifest (ADR 0006). This package ships no products and is
// deliberately NOT referenced by the root Package.swift: declaring swift-format
// there would force every consumer to resolve swift-syntax, a large checkout and
// a common source of version conflicts in apps that use macros.
//
// Usage (CI and local are identical):
//   swift run --package-path Tools swift-format lint --strict --recursive Sources Tests Examples
//   swift run --package-path Tools swift-format format --in-place --recursive Sources Tests Examples
import PackageDescription

let package = Package(
    name: "Tools",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-format.git", exact: "603.0.0")
    ]
)
