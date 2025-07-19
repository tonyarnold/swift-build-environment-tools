// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Tools",
    platforms: [
        .macOS(.v13),
        .macCatalyst(.v16),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1),
    ],
    products: [
        .plugin(
            name: "BuildEnvironmentExtractorPlugin", targets: ["BuildEnvironmentExtractorPlugin"]),
        .plugin(name: "GitInfoPlugin", targets: ["GitInfoPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.6.1")
    ],
    targets: [
        .executableTarget(
            name: "BuildEnvironmentExtractor",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "BuildEnvironmentExtractorTests",
            dependencies: ["BuildEnvironmentExtractor"]
        ),
        .plugin(
            name: "BuildEnvironmentExtractorPlugin",
            capability: .buildTool,
            dependencies: ["BuildEnvironmentExtractor"],
            packageAccess: false
        ),

        .executableTarget(
            name: "GitInfoExtractor",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "GitInfoExtractorTests",
            dependencies: ["GitInfoExtractor"]
        ),
        .plugin(
            name: "GitInfoPlugin",
            capability: .buildTool,
            dependencies: ["GitInfoExtractor"],
            packageAccess: false
        ),
    ]
)
