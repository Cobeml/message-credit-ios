// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PrivacyCreditAnalyzer",
    platforms: [
        .iOS(.v17),
        .macOS("13.3")
    ],
    products: [
        .library(
            name: "PrivacyCreditAnalyzer",
            targets: ["PrivacyCreditAnalyzer"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift.git", from: "0.18.0"),
        // Cryptographic and verification dependencies
        // Note: CryptoKit and DeviceCheck are system frameworks, not SPM packages
        // Future dependencies:
        // - PostgresClientKit for database communication
        // - EZKL Swift wrapper for Zero-Knowledge Proofs (to be added in Phase 3)
    ],
    targets: [
        .target(
            name: "PrivacyCreditAnalyzer",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXNN", package: "mlx-swift"),
                .product(name: "MLXOptimizers", package: "mlx-swift"),
                .product(name: "MLXRandom", package: "mlx-swift")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "PrivacyCreditAnalyzerTests",
            dependencies: ["PrivacyCreditAnalyzer"],
            path: "Tests"
        ),
    ]
)