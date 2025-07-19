import Testing
import Foundation
@testable import GitInfoExtractor

@Suite("GitInfoExtractor Tests") 
struct GitInfoExtractorTests {
    
    @Test("Git tag simplification - basic tags")
    func testBasicTagSimplification() throws {
        let extractor = try #require(GitInfoExtractor.parseAsRoot(["/tmp/test"]) as? GitInfoExtractor)
        
        // Test direct tags (no additional info)
        #expect(extractor.simplifiedTag(from: "1.0.0") == "1.0.0")
        #expect(extractor.simplifiedTag(from: "v2.1.3") == "2.1.3")  // Remove v prefix
        #expect(extractor.simplifiedTag(from: "release/1.5.0") == "1.5.0")  // Remove namespace
    }
    
    @Test("Git tag simplification - tags with commit info")
    func testTagsWithCommitInfo() throws {
        let extractor = try #require(GitInfoExtractor.parseAsRoot(["/tmp/test"]) as? GitInfoExtractor)
        
        // Test tags with commit count and hash (format: tag-count-hash)
        #expect(extractor.simplifiedTag(from: "1.0.0-5-g1a2b3c4") == "1.0.0+g1a2b3c4")
        #expect(extractor.simplifiedTag(from: "v2.1.0-10-gabcdef1") == "2.1.0+gabcdef1")
        #expect(extractor.simplifiedTag(from: "release/1.5.0-3-g9876543") == "1.5.0+g9876543")
    }
    
    @Test("Git tag simplification - edge cases")
    func testTagSimplificationEdgeCases() throws {
        let extractor = try #require(GitInfoExtractor.parseAsRoot(["/tmp/test"]) as? GitInfoExtractor)
        
        // Test edge cases
        #expect(extractor.simplifiedTag(from: "") == "")
        #expect(extractor.simplifiedTag(from: "   1.0.0   ") == "1.0.0")  // Whitespace trimming
        #expect(extractor.simplifiedTag(from: "complex-tag-name") == "complex-tag-name")  // Non-standard format
        #expect(extractor.simplifiedTag(from: "1.0.0-beta") == "1.0.0-beta")  // Keep non-git suffixes
    }
    
    @Test("Git tag simplification - namespace handling")
    func testNamespaceHandling() throws {
        let extractor = try #require(GitInfoExtractor.parseAsRoot(["/tmp/test"]) as? GitInfoExtractor)
        
        // Test various namespace formats
        #expect(extractor.simplifiedTag(from: "release/1.0.0") == "1.0.0")
        #expect(extractor.simplifiedTag(from: "feature/new-stuff/1.0.0") == "1.0.0")  // Multiple slashes
        #expect(extractor.simplifiedTag(from: "hotfix/critical-fix") == "critical-fix")
    }
    
    
    @Test("Multiple git describe formats")
    func testMultipleGitDescribeFormats() throws {
        let extractor = try #require(GitInfoExtractor.parseAsRoot(["/tmp/test"]) as? GitInfoExtractor)
        
        // Test various git describe output formats
        let testCases: [(input: String, expected: String)] = [
            ("1.0.0", "1.0.0"),                           // Exact tag
            ("1.0.0-5-g1a2b3c4", "1.0.0+g1a2b3c4"),      // Standard format
            ("v2.1.0-10-gabcdef1", "2.1.0+gabcdef1"),     // With v prefix
            ("release/1.5.0-3-g9876543", "1.5.0+g9876543"), // With namespace
            ("feature/new-feature", "new-feature"),        // Branch-like tag
            ("1.0.0-rc1", "1.0.0-rc1"),                   // Pre-release
            ("1.0.0-beta-2-g1234567", "1.0.0-beta+g1234567") // Pre-release with commits
        ]
        
        for (input, expected) in testCases {
            #expect(extractor.simplifiedTag(from: input) == expected, "Failed for input: \(input)")
        }
    }
}
