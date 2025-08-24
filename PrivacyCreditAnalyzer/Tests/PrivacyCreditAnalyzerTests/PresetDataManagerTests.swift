import XCTest
@testable import PrivacyCreditAnalyzer

final class PresetDataManagerTests: XCTestCase {
    
    var presetManager: PresetDataManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        presetManager = PresetDataManager()
    }
    
    override func tearDownWithError() throws {
        presetManager.cleanupTemporaryFiles()
        presetManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testPresetTypes() {
        let presetInfo = presetManager.getPresetInfo()
        
        XCTAssertEqual(presetInfo.count, 2)
        
        let responsiblePreset = presetInfo.first { $0.type == .responsibleUser }!
        XCTAssertEqual(responsiblePreset.title, "Responsible User Sample")
        XCTAssertEqual(responsiblePreset.icon, "🏆")
        XCTAssertGreaterThan(responsiblePreset.expectedScore, 0.8)
        XCTAssertTrue(responsiblePreset.riskLevel.contains("LOW RISK"))
        
        let irresponsiblePreset = presetInfo.first { $0.type == .irresponsibleUser }!
        XCTAssertEqual(irresponsiblePreset.title, "Irresponsible User Sample")
        XCTAssertEqual(irresponsiblePreset.icon, "📉")
        XCTAssertLessThan(irresponsiblePreset.expectedScore, 0.5)
        XCTAssertTrue(irresponsiblePreset.riskLevel.contains("VERY HIGH RISK"))
    }
    
    func testLoadPresetMessages() {
        let responsibleMessages = presetManager.loadPresetMessages(type: .responsibleUser)
        let irresponsibleMessages = presetManager.loadPresetMessages(type: .irresponsibleUser)
        
        XCTAssertEqual(responsibleMessages.count, 15)
        XCTAssertEqual(irresponsibleMessages.count, 15)
        
        // Verify message content differences
        let responsibleContent = responsibleMessages.map { $0.content }.joined().lowercased()
        let irresponsibleContent = irresponsibleMessages.map { $0.content }.joined().lowercased()
        
        XCTAssertTrue(responsibleContent.contains("budget"))
        XCTAssertTrue(responsibleContent.contains("savings"))
        XCTAssertFalse(responsibleContent.contains("overdraft"))
        
        XCTAssertTrue(irresponsibleContent.contains("overdraft"))
        XCTAssertTrue(irresponsibleContent.contains("maxed out"))
        XCTAssertFalse(irresponsibleContent.contains("budget"))
    }
    
    func testLoadPresetJSON() {
        let responsibleJSON = presetManager.loadPresetJSON(type: .responsibleUser)
        let irresponsibleJSON = presetManager.loadPresetJSON(type: .irresponsibleUser)
        
        XCTAssertTrue(responsibleJSON.contains("Responsible User Sample"))
        XCTAssertTrue(responsibleJSON.contains("export_info"))
        XCTAssertTrue(responsibleJSON.contains("messages"))
        
        XCTAssertTrue(irresponsibleJSON.contains("Irresponsible User Sample"))
        XCTAssertTrue(irresponsibleJSON.contains("export_info"))
        XCTAssertTrue(irresponsibleJSON.contains("messages"))
    }
    
    func testLoadExpectedResults() {
        let responsibleResult = presetManager.loadExpectedResult(type: .responsibleUser)
        let irresponsibleResult = presetManager.loadExpectedResult(type: .irresponsibleUser)
        
        // Validate responsible user expectations
        XCTAssertGreaterThan(responsibleResult.trustworthinessScore.score, 0.8)
        XCTAssertGreaterThan(responsibleResult.personalityTraits.conscientiousness, 0.7)
        XCTAssertLessThan(responsibleResult.personalityTraits.neuroticism, 0.3)
        
        // Validate irresponsible user expectations
        XCTAssertLessThan(irresponsibleResult.trustworthinessScore.score, 0.3)
        XCTAssertLessThan(irresponsibleResult.personalityTraits.conscientiousness, 0.3)
        XCTAssertGreaterThan(irresponsibleResult.personalityTraits.neuroticism, 0.6)
        
        // Validate score ranges
        validateAnalysisResult(responsibleResult)
        validateAnalysisResult(irresponsibleResult)
    }
    
    // MARK: - Display Format Tests
    
    func testMessagesToDisplayText() {
        let messages = presetManager.loadPresetMessages(type: .responsibleUser)
        let displayText = presetManager.messagesToDisplayText(messages)
        
        XCTAssertFalse(displayText.isEmpty)
        XCTAssertTrue(displayText.contains("Me:"))
        XCTAssertTrue(displayText.contains("["))
        XCTAssertTrue(displayText.contains("]"))
        
        // Should contain some of the message content
        XCTAssertTrue(displayText.contains("budget"))
    }
    
    // MARK: - File Management Tests
    
    func testCreateTemporaryJSONFile() throws {
        let tempURL = try presetManager.createTemporaryJSONFile(type: .responsibleUser)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))
        XCTAssertEqual(tempURL.pathExtension, "json")
        XCTAssertTrue(tempURL.lastPathComponent.contains("responsible_user_sample"))
        
        let content = try String(contentsOf: tempURL)
        XCTAssertTrue(content.contains("Responsible User Sample"))
        
        // Cleanup
        try FileManager.default.removeItem(at: tempURL)
    }
    
    func testCleanupTemporaryFiles() throws {
        // Create some temporary files
        let tempURL1 = try presetManager.createTemporaryJSONFile(type: .responsibleUser)
        let tempURL2 = try presetManager.createTemporaryJSONFile(type: .irresponsibleUser)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL1.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL2.path))
        
        // Cleanup
        presetManager.cleanupTemporaryFiles()
        
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempURL1.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempURL2.path))
    }
    
    // MARK: - Result Comparison Tests
    
    func testCompareResults() {
        let expectedResponsible = presetManager.loadExpectedResult(type: .responsibleUser)
        
        // Create a slightly different result
        let actualTraits = PersonalityTraits(
            openness: expectedResponsible.personalityTraits.openness + 0.05,
            conscientiousness: expectedResponsible.personalityTraits.conscientiousness - 0.03,
            extraversion: expectedResponsible.personalityTraits.extraversion,
            agreeableness: expectedResponsible.personalityTraits.agreeableness + 0.02,
            neuroticism: expectedResponsible.personalityTraits.neuroticism + 0.01,
            confidence: expectedResponsible.personalityTraits.confidence - 0.04
        )
        
        let actualTrustworthiness = TrustworthinessScore(
            score: expectedResponsible.trustworthinessScore.score - 0.07,
            factors: expectedResponsible.trustworthinessScore.factors,
            explanation: "Test result"
        )
        
        let actualResult = AnalysisResult(
            personalityTraits: actualTraits,
            trustworthinessScore: actualTrustworthiness,
            messageCount: 15,
            processingTime: 2.0
        )
        
        let comparison = presetManager.compareResults(actual: actualResult, expected: expectedResponsible)
        
        XCTAssertEqual(comparison.trustworthinessDifference, 0.07, accuracy: 0.001)
        XCTAssertFalse(comparison.isWithinExpectedRange) // Should be outside range due to 0.07 difference
        XCTAssertGreaterThan(comparison.accuracyPercentage, 85.0) // Should still be reasonably accurate
        XCTAssertTrue(comparison.summary.contains("Analysis accuracy"))
    }
    
    func testCompareResultsWithinRange() {
        let expected = presetManager.loadExpectedResult(type: .responsibleUser)
        
        // Create a result that should be within expected range
        let actualTraits = PersonalityTraits(
            openness: expected.personalityTraits.openness + 0.02,
            conscientiousness: expected.personalityTraits.conscientiousness - 0.01,
            extraversion: expected.personalityTraits.extraversion,
            agreeableness: expected.personalityTraits.agreeableness,
            neuroticism: expected.personalityTraits.neuroticism,
            confidence: expected.personalityTraits.confidence - 0.01
        )
        
        let actualTrustworthiness = TrustworthinessScore(
            score: expected.trustworthinessScore.score - 0.03,
            factors: expected.trustworthinessScore.factors,
            explanation: "Test result"
        )
        
        let actualResult = AnalysisResult(
            personalityTraits: actualTraits,
            trustworthinessScore: actualTrustworthiness,
            messageCount: 15,
            processingTime: 2.0
        )
        
        let comparison = presetManager.compareResults(actual: actualResult, expected: expected)
        
        XCTAssertTrue(comparison.isWithinExpectedRange)
        XCTAssertGreaterThan(comparison.accuracyPercentage, 95.0)
        XCTAssertTrue(comparison.summary.contains("✅"))
    }
    
    // MARK: - Helper Methods
    
    private func validateAnalysisResult(_ result: AnalysisResult) {
        // Validate personality trait ranges
        let traits = result.personalityTraits
        XCTAssertGreaterThanOrEqual(traits.openness, 0.0)
        XCTAssertLessThanOrEqual(traits.openness, 1.0)
        XCTAssertGreaterThanOrEqual(traits.conscientiousness, 0.0)
        XCTAssertLessThanOrEqual(traits.conscientiousness, 1.0)
        XCTAssertGreaterThanOrEqual(traits.extraversion, 0.0)
        XCTAssertLessThanOrEqual(traits.extraversion, 1.0)
        XCTAssertGreaterThanOrEqual(traits.agreeableness, 0.0)
        XCTAssertLessThanOrEqual(traits.agreeableness, 1.0)
        XCTAssertGreaterThanOrEqual(traits.neuroticism, 0.0)
        XCTAssertLessThanOrEqual(traits.neuroticism, 1.0)
        XCTAssertGreaterThanOrEqual(traits.confidence, 0.0)
        XCTAssertLessThanOrEqual(traits.confidence, 1.0)
        
        // Validate trustworthiness score
        XCTAssertGreaterThanOrEqual(result.trustworthinessScore.score, 0.0)
        XCTAssertLessThanOrEqual(result.trustworthinessScore.score, 1.0)
        
        // Validate metadata
        XCTAssertGreaterThan(result.messageCount, 0)
        XCTAssertGreaterThan(result.processingTime, 0.0)
        XCTAssertFalse(result.trustworthinessScore.explanation.isEmpty)
    }
}