import XCTest
@testable import PrivacyCreditAnalyzer

final class DataModelTests: XCTestCase {
    
    // MARK: - Message Tests
    
    func testMessageInitialization() {
        let message = Message(
            content: "Hello, how are you?",
            timestamp: Date(),
            sender: "John Doe",
            recipient: "Jane Smith",
            isFromUser: true
        )
        
        XCTAssertFalse(message.id.uuidString.isEmpty)
        XCTAssertEqual(message.content, "Hello, how are you?")
        XCTAssertEqual(message.sender, "John Doe")
        XCTAssertEqual(message.recipient, "Jane Smith")
        XCTAssertTrue(message.isFromUser)
    }
    
    func testMessageValidation() {
        let validMessage = Message(
            content: "Valid content",
            timestamp: Date(),
            sender: "John",
            recipient: "Jane",
            isFromUser: true
        )
        XCTAssertTrue(validMessage.isValid())
        
        let emptyContentMessage = Message(
            content: "",
            timestamp: Date(),
            sender: "John",
            recipient: "Jane",
            isFromUser: true
        )
        XCTAssertFalse(emptyContentMessage.isValid())
        
        let emptySenderMessage = Message(
            content: "Content",
            timestamp: Date(),
            sender: "",
            recipient: "Jane",
            isFromUser: true
        )
        XCTAssertFalse(emptySenderMessage.isValid())
    }
    
    func testMessageSanitization() {
        let message = Message(
            content: "  Hello World  \n",
            timestamp: Date(),
            sender: "John",
            recipient: "Jane",
            isFromUser: true
        )
        
        XCTAssertEqual(message.sanitizedContent(), "Hello World")
    }
    
    func testMessageCodable() throws {
        let originalMessage = Message(
            content: "Test message",
            timestamp: Date(),
            sender: "John",
            recipient: "Jane",
            isFromUser: true
        )
        
        let encoded = try JSONEncoder().encode(originalMessage)
        let decoded = try JSONDecoder().decode(Message.self, from: encoded)
        
        XCTAssertEqual(originalMessage, decoded)
    }
    
    // MARK: - PersonalityTraits Tests
    
    func testPersonalityTraitsInitialization() {
        let traits = PersonalityTraits(
            openness: 0.8,
            conscientiousness: 0.7,
            extraversion: 0.6,
            agreeableness: 0.9,
            neuroticism: 0.3,
            confidence: 0.85
        )
        
        XCTAssertEqual(traits.openness, 0.8, accuracy: 0.001)
        XCTAssertEqual(traits.conscientiousness, 0.7, accuracy: 0.001)
        XCTAssertEqual(traits.extraversion, 0.6, accuracy: 0.001)
        XCTAssertEqual(traits.agreeableness, 0.9, accuracy: 0.001)
        XCTAssertEqual(traits.neuroticism, 0.3, accuracy: 0.001)
        XCTAssertEqual(traits.confidence, 0.85, accuracy: 0.001)
    }
    
    func testPersonalityTraitsRangeClamping() {
        let traits = PersonalityTraits(
            openness: 1.5,  // Should be clamped to 1.0
            conscientiousness: -0.2,  // Should be clamped to 0.0
            extraversion: 0.5,
            agreeableness: 2.0,  // Should be clamped to 1.0
            neuroticism: -1.0,  // Should be clamped to 0.0
            confidence: 0.75
        )
        
        XCTAssertEqual(traits.openness, 1.0)
        XCTAssertEqual(traits.conscientiousness, 0.0)
        XCTAssertEqual(traits.agreeableness, 1.0)
        XCTAssertEqual(traits.neuroticism, 0.0)
    }
    
    func testPersonalityTraitsValidation() {
        let validTraits = PersonalityTraits(
            openness: 0.5,
            conscientiousness: 0.6,
            extraversion: 0.7,
            agreeableness: 0.8,
            neuroticism: 0.4,
            confidence: 0.9
        )
        XCTAssertTrue(validTraits.isValid())
    }
    
    func testPersonalityTraitsAverageScore() {
        let traits = PersonalityTraits(
            openness: 0.8,
            conscientiousness: 0.6,
            extraversion: 0.4,
            agreeableness: 1.0,
            neuroticism: 0.2,
            confidence: 0.7
        )
        
        let expectedAverage = (0.8 + 0.6 + 0.4 + 1.0 + 0.2) / 5.0
        XCTAssertEqual(traits.averageScore(), expectedAverage, accuracy: 0.001)
    }
    
    func testPersonalityTraitsToDictionary() {
        let traits = PersonalityTraits(
            openness: 0.8,
            conscientiousness: 0.7,
            extraversion: 0.6,
            agreeableness: 0.9,
            neuroticism: 0.3,
            confidence: 0.85
        )
        
        let dict = traits.toDictionary()
        XCTAssertEqual(dict["openness"], 0.8)
        XCTAssertEqual(dict["conscientiousness"], 0.7)
        XCTAssertEqual(dict["extraversion"], 0.6)
        XCTAssertEqual(dict["agreeableness"], 0.9)
        XCTAssertEqual(dict["neuroticism"], 0.3)
        XCTAssertEqual(dict["confidence"], 0.85)
    }
    
    // MARK: - TrustworthinessScore Tests
    
    func testTrustworthinessScoreInitialization() {
        let factors = ["financial_responsibility": 0.8, "communication_style": 0.7]
        let score = TrustworthinessScore(
            score: 0.75,
            factors: factors,
            explanation: "High trustworthiness based on consistent financial behavior"
        )
        
        XCTAssertEqual(score.score, 0.75, accuracy: 0.001)
        XCTAssertEqual(score.factors.count, 2)
        XCTAssertEqual(score.explanation, "High trustworthiness based on consistent financial behavior")
    }
    
    func testTrustworthinessScoreRangeClamping() {
        let factors = ["factor1": 1.5, "factor2": -0.2]  // Should be clamped
        let score = TrustworthinessScore(
            score: 1.2,  // Should be clamped to 1.0
            factors: factors,
            explanation: "Test explanation"
        )
        
        XCTAssertEqual(score.score, 1.0)
        XCTAssertEqual(score.factors["factor1"], 1.0)
        XCTAssertEqual(score.factors["factor2"], 0.0)
    }
    
    func testTrustworthinessScoreValidation() {
        let validScore = TrustworthinessScore(
            score: 0.8,
            factors: ["factor1": 0.7, "factor2": 0.9],
            explanation: "Valid explanation"
        )
        XCTAssertTrue(validScore.isValid())
        
        let invalidScore = TrustworthinessScore(
            score: 0.8,
            factors: ["factor1": 0.7],
            explanation: ""  // Empty explanation
        )
        XCTAssertFalse(invalidScore.isValid())
    }
    
    func testTrustworthinessScoreWeightedScore() {
        let factors = ["factor1": 0.8, "factor2": 0.6, "factor3": 1.0]
        let score = TrustworthinessScore(
            score: 0.75,
            factors: factors,
            explanation: "Test"
        )
        
        let expectedWeighted = (0.8 + 0.6 + 1.0) / 3.0
        XCTAssertEqual(score.calculateWeightedScore(), expectedWeighted, accuracy: 0.001)
    }
    
    func testTrustworthinessScorePrimaryFactor() {
        let factors = ["low_factor": 0.3, "high_factor": 0.9, "medium_factor": 0.6]
        let score = TrustworthinessScore(
            score: 0.6,
            factors: factors,
            explanation: "Test"
        )
        
        let primaryFactor = score.primaryFactor()
        XCTAssertNotNil(primaryFactor)
        XCTAssertEqual(primaryFactor?.key, "high_factor")
        XCTAssertEqual(primaryFactor?.value, 0.9)
    }
    
    // MARK: - AnalysisResult Tests
    
    func testAnalysisResultInitialization() {
        let traits = PersonalityTraits(
            openness: 0.8, conscientiousness: 0.7, extraversion: 0.6,
            agreeableness: 0.9, neuroticism: 0.3, confidence: 0.85
        )
        let trustScore = TrustworthinessScore(
            score: 0.75,
            factors: ["factor1": 0.8],
            explanation: "Test explanation"
        )
        
        let result = AnalysisResult(
            personalityTraits: traits,
            trustworthinessScore: trustScore,
            messageCount: 100,
            processingTime: 5.5
        )
        
        XCTAssertFalse(result.id.uuidString.isEmpty)
        XCTAssertEqual(result.messageCount, 100)
        XCTAssertEqual(result.processingTime, 5.5, accuracy: 0.001)
    }
    
    func testAnalysisResultValidation() {
        let validTraits = PersonalityTraits(
            openness: 0.8, conscientiousness: 0.7, extraversion: 0.6,
            agreeableness: 0.9, neuroticism: 0.3, confidence: 0.85
        )
        let validTrustScore = TrustworthinessScore(
            score: 0.75,
            factors: ["factor1": 0.8],
            explanation: "Valid explanation"
        )
        
        let validResult = AnalysisResult(
            personalityTraits: validTraits,
            trustworthinessScore: validTrustScore,
            messageCount: 100,
            processingTime: 5.5
        )
        XCTAssertTrue(validResult.isValid())
        
        let invalidResult = AnalysisResult(
            personalityTraits: validTraits,
            trustworthinessScore: validTrustScore,
            messageCount: -1,  // Invalid negative count
            processingTime: 5.5
        )
        XCTAssertFalse(invalidResult.isValid())
    }
    
    func testAnalysisResultSummary() {
        let traits = PersonalityTraits(
            openness: 0.8, conscientiousness: 0.7, extraversion: 0.6,
            agreeableness: 0.9, neuroticism: 0.3, confidence: 0.85
        )
        let trustScore = TrustworthinessScore(
            score: 0.75,
            factors: ["factor1": 0.8],
            explanation: "Test explanation"
        )
        
        let result = AnalysisResult(
            personalityTraits: traits,
            trustworthinessScore: trustScore,
            messageCount: 100,
            processingTime: 5.5
        )
        
        let summary = result.summary()
        XCTAssertTrue(summary.contains("100"))  // Message count
        XCTAssertTrue(summary.contains("5.50"))  // Processing time
        XCTAssertTrue(summary.contains("0.75"))  // Trust score
        // Check for average personality score (0.8+0.7+0.6+0.9+0.3)/5 = 0.66
        XCTAssertTrue(summary.contains("0.66"))
    }
    
    func testAnalysisResultDictionaryConversion() throws {
        let traits = PersonalityTraits(
            openness: 0.8, conscientiousness: 0.7, extraversion: 0.6,
            agreeableness: 0.9, neuroticism: 0.3, confidence: 0.85
        )
        let trustScore = TrustworthinessScore(
            score: 0.75,
            factors: ["factor1": 0.8],
            explanation: "Test explanation"
        )
        
        let fixedDate = Date(timeIntervalSince1970: 1692806400) // Fixed timestamp
        let originalResult = AnalysisResult(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789012")!,
            timestamp: fixedDate,
            personalityTraits: traits,
            trustworthinessScore: trustScore,
            messageCount: 100,
            processingTime: 5.5
        )
        
        let dict = originalResult.toDictionary()
        let reconstructedResult = try AnalysisResult.fromDictionary(dict)
        
        // Compare individual fields instead of the whole struct due to potential timestamp precision issues
        XCTAssertEqual(originalResult.id, reconstructedResult.id)
        XCTAssertEqual(originalResult.personalityTraits, reconstructedResult.personalityTraits)
        XCTAssertEqual(originalResult.trustworthinessScore, reconstructedResult.trustworthinessScore)
        XCTAssertEqual(originalResult.messageCount, reconstructedResult.messageCount)
        XCTAssertEqual(originalResult.processingTime, reconstructedResult.processingTime, accuracy: 0.001)
        XCTAssertEqual(originalResult.timestamp.timeIntervalSince1970, reconstructedResult.timestamp.timeIntervalSince1970, accuracy: 0.001)
    }
    
    // MARK: - SignedResult Tests
    
    func testSignedResultInitialization() {
        let traits = PersonalityTraits(
            openness: 0.8, conscientiousness: 0.7, extraversion: 0.6,
            agreeableness: 0.9, neuroticism: 0.3, confidence: 0.85
        )
        let trustScore = TrustworthinessScore(
            score: 0.75,
            factors: ["factor1": 0.8],
            explanation: "Test explanation"
        )
        let analysisResult = AnalysisResult(
            personalityTraits: traits,
            trustworthinessScore: trustScore,
            messageCount: 100,
            processingTime: 5.5
        )
        
        let signedResult = SignedResult(
            result: analysisResult,
            signature: "test_signature_123",
            publicKey: "test_public_key_456",
            inputHash: "test_input_hash_789",
            modelHash: "test_model_hash_abc"
        )
        
        XCTAssertEqual(signedResult.id, analysisResult.id)
        XCTAssertEqual(signedResult.signature, "test_signature_123")
        XCTAssertEqual(signedResult.publicKey, "test_public_key_456")
        XCTAssertEqual(signedResult.inputHash, "test_input_hash_789")
        XCTAssertEqual(signedResult.modelHash, "test_model_hash_abc")
    }
    
    func testSignedResultValidation() {
        let validTraits = PersonalityTraits(
            openness: 0.8, conscientiousness: 0.7, extraversion: 0.6,
            agreeableness: 0.9, neuroticism: 0.3, confidence: 0.85
        )
        let validTrustScore = TrustworthinessScore(
            score: 0.75,
            factors: ["factor1": 0.8],
            explanation: "Valid explanation"
        )
        let validAnalysisResult = AnalysisResult(
            personalityTraits: validTraits,
            trustworthinessScore: validTrustScore,
            messageCount: 100,
            processingTime: 5.5
        )
        
        let validSignedResult = SignedResult(
            result: validAnalysisResult,
            signature: "valid_signature",
            publicKey: "valid_public_key",
            inputHash: "valid_input_hash",
            modelHash: "valid_model_hash"
        )
        XCTAssertTrue(validSignedResult.isValid())
        
        let invalidSignedResult = SignedResult(
            result: validAnalysisResult,
            signature: "",  // Empty signature
            publicKey: "valid_public_key",
            inputHash: "valid_input_hash",
            modelHash: "valid_model_hash"
        )
        XCTAssertFalse(invalidSignedResult.isValid())
    }
    
    func testSignedResultJSONSerialization() throws {
        let traits = PersonalityTraits(
            openness: 0.8, conscientiousness: 0.7, extraversion: 0.6,
            agreeableness: 0.9, neuroticism: 0.3, confidence: 0.85
        )
        let trustScore = TrustworthinessScore(
            score: 0.75,
            factors: ["factor1": 0.8],
            explanation: "Test explanation"
        )
        let analysisResult = AnalysisResult(
            personalityTraits: traits,
            trustworthinessScore: trustScore,
            messageCount: 100,
            processingTime: 5.5
        )
        
        let originalSignedResult = SignedResult(
            result: analysisResult,
            signature: "test_signature",
            publicKey: "test_public_key",
            inputHash: "test_input_hash",
            modelHash: "test_model_hash"
        )
        
        let jsonData = try originalSignedResult.toJSONData()
        let reconstructedSignedResult = try SignedResult.fromJSONData(jsonData)
        
        XCTAssertEqual(originalSignedResult, reconstructedSignedResult)
    }
    
    func testSignedResultDictionaryConversion() throws {
        let traits = PersonalityTraits(
            openness: 0.8, conscientiousness: 0.7, extraversion: 0.6,
            agreeableness: 0.9, neuroticism: 0.3, confidence: 0.85
        )
        let trustScore = TrustworthinessScore(
            score: 0.75,
            factors: ["factor1": 0.8],
            explanation: "Test explanation"
        )
        
        let fixedDate = Date(timeIntervalSince1970: 1692806400) // Fixed timestamp
        let analysisResult = AnalysisResult(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789012")!,
            timestamp: fixedDate,
            personalityTraits: traits,
            trustworthinessScore: trustScore,
            messageCount: 100,
            processingTime: 5.5
        )
        
        let originalSignedResult = SignedResult(
            result: analysisResult,
            signature: "test_signature",
            publicKey: "test_public_key",
            inputHash: "test_input_hash",
            modelHash: "test_model_hash"
        )
        
        let dict = originalSignedResult.toDictionary()
        let reconstructedSignedResult = try SignedResult.fromDictionary(dict)
        
        // Compare individual fields instead of the whole struct due to potential timestamp precision issues
        XCTAssertEqual(originalSignedResult.signature, reconstructedSignedResult.signature)
        XCTAssertEqual(originalSignedResult.publicKey, reconstructedSignedResult.publicKey)
        XCTAssertEqual(originalSignedResult.inputHash, reconstructedSignedResult.inputHash)
        XCTAssertEqual(originalSignedResult.modelHash, reconstructedSignedResult.modelHash)
        XCTAssertEqual(originalSignedResult.result.id, reconstructedSignedResult.result.id)
        XCTAssertEqual(originalSignedResult.result.messageCount, reconstructedSignedResult.result.messageCount)
        XCTAssertEqual(originalSignedResult.result.processingTime, reconstructedSignedResult.result.processingTime, accuracy: 0.001)
    }
}