// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MythosCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "MythosCore",
            targets: ["MythosCore"]
        ),
        .library(
            name: "MythosUI",
            targets: ["MythosUI"]
        ),
        .library(
            name: "MythosNetworking",
            targets: ["MythosNetworking"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/realm/SwiftLint", from: "0.54.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.5.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.5.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.14.1")
    ],
    targets: [
        // MARK: - Core Module
        .target(
            name: "MythosCore",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "Sources/MythosCore"
        ),
        
        // MARK: - Networking Module
        .target(
            name: "MythosNetworking",
            dependencies: [
                "MythosCore",
                "Alamofire",
                .product(name: "Logging", package: "swift-log")
            ],
            path: "Sources/MythosNetworking"
        ),
        
        // MARK: - UI Module
        .target(
            name: "MythosUI",
            dependencies: [
                "MythosCore",
                "MythosNetworking",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/MythosUI"
        ),
        
    ]
) 