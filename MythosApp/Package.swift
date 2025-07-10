// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MythosApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MythosApp",
            targets: ["MythosApp"]
        )
    ],
    targets: [
        .target(
            name: "MythosApp",
            path: "Sources"
        )
    ]
)