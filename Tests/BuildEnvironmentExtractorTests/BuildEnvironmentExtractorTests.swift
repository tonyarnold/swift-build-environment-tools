import Testing
import Foundation
@testable import BuildEnvironmentExtractor

@Suite("BuildEnvironmentExtractor Tests")
struct BuildEnvironmentExtractorTests {
    
    @Test("CamelCase conversion - basic cases")
    func testBasicCamelCaseConversion() throws {
        let extractor = try #require(BuildEnvironmentExtractor.parseAsRoot(["/tmp/test", "--keys", "dummy"]) as? BuildEnvironmentExtractor)
        
        // Test basic conversion
        #expect(extractor.camelCase(from: "BUILD_NUMBER", acronymWhitelist: Set()) == "buildNumber")
        #expect(extractor.camelCase(from: "API_KEY", acronymWhitelist: Set()) == "apiKey")
        #expect(extractor.camelCase(from: "SIMPLE", acronymWhitelist: Set()) == "simple")
        #expect(extractor.camelCase(from: "MULTI_WORD_VARIABLE", acronymWhitelist: Set()) == "multiWordVariable")
    }
    
    @Test("CamelCase conversion - with acronyms")
    func testCamelCaseWithAcronyms() throws {
        let extractor = try #require(BuildEnvironmentExtractor.parseAsRoot(["/tmp/test", "--keys", "dummy"]) as? BuildEnvironmentExtractor)
        let acronyms: Set<String> = ["API", "URL", "ID", "HTTP", "JSON"]
        
        // Test acronym preservation
        #expect(extractor.camelCase(from: "API_URL", acronymWhitelist: acronyms) == "apiURL")
        #expect(extractor.camelCase(from: "USER_ID", acronymWhitelist: acronyms) == "userID")
        #expect(extractor.camelCase(from: "HTTP_ENDPOINT", acronymWhitelist: acronyms) == "httpEndpoint")
        #expect(extractor.camelCase(from: "JSON_API_URL", acronymWhitelist: acronyms) == "jsonAPIURL")
    }
    
    @Test("CamelCase conversion - edge cases")
    func testCamelCaseEdgeCases() throws {
        let extractor = try #require(BuildEnvironmentExtractor.parseAsRoot(["/tmp/test", "--keys", "dummy"]) as? BuildEnvironmentExtractor)
        
        // Test edge cases
        #expect(extractor.camelCase(from: "", acronymWhitelist: Set()) == "")
        #expect(extractor.camelCase(from: "A", acronymWhitelist: Set()) == "a")
        #expect(extractor.camelCase(from: "A_B", acronymWhitelist: Set()) == "aB")
        #expect(extractor.camelCase(from: "LOWERCASE", acronymWhitelist: Set()) == "lowercase")
    }
    
    @Test("Environment variable processing")
    func testEnvironmentVariableProcessing() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let outputFile = tempDir.appendingPathComponent("test-output.swift")
        
        // Set up test environment variables
        setenv("TEST_VAR", "test_value", 1)
        setenv("API_URL", "https://api.example.com", 1)
        
        // Test the logic directly by calling run with proper initialization
        let result = try #require(await BuildEnvironmentExtractor.parseAsRoot([
            outputFile.path,
            "--keys", "TEST_VAR,API_URL,MISSING_VAR",
            "--generated-type-name", "TestEnvironment"
        ]) as? BuildEnvironmentExtractor)
        try await result.run()
        
        // Verify output file exists
        #expect(FileManager.default.fileExists(atPath: outputFile.path))
        
        // Read and verify content
        let content = try String(contentsOf: outputFile, encoding: .utf8)
        #expect(content.contains("enum TestEnvironment"))
        #expect(content.contains("static let testVar = \"test_value\""))
        #expect(content.contains("static let apiURL = \"https://api.example.com\""))
        #expect(content.contains("Could not find environment variable for MISSING_VAR"))
        
        // Clean up
        try? FileManager.default.removeItem(at: outputFile)
        unsetenv("TEST_VAR")
        unsetenv("API_URL")
    }
    
    @Test("Default acronym whitelist")
    func testDefaultAcronymWhitelist() throws {
        // Create an instance to test camelCase method  
        let extractor = try #require(BuildEnvironmentExtractor.parseAsRoot([
            "/tmp/test", "--keys", "dummy"
        ]) as? BuildEnvironmentExtractor)
        
        // Test with default acronyms
        #expect(extractor.camelCase(from: "API_URL", acronymWhitelist: BuildEnvironmentExtractor.acronymWhitelist) == "apiURL")
        #expect(extractor.camelCase(from: "USER_ID", acronymWhitelist: BuildEnvironmentExtractor.acronymWhitelist) == "userID")
        #expect(extractor.camelCase(from: "HTTP_JSON_API", acronymWhitelist: BuildEnvironmentExtractor.acronymWhitelist) == "httpJSONAPI")
    }
    
    @Test("Custom acronym whitelist override")
    func testCustomAcronymWhitelist() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let outputFile = tempDir.appendingPathComponent("test-acronym-output.swift")
        
        // Set up test environment
        setenv("CUSTOM_API", "test", 1)
        
        let result = try #require(await BuildEnvironmentExtractor.parseAsRoot([
            outputFile.path,
            "--keys", "CUSTOM_API",
            "--acronym-whitelist", "CUSTOM"  // Only CUSTOM is in whitelist, not API
        ]) as? BuildEnvironmentExtractor)
        try await result.run()
        
        let content = try String(contentsOf: outputFile, encoding: .utf8)
        #expect(content.contains("static let customApi = \"test\""))  // API should be lowercase since not in custom whitelist
        
        // Clean up
        try? FileManager.default.removeItem(at: outputFile)
        unsetenv("CUSTOM_API")
    }
}
