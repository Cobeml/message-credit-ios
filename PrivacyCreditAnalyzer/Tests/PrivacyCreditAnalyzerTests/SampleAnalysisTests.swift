import XCTest
@testable import PrivacyCreditAnalyzer

final class SampleAnalysisTests: XCTestCase {
    
    var analysisRunner: SampleAnalysisRunner!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        analysisRunner = SampleAnalysisRunner()
    }
    
    override func tearDownWithError() throws {
        analysisRunner = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Sample Data Tests
    
    func testSampleDataGeneration() {
        let responsibleMessages = SampleDataGenerator.generateResponsibleUserMessages()
        let irresponsibleMessages = SampleDataGenerator.generateIrresponsibleUserMessages()
        
        XCTAssertEqual(responsibleMessages.count, 15)
        XCTAssertEqual(irresponsibleMessages.count, 15)
        
        // Verify responsible messages contain positive indicators
        let responsibleContent = responsibleMessages.map { $0.content }.joined().lowercased()
        XCTAssertTrue(responsibleContent.contains("budget"))
        XCTAssertTrue(responsibleContent.contains("save"))
        XCTAssertTrue(responsibleContent.contains("plan"))
        
        // Verify irresponsible messages contain negative indicators  
        let irresponsibleContent = irresponsibleMessages.map { $0.content }.joined().lowercased()
        XCTAssertTrue(irresponsibleContent.contains("overdraft"))
        XCTAssertTrue(irresponsibleContent.contains("maxed out"))
        XCTAssertTrue(irresponsibleContent.contains("broke"))
    }
    
    func testJSONExport() {
        let responsibleJSON = SampleDataGenerator.responsibleUserJSON()
        let irresponsibleJSON = SampleDataGenerator.irresponsibleUserJSON()
        
        // Verify JSON structure
        XCTAssertTrue(responsibleJSON.contains("export_info"))
        XCTAssertTrue(responsibleJSON.contains("messages"))
        XCTAssertTrue(responsibleJSON.contains("Responsible User Sample"))
        
        XCTAssertTrue(irresponsibleJSON.contains("export_info"))
        XCTAssertTrue(irresponsibleJSON.contains("messages"))
        XCTAssertTrue(irresponsibleJSON.contains("Irresponsible User Sample"))
    }
    
    func testRunSampleAnalysis() async throws {
        // Run the complete sample analysis
        let results = try await analysisRunner.runSampleAnalysis()
        
        // Verify both results were generated
        XCTAssertNotNil(results.responsible)
        XCTAssertNotNil(results.irresponsible)
        
        // Verify responsible user has better scores
        XCTAssertGreaterThan(results.responsible.trustworthinessScore.score, 
                           results.irresponsible.trustworthinessScore.score)
        
        XCTAssertGreaterThan(results.responsible.personalityTraits.conscientiousness,
                           results.irresponsible.personalityTraits.conscientiousness)
        
        XCTAssertLessThan(results.responsible.personalityTraits.neuroticism,
                         results.irresponsible.personalityTraits.neuroticism)
        
        // Verify results are stored
        let storedResults = SampleDataGenerator.getStoredResults()
        XCTAssertNotNil(storedResults.responsible)
        XCTAssertNotNil(storedResults.irresponsible)
    }
    
    func testGenerateSampleFiles() throws {
        try analysisRunner.generateSampleJSONFiles()
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let responsibleURL = documentsPath.appendingPathComponent("responsible_user_sample.json")
        let irresponsibleURL = documentsPath.appendingPathComponent("irresponsible_user_sample.json")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: responsibleURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: irresponsibleURL.path))
    }
    
    // MARK: - Sample Result Validation
    
    func testExpectedResults() {
        let responsibleResult = SampleDataGenerator.expectedResponsibleResult()
        let irresponsibleResult = SampleDataGenerator.expectedIrresponsibleResult()
        
        // Validate responsible user expectations
        XCTAssertGreaterThan(responsibleResult.personalityTraits.conscientiousness, 0.8)
        XCTAssertGreaterThan(responsibleResult.trustworthinessScore.score, 0.8)
        XCTAssertLessThan(responsibleResult.personalityTraits.neuroticism, 0.3)
        
        // Validate irresponsible user expectations
        XCTAssertLessThan(irresponsibleResult.personalityTraits.conscientiousness, 0.3)
        XCTAssertLessThan(irresponsibleResult.trustworthinessScore.score, 0.3)
        XCTAssertGreaterThan(irresponsibleResult.personalityTraits.neuroticism, 0.7)
        
        // Validate score ranges
        validatePersonalityTraits(responsibleResult.personalityTraits)
        validatePersonalityTraits(irresponsibleResult.personalityTraits)
        validateTrustworthinessScore(responsibleResult.trustworthinessScore)
        validateTrustworthinessScore(irresponsibleResult.trustworthinessScore)
    }
    
    private func validatePersonalityTraits(_ traits: PersonalityTraits) {
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
    }
    
    private func validateTrustworthinessScore(_ score: TrustworthinessScore) {
        XCTAssertGreaterThanOrEqual(score.score, 0.0)
        XCTAssertLessThanOrEqual(score.score, 1.0)
        
        for (_, factorScore) in score.factors {
            XCTAssertGreaterThanOrEqual(factorScore, 0.0)
            XCTAssertLessThanOrEqual(factorScore, 1.0)
        }
        
        XCTAssertFalse(score.explanation.isEmpty)
    }
}