// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "mindbox_ios",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "mindbox-ios", targets: ["mindbox_ios"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/mindbox-cloud/ios-sdk", from: "2.15.0"),
    ],
    targets: [
        .target(
            name: "mindbox_ios",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "Mindbox", package: "ios-sdk"),
            ]
        )
    ]
)
