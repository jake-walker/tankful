// swift-tools-version: 6.1
// This is a Skip (https://skip.dev) package.
import PackageDescription

let package = Package(
    name: "tankful",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TankfulApp", type: .dynamic, targets: ["TankfulApp"])
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.7.2"),
        .package(url: "https://source.skip.tools/skip-fuse-ui.git", from: "1.0.0"),
        .package(url: "https://source.skip.tools/skip-sql.git", from: "0.16.0"),
        .package(url: "https://github.com/Peek-Travel/swift-currency.git", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "TankfulApp",
            dependencies: [
                .product(name: "SkipFuseUI", package: "skip-fuse-ui"),
                "TankfulDomain",
                "TankfulPersistence",
                "TankfulSync",
                .product(name: "Currency", package: "swift-currency"),
            ], resources: [.process("Resources")],
            plugins: [.plugin(name: "skipstone", package: "skip")]),
        .target(
            name: "TankfulDomain",
            dependencies: [
                .product(name: "Currency", package: "swift-currency")
            ]),
        .target(
            name: "TankfulPersistence",
            dependencies: [
                .product(name: "SkipSQL", package: "skip-sql"),
                "TankfulDomain",
            ]),
        .target(
            name: "TankfulSync",
            dependencies: [
                "TankfulDomain",
                .product(name: "Currency", package: "swift-currency"),
            ]),
    ]
)
