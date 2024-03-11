// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SauceLive_iOS",
    products: [
        .library(
            name: "SauceLive_iOS",
            targets: ["SauceLive_iOS"]),
    ],
    targets: [
        .target(
            name: "SauceLive_iOS",
            resources: [
                .process("Assets")
            ]),
        .testTarget(
            name: "SauceLive_iOSTests",
            dependencies: ["SauceLive_iOS"]),
    ]
)
