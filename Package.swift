// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "ServerSideEvent",
    platforms: [
        .iOS("13.0"),
        .macOS("11.0"),
    ],
    products: [
        .library(name: "ServerSideEvent", targets: ["ServerSideEvent"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "ServerSideEvent",
            dependencies: []),
        .testTarget(
            name: "ServerSideEventTests",
            dependencies: ["ServerSideEvent"]),
    ]
)
