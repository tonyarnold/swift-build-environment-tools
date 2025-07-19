// swift-format-ignore: OrderedImports
#if os(Linux)
    // This needs to remain at the top of the file to ensure that stderr is imported with @preconcurrency
    @preconcurrency import Glibc
#else
    import Darwin.C
#endif

import ArgumentParser
import Foundation

@main
struct GitInfoExtractor: AsyncParsableCommand {
    @Argument(help: "Path to output Swift file")
    var outputPath: String

    func run() async throws {
        let tag = try await shell("git", "describe", "--tags")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let count = try await shell("git", "rev-list", "--count", "HEAD")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let simplifiedTag = simplifiedTag(from: tag)

        let contents = """
            public enum GitInfo {
                public static let tag = "\(simplifiedTag)"
                public static let revision = \(count)
            }
            """

        try contents.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
    }

    func shell(_ args: String...) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = args

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(decoding: errorData, as: UTF8.self)
            throw RuntimeError("Command failed: \(args.joined(separator: " "))\n\(errorMessage)")
        }

        let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
        return String(decoding: outputData, as: UTF8.self)
    }

    func simplifiedTag(from rawTag: String) -> String {
        let trimmed = rawTag.trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip leading namespace (e.g., "release/")
        var tagPart = trimmed.split(separator: "/").last.map(String.init) ?? trimmed
        
        // Remove "v" prefix if present
        if tagPart.hasPrefix("v") {
            tagPart = String(tagPart.dropFirst())
        }

        // If HEAD is on a tag, return it directly (no dashes in the suffix)
        if !tagPart.contains("-") {
            return tagPart
        }

        // Match e.g. "1.0.0-5-gd7f70d88f" or "1.0.0-beta-2-g1234567"
        let components = tagPart.split(separator: "-", omittingEmptySubsequences: false)
        
        // Handle standard format: tag-count-hash (hash starts with 'g')
        if components.count == 3, let base = components.first, let hash = components.last, hash.hasPrefix("g") {
            return "\(base)+\(hash)"
        }
        
        // Handle pre-release format: tag-prerelease-count-hash (hash starts with 'g')
        if components.count == 4, let base = components.first, let prerelease = components.dropFirst().first, let hash = components.last, hash.hasPrefix("g") {
            return "\(base)-\(prerelease)+\(hash)"
        }

        return tagPart
    }

    struct RuntimeError: Error, CustomStringConvertible {
        let message: String
        init(_ message: String) { self.message = message }
        var description: String { message }
    }
}
