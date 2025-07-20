// swift-tools-version: 6.1
import PackageDescription

// Plugin dependencies - use binary targets when available, fallback to source
var buildEnvironmentExtractorPluginDependencies: [Target.Dependency] = []
var gitInfoPluginDependencies: [Target.Dependency] = []

#if os(macOS)
    buildEnvironmentExtractorPluginDependencies = [.target(name: "BuildEnvironmentExtractorBinary")]
    gitInfoPluginDependencies = [.target(name: "GitInfoExtractorBinary")]
#else
    // Fallback to source targets for non-macOS platforms
    buildEnvironmentExtractorPluginDependencies = [.target(name: "BuildEnvironmentExtractor")]
    gitInfoPluginDependencies = [.target(name: "GitInfoExtractor")]
#endif

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
        // Source targets for development and as a fallback
        .executableTarget(
            name: "BuildEnvironmentExtractor",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .executableTarget(
            name: "GitInfoExtractor",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),

        // Plugins
        .plugin(
            name: "BuildEnvironmentExtractorPlugin",
            capability: .buildTool,
            dependencies: buildEnvironmentExtractorPluginDependencies,
            packageAccess: false
        ),
        .plugin(
            name: "GitInfoPlugin",
            capability: .buildTool,
            dependencies: gitInfoPluginDependencies,
            packageAccess: false
        ),

        // Tests
        .testTarget(
            name: "BuildEnvironmentExtractorTests",
            dependencies: ["BuildEnvironmentExtractor"]
        ),
        .testTarget(
            name: "GitInfoExtractorTests",
            dependencies: ["GitInfoExtractor"]
        ),
    ]
)

// Add binary targets for macOS when available
#if os(macOS)
    package.targets.append(contentsOf: [
        .binaryTarget(
            name: "BuildEnvironmentExtractorBinary",
            url:
                "https://github.com/tonyarnold/swift-build-environment-tools/releases/download/1.0.0/BuildEnvironmentExtractor.artifactbundle.zip",
            checksum: "1282b5d82d80f670776c0158c39cd73838fd7cbcdebe4ad11af1c2bc338ec32d"
        ),
        .binaryTarget(
            name: "GitInfoExtractorBinary",
            url:
                "https://github.com/tonyarnold/swift-build-environment-tools/releases/download/1.0.0/GitInfoExtractor.artifactbundle.zip",
            checksum: "62f1c9ac711127000622defa08aef2d8bf7ebae4d9264b892517d35c2293226c"
        ),
    ])
#endif
