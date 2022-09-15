// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "PlaySRG-GoogleCastSDK-ios-no-bluetooth",
        platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "PlaySRG-GoogleCastSDK-ios-no-bluetooth",
            targets: ["PlaySRG-GoogleCastSDK-ios-no-bluetooth"]
        )
    ],
    dependencies: [
        .package(name: "GoogleCastSDK-ios-no-bluetooth", url: "https://github.com/SRGSSR/GoogleCastSDK-ios-no-bluetooth.git", .upToNextMajor(from: "4.7.1-beta.1"))
    ],
    targets: [
        .target(
            name: "PlaySRG-GoogleCastSDK-ios-no-bluetooth",
            dependencies: [
                .product(name: "GoogleCastSDK-ios-no-bluetooth", package: "GoogleCastSDK-ios-no-bluetooth")
            ]
        )
    ]
)
