// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [
        .iOS(SupportedPlatform.IOSVersion.v14),
        .macOS(SupportedPlatform.MacOSVersion.v12),
        .watchOS(SupportedPlatform.WatchOSVersion.v9)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Networking",
            targets: ["Networking"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint.git", exact: "0.58.2"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Networking",
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: ["Networking"],
            resources: [.process("Resources")],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        )
    ]
)
