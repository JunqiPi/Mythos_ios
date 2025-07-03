// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MythosApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "MythosApp",
            targets: ["MythosApp"]
        )
    ],
    dependencies: [
        .package(path: "../"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.5.0"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "7.10.0"),
        .package(url: "https://github.com/hmlongco/Factory", from: "2.2.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-perception", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "MythosApp",
            dependencies: [
                .product(name: "MythosCore", package: "MythosCore"),
                .product(name: "MythosNetworking", package: "MythosCore"),
                .product(name: "MythosUI", package: "MythosCore"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "Factory", package: "Factory"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Perception", package: "swift-perception")
            ],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        )
    ]
) 