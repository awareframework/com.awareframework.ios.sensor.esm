// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "com.awareframework.ios.sensor.esm",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "com.awareframework.ios.sensor.esm",
            targets: ["com.awareframework.ios.sensor.esm"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/awareframework/com.awareframework.ios.core.git", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "com.awareframework.ios.sensor.esm",
            dependencies: [
                .product(name: "com.awareframework.ios.core", package: "com.awareframework.ios.core", condition: .when(platforms: [.iOS]))
            ],
            path: "Sources/com.awareframework.ios.sensor.esm"
        ),
        .testTarget(
            name: "com.awareframework.ios.sensor.esmTests",
            dependencies: ["com.awareframework.ios.sensor.esm"]
        )
    ],
    swiftLanguageModes: [.v5]
)
