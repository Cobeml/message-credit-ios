// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PrivacyCreditAnalyzer",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PrivacyCreditAnalyzer",
            targets: ["PrivacyCreditAnalyzer"]
        ),
    ],
    dependencies: [
        // Future dependencies will be added here:
        // - MLX-Swift for on-device AI inference
        // - PostgresClientKit for database communication
    ],
    targets: [
        .target(
            name: "PrivacyCreditAnalyzer",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "PrivacyCreditAnalyzerTests",
            dependencies: ["PrivacyCreditAnalyzer"],
            path: "Tests"
        ),
    ]
)