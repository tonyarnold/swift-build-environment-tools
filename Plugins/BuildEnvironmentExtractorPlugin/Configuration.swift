import Foundation

struct Configuration: Codable {
    static let filename = ".build-env-to-swift.json"

    /// The name of the generated type that holds the extract build environment variables.
    let generatedTypeName: String?

    /// List of build environment variable names to extract at build time.
    let environmentKeys: [String]

    /// List of acronyms to preserve as uppercase when transforming keys into Swift property names.
    let acronyms: [String]?

    enum CodingKeys: String, CodingKey {
        case generatedTypeName = "generated_type_name"
        case environmentKeys = "environment_keys"
        case acronyms = "acronyms"
    }
}
