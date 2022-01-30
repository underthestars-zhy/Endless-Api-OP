// swift-tools-version:5.5
import PackageDescription

#if os(macOS)
let package = Package(
    name: "EndLess-Api",
    platforms: [
        .macOS(.v12),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.55.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-beta"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0-beta"),
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", from: "0.1.0"),
        .package(url: "https://github.com/leif-ibsen/SwiftECC", from: "2.1.0"),
        .package(url: "https://github.com/vapor/apns.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "CollectionConcurrencyKit", package: "CollectionConcurrencyKit"),
                .product(name: "SwiftECC", package: "SwiftECC"),
                .product(name: "APNS", package: "apns")
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
#else
let package = Package(
    name: "EndLess-Api",
    platforms: [
        .macOS(.v12),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-beta"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0-beta"),
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", from: "0.1.0"),
        .package(url: "https://github.com/vapor/apns.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "CollectionConcurrencyKit", package: "CollectionConcurrencyKit"),
                .product(name: "APNS", package: "apns")
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
#endif
