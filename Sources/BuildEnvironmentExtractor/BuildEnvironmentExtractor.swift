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
struct BuildEnvironmentExtractor: AsyncParsableCommand {
    @Argument(help: "The output path for the generated Swift file")
    var outputPath: String

    @Option(help: "The name of the generated type that holds the environment variables")
    var generatedTypeName: String = "BuildEnvironment"

    @Option(name: .customLong("keys"), help: "A list of environment variables to extract and inject")
    var keysRaw: String

    private var keys: [String] {
        keysRaw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    @Option(name: .customLong("acronym-whitelist"), help: "A list of acronyms to capitalize in the extracted variable names")
    var acronymsRaw: String = ""

    private var acronyms: Set<String> {
        Set(acronymsRaw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
    }

    func run() async throws {
        let env = ProcessInfo.processInfo.environment
        var outputLines: [String] = []

        let acronymWhitelist = acronyms.isEmpty ? Self.acronymWhitelist : self.acronyms

        for key in keys {
            if let value = env[key] {
                let fieldName = camelCase(from: key, acronymWhitelist: acronymWhitelist)
                let line = "    static let \(fieldName) = \"\(value)\""
                outputLines.append(line)
            } else {
                outputLines.append("    // Could not find environment variable for \(key)")
                fputs("warning: Missing build environment variable \(key), entry skipped\n", stderr)
            }
        }

        var output = "enum \(generatedTypeName) {\n"
        output += outputLines.joined(separator: "\n")
        output += "\n}\n"

        try output.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
    }

    static let acronymWhitelist: Set<String> = [
        "ID",
        "URL",
        "UTI",
        "API",
        "IP",
        "UUID",
        "HTTP",
        "XML",
        "JSON"
    ]

    func camelCase(from key: String, acronymWhitelist: Set<String>) -> String {
        let parts = key.split(separator: "_")
        guard let first = parts.first else { return key.lowercased() }

        let head = first.lowercased()
        let tail = parts.dropFirst().map { part -> String in
            let s = String(part)
            if acronymWhitelist.contains(s.uppercased()) {
                return s.uppercased()
            } else {
                return s.capitalized
            }
        }

        return ([head] + tail).joined()
    }
}
