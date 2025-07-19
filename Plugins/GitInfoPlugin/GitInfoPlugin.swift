import Foundation
import PackagePlugin

@main
struct GitInfoPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let tool = try context.tool(named: "GitInfoExtractor")
        let outputFileURL = context.pluginWorkDirectoryURL.appending(path: "GitInfo.swift")

        return [
            .buildCommand(
                displayName: "Generating GitInfo.swift from Git metadata",
                executable: tool.url,
                arguments: [outputFileURL.path(percentEncoded: false)],
                outputFiles: [outputFileURL]
            )
        ]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension GitInfoPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let tool = try context.tool(named: "GitInfoExtractor")
        let outputFileURL = context.pluginWorkDirectoryURL.appending(path:"GitInfo.swift")

        return [
            .buildCommand(
                displayName: "Generating GitInfo.swift from Git metadata",
                executable: tool.url,
                arguments: [outputFileURL.path(percentEncoded: false)],
                outputFiles: [outputFileURL]
            )
        ]
    }
}

#endif
