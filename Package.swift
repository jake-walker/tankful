// swift-tools-version: 6.1
// This is a Skip (https://skip.dev) package.
import PackageDescription

let package = Package(
    name: "tankful",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TankfulApp", type: .dynamic, targets: ["TankfulApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/skiptools/skip.git", from: "1.9.9"),
        .package(url: "https://github.com/skiptools/skip-fuse-ui.git", from: "1.18.2"),
        .package(url: "https://github.com/skiptools/skip-sql.git", from: "0.16.0"),
        .package(url: "https://github.com/jake-walker/swift-currency.git", branch: "generated"),
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
                .byNameItem(name: "TankfulIntents", condition: .when(platforms: [.iOS, .macOS])),
            ], resources: [.process("Resources")],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
        .target(
            name: "TankfulDomain",
            dependencies: [
                .product(name: "Currency", package: "swift-currency"),
            ]
        ),
        .target(
            name: "TankfulPersistence",
            dependencies: [
                .product(name: "SkipSQLPlus", package: "skip-sql"),
                "TankfulDomain",
            ]
        ),
        .target(
            name: "TankfulSync",
            dependencies: [
                "TankfulDomain",
                .product(name: "Currency", package: "swift-currency"),
            ]
        ),
        .target(
            name: "TankfulIntents",
            dependencies: [
                "TankfulDomain",
                "TankfulPersistence",
                .product(name: "Currency", package: "swift-currency"),
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "TankfulDomainTests",
            dependencies: ["TankfulDomain"]
        ),
    ]
)
