// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "mindbox_ios",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "mindbox-ios", targets: ["mindbox_ios"])
    ],
    dependencies: [
        .package(url: "https://github.com/mindbox-cloud/ios-sdk", exact: "2.15.2"),
    ],
    targets: [
        .target(
            name: "mindbox_ios",
            dependencies: [
                .product(name: "Mindbox", package: "ios-sdk"),
            ]
        )
    ]
)
