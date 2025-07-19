import Foundation
import PackagePlugin

@main
struct BuildEnvironmentExtractorPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) throws -> [Command] {
        let tool = try context.tool(named: "BuildEnvironmentExtractor")
        return try makeBuildCommand(
            directoryURL: context.package.directoryURL,
            workingDirectoryURL: context.pluginWorkDirectoryURL,
            toolURL: tool.url
        )
    }

    private func findConfigFile(
        named filename: String,
        startingAt start: URL
    ) -> URL? {
        var current = start

        while true {
            let candidate = current.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }

            let parent = current.deletingLastPathComponent()
            if parent == current { // Reached root
                return nil
            }

            current = parent
        }
    }

    fileprivate func makeBuildCommand(
        directoryURL: URL,
        workingDirectoryURL: URL,
        toolURL: URL
    ) throws -> [Command] {
        if let configURL = findConfigFile(named: Configuration.filename, startingAt: directoryURL) {
            let data = try Data(contentsOf: configURL)
            let config = try JSONDecoder().decode(Configuration.self, from: data)
            let keys = config.environmentKeys

            var arguments: [String] = ["--keys", keys.joined(separator: ",")]

            if let acronyms = config.acronyms, acronyms.isEmpty == false {
                arguments.append(contentsOf: ["--acronym-whitelist", acronyms.joined(separator: ",")])
            }

            if let generatedTypeName = config.generatedTypeName, generatedTypeName.isEmpty == false {
                arguments.append(contentsOf: ["--generated-type-name", generatedTypeName])
            }

            let outputFileURL = workingDirectoryURL.appending(path: "BuildEnvironment.swift")
            arguments.append(outputFileURL.path(percentEncoded: false))

            return [
                .buildCommand(
                    displayName: "Generating BuildEnvironment.swift from environment variables",
                    executable: toolURL,
                    arguments: arguments,
                    environment: ProcessInfo.processInfo.environment,
                    outputFiles: [outputFileURL]
                )
            ]
        } else {
            print("warning: \(Configuration.filename) not found, no build environment variables will be extracted")
            return []
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension BuildEnvironmentExtractorPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(
        context: XcodePluginContext,
        target: XcodeTarget
    ) throws -> [Command] {
        let tool = try context.tool(named: "BuildEnvironmentExtractor")
        return try makeBuildCommand(
            directoryURL: context.xcodeProject.directoryURL,
            workingDirectoryURL: context.pluginWorkDirectoryURL,
            toolURL: tool.url
        )
    }
}
#endif
