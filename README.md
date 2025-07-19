# Swift Build Environment Tools

Swift Package Manager plugins for generating build-time code from environment variables and Git metadata.

## Features

This package provides two Swift Package Manager build tool plugins:

### BuildEnvironmentExtractorPlugin

Generates Swift code from environment variables at build time. Useful for injecting configuration values, build numbers, or API endpoints into your app without hardcoding them.

**Generated code example:**
```swift
enum BuildEnvironment {
    static let buildNumber = "123"
    static let apiURL = "https://api.example.com"
    // Could not find environment variable for MISSING_VAR
}
```

**Configuration:** Create a `.build-env-to-swift.json` file in your project root:
```json
{
    "generated_type_name": "BuildEnvironment",
    "environment_keys": ["BUILD_NUMBER", "API_URL"],
    "acronyms": ["API", "URL", "ID"]
}
```

**Features:**
- Converts environment variable names to camelCase Swift properties
- Preserves acronyms in uppercase (configurable whitelist)

### GitInfoPlugin

Generates Swift code containing Git metadata including tags and commit counts. No configuration required.

**Generated code example:**
```swift
public enum GitInfo {
    public static let tag = "v1.2.3"
    public static let revision = 142
}
```

**Features:**
- Automatically extracts Git tag and revision count
- Simplifies complex Git tag formats for cleaner version strings

## Requirements

- Swift 6.1+

## Installation

Add this package as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tonyarnold/swift-build-environment-tools.git", from: "1.0.0")
]
```

Then add the plugins to your target:

```swift
.target(
    name: "YourTarget",
    plugins: [
        .plugin(name: "BuildEnvironmentExtractorPlugin", package: "swift-build-environment-tools"),
        .plugin(name: "GitInfoPlugin", package: "swift-build-environment-tools")
    ]
)
```

## Usage

### Using BuildEnvironmentExtractorPlugin

1. Create `.build-env-to-swift.json` in your project root
2. Set environment variables before building
3. The generated `BuildEnvironment.swift` file will be available in your target

### Using GitInfoPlugin

Simply add the plugin to your target. The generated `GitInfo.swift` file will automatically include current Git information.

## License

MIT License - see [LICENSE](LICENSE) file for details.
