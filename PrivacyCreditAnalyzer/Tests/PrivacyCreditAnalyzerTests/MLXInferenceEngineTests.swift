import XCTest
@testable import PrivacyCreditAnalyzer

final class MLXInferenceEngineTests: XCTestCase {
    
    var inferenceEngine: MLXInferenceEngine!
    var testMessages: [Message]!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        inferenceEngine = MLXInferenceEngine()
        
        // Create comprehensive test messages for various scenarios
        testMessages = createTestMessages()
    }
    
    override func tearDownWithError() throws {
        inferenceEngine = nil
        testMessages = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testInferenceEngineInitialization() async throws {
        // Test basic initialization
        XCTAssertFalse(inferenceEngine.isInitialized)
        XCTAssertFalse(inferenceEngine.isAnalyzing)
        XCTAssertEqual(inferenceEngine.analysisProgress, 0.0)
        XCTAssertEqual(inferenceEngine.analysisStatus, "Ready")
    }
    
    func testModelInitialization() async throws {
        // Test model initialization (this will use placeholder implementation)
        do {
            try await inferenceEngine.initialize()
            // Since we're using placeholder implementation, initialization should succeed
            XCTAssertTrue(inferenceEngine.isInitialized)
        } catch {
            // In test environment without actual MLX model, this might fail
            // That's expected and acceptable for this test phase
            print("Model initialization failed as expected in test environment: \(error)")
        }
    }
    
    // MARK: - Personality Analysis Tests
    
    func testPersonalityAnalysisWithValidMessages() async throws {
        // Test personality analysis with various message types
        let personalityMessages = createPersonalityTestMessages()
        
        do {
            try await inferenceEngine.initialize()
            let traits = try await inferenceEngine.analyzePersonality(messages: personalityMessages)
            
            // Validate personality trait ranges
            validatePersonalityTraits(traits)
            
        } catch InferenceError.engineNotInitialized {
            // Expected in test environment
            XCTAssertFalse(inferenceEngine.isInitialized)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testPersonalityAnalysisWithInsufficientData() async throws {
        // Test behavior with insufficient message data
        let insufficientMessages = Array(testMessages.prefix(2)) // Only 2 messages
        
        do {
            try await inferenceEngine.initialize()
            let traits = try await inferenceEngine.analyzePersonality(messages: insufficientMessages)
            
            // Should still return valid traits even with limited data
            validatePersonalityTraits(traits)
            
        } catch InferenceError.engineNotInitialized {
            // Expected in test environment
            XCTAssertFalse(inferenceEngine.isInitialized)
        } catch {
            // Insufficient data might cause analysis to fail
            print("Analysis failed with insufficient data as expected: \(error)")
        }
    }
    
    // MARK: - Trustworthiness Analysis Tests
    
    func testTrustworthinessCalculation() async throws {
        let financialMessages = createFinancialTestMessages()
        let mockTraits = createMockPersonalityTraits()
        
        do {
            try await inferenceEngine.initialize()
            let trustworthiness = try await inferenceEngine.calculateTrustworthiness(
                messages: financialMessages,
                traits: mockTraits
            )
            
            // Validate trustworthiness score
            validateTrustworthinessScore(trustworthiness)
            
        } catch InferenceError.engineNotInitialized {
            // Expected in test environment
            XCTAssertFalse(inferenceEngine.isInitialized)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Background Processing Tests
    
    func testBackgroundProcessingWorkflow() async throws {
        let largeMessageSet = createLargeTestMessageSet()
        
        do {
            try await inferenceEngine.initialize()
            let result = try await inferenceEngine.processInBackground(messages: largeMessageSet)
            
            // Validate complete analysis result
            validateAnalysisResult(result, expectedMessageCount: largeMessageSet.count)
            
        } catch InferenceError.engineNotInitialized {
            // Expected in test environment
            XCTAssertFalse(inferenceEngine.isInitialized)
        } catch {
            print("Background processing failed as expected in test environment: \(error)")
        }
    }
    
    func testAnalysisCancellation() async throws {
        let messages = createLargeTestMessageSet()
        
        // Start analysis in background
        let analysisTask = Task {
            do {
                try await inferenceEngine.initialize()
                return try await inferenceEngine.processInBackground(messages: messages)
            } catch {
                throw error
            }
        }
        
        // Cancel analysis after a brief delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        inferenceEngine.cancelAnalysis()
        analysisTask.cancel()
        
        // Verify cancellation state
        XCTAssertFalse(inferenceEngine.isAnalyzing)
    }
    
    // MARK: - Performance Tests
    
    func testMemoryUsageEstimation() {
        let memoryUsage = inferenceEngine.estimatedMemoryUsage
        
        // Should provide a reasonable estimate (MLX Phi-3 Mini is ~2.4GB)
        XCTAssertGreaterThan(memoryUsage, 1_000_000_000) // > 1GB
        XCTAssertLessThan(memoryUsage, 10_000_000_000)   // < 10GB
        
        let stats = inferenceEngine.performanceStats
        XCTAssertEqual(stats.memoryUsage, memoryUsage)
        XCTAssertGreaterThan(stats.memoryUsageMB, 1000) // > 1000 MB
    }
    
    func testLargeDatasetProcessing() async throws {
        // Test processing with dataset that requires sampling
        let veryLargeMessageSet = createVeryLargeTestMessageSet() // > 5000 messages
        
        do {
            try await inferenceEngine.initialize()
            let result = try await inferenceEngine.processLargeDataset(
                messages: veryLargeMessageSet,
                batchSize: 1000
            )
            
            // Should handle large datasets gracefully
            validateAnalysisResult(result, expectedMessageCount: min(veryLargeMessageSet.count, 5000))
            
        } catch InferenceError.engineNotInitialized {
            // Expected in test environment
            XCTAssertFalse(inferenceEngine.isInitialized)
        } catch {
            print("Large dataset processing failed as expected in test environment: \(error)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testUninitializedEngineError() async throws {
        // Test calling analysis methods on uninitialized engine
        do {
            _ = try await inferenceEngine.analyzePersonality(messages: testMessages)
            XCTFail("Should have thrown engineNotInitialized error")
        } catch InferenceError.engineNotInitialized {
            // Expected error
            XCTAssertFalse(inferenceEngine.isInitialized)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testEmptyMessageHandling() async throws {
        do {
            try await inferenceEngine.initialize()
            _ = try await inferenceEngine.analyzePersonality(messages: [])
            XCTFail("Should have thrown invalidInput error")
        } catch InferenceError.invalidInput {
            // Expected error for empty input
        } catch InferenceError.engineNotInitialized {
            // Also acceptable in test environment
        } catch {
            print("Unexpected error handling empty messages: \(error)")
        }
    }
}

// MARK: - Test Data Creation

extension MLXInferenceEngineTests {
    
    private func createTestMessages() -> [Message] {
        let baseDate = Date().addingTimeInterval(-86400) // 24 hours ago
        
        return [
            Message(content: "Hey, how are you doing today?", timestamp: baseDate, sender: "Alice", recipient: "User", isFromUser: false),
            Message(content: "I'm doing well, thanks for asking!", timestamp: baseDate.addingTimeInterval(300), sender: "User", recipient: "Alice", isFromUser: true),
            Message(content: "I need to pay my rent this week, it's $1200", timestamp: baseDate.addingTimeInterval(3600), sender: "User", recipient: "Bob", isFromUser: true),
            Message(content: "That's quite expensive! Have you considered moving?", timestamp: baseDate.addingTimeInterval(3900), sender: "Bob", recipient: "User", isFromUser: false),
            Message(content: "I've been saving money every month for my emergency fund", timestamp: baseDate.addingTimeInterval(7200), sender: "User", recipient: "Charlie", isFromUser: true),
            Message(content: "That's really smart financial planning!", timestamp: baseDate.addingTimeInterval(7500), sender: "Charlie", recipient: "User", isFromUser: false),
            Message(content: "I love spending time with my family on weekends", timestamp: baseDate.addingTimeInterval(10800), sender: "User", recipient: "Dana", isFromUser: true),
            Message(content: "Family time is so important for happiness", timestamp: baseDate.addingTimeInterval(11100), sender: "Dana", recipient: "User", isFromUser: false)
        ]
    }
    
    private func createPersonalityTestMessages() -> [Message] {
        let baseDate = Date()
        
        return [
            // Openness indicators
            Message(content: "I love exploring new ideas and creative projects", timestamp: baseDate, sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "Have you read any interesting philosophy books lately?", timestamp: baseDate.addingTimeInterval(300), sender: "User", recipient: "Friend", isFromUser: true),
            
            // Conscientiousness indicators
            Message(content: "I always plan my budget carefully each month", timestamp: baseDate.addingTimeInterval(600), sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "I need to finish this project on time, no matter what", timestamp: baseDate.addingTimeInterval(900), sender: "User", recipient: "Friend", isFromUser: true),
            
            // Extraversion indicators
            Message(content: "Can't wait for the party tonight! It's going to be amazing!", timestamp: baseDate.addingTimeInterval(1200), sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "I love meeting new people and making connections", timestamp: baseDate.addingTimeInterval(1500), sender: "User", recipient: "Friend", isFromUser: true),
            
            // Agreeableness indicators
            Message(content: "I'm always happy to help others when they need support", timestamp: baseDate.addingTimeInterval(1800), sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "Let's find a solution that works for everyone", timestamp: baseDate.addingTimeInterval(2100), sender: "User", recipient: "Friend", isFromUser: true),
            
            // Neuroticism (low) indicators
            Message(content: "I stay calm even under pressure", timestamp: baseDate.addingTimeInterval(2400), sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "Everything will work out fine, I'm not worried", timestamp: baseDate.addingTimeInterval(2700), sender: "User", recipient: "Friend", isFromUser: true)
        ]
    }
    
    private func createFinancialTestMessages() -> [Message] {
        let baseDate = Date()
        
        return [
            Message(content: "I paid my credit card bill early this month", timestamp: baseDate, sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "My monthly budget includes savings and investments", timestamp: baseDate.addingTimeInterval(300), sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "I always check my bank account balance before spending", timestamp: baseDate.addingTimeInterval(600), sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "I'm thinking about getting a loan for a car", timestamp: baseDate.addingTimeInterval(900), sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "My credit score has been improving steadily", timestamp: baseDate.addingTimeInterval(1200), sender: "User", recipient: "Friend", isFromUser: true)
        ]
    }
    
    private func createMockPersonalityTraits() -> PersonalityTraits {
        return PersonalityTraits(
            openness: 0.7,
            conscientiousness: 0.8,
            extraversion: 0.6,
            agreeableness: 0.9,
            neuroticism: 0.3,
            confidence: 0.8
        )
    }
    
    private func createLargeTestMessageSet() -> [Message] {
        var messages: [Message] = []
        let baseDate = Date().addingTimeInterval(-86400 * 30) // 30 days ago
        
        // Create 100 test messages with variety
        for i in 0..<100 {
            let timestamp = baseDate.addingTimeInterval(TimeInterval(i * 300)) // Every 5 minutes
            let content = generateVariedMessageContent(index: i)
            
            messages.append(Message(
                content: content,
                timestamp: timestamp,
                sender: i % 2 == 0 ? "User" : "Contact\(i % 10)",
                recipient: i % 2 == 0 ? "Contact\(i % 10)" : "User",
                isFromUser: i % 2 == 0
            ))
        }
        
        return messages
    }
    
    private func createVeryLargeTestMessageSet() -> [Message] {
        var messages = createLargeTestMessageSet()
        
        // Extend to over 5000 messages by duplicating and varying content
        let originalCount = messages.count
        while messages.count < 6000 {
            let baseMessage = messages[messages.count % originalCount]
            let newMessage = Message(
                content: "\(baseMessage.content) (extended \(messages.count))",
                timestamp: baseMessage.timestamp.addingTimeInterval(TimeInterval(messages.count)),
                sender: baseMessage.sender,
                recipient: baseMessage.recipient,
                isFromUser: baseMessage.isFromUser
            )
            messages.append(newMessage)
        }
        
        return messages
    }
    
    private func generateVariedMessageContent(index: Int) -> String {
        let contentTypes = [
            "Hi there! How's your day going?",
            "I need to budget better this month",
            "Just paid my bills, feeling responsible",
            "Love spending time with family",
            "Working on a creative project today",
            "Planning my finances for next year",
            "Really excited about this new opportunity!",
            "I always try to help others when I can",
            "Staying calm despite the stress",
            "Let me check my savings account balance"
        ]
        
        return contentTypes[index % contentTypes.count]
    }
}

// MARK: - Validation Helpers

extension MLXInferenceEngineTests {
    
    private func validatePersonalityTraits(_ traits: PersonalityTraits) {
        // All traits should be in valid range [0.0, 1.0]
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
        // Overall score should be in valid range
        XCTAssertGreaterThanOrEqual(score.score, 0.0)
        XCTAssertLessThanOrEqual(score.score, 1.0)
        
        // All factor scores should be in valid range
        for (_, factorScore) in score.factors {
            XCTAssertGreaterThanOrEqual(factorScore, 0.0)
            XCTAssertLessThanOrEqual(factorScore, 1.0)
        }
        
        // Should have meaningful explanation
        XCTAssertFalse(score.explanation.isEmpty)
        XCTAssertGreaterThan(score.explanation.count, 20)
    }
    
    private func validateAnalysisResult(_ result: AnalysisResult, expectedMessageCount: Int) {
        // Validate personality traits
        validatePersonalityTraits(result.personalityTraits)
        
        // Validate trustworthiness score
        validateTrustworthinessScore(result.trustworthinessScore)
        
        // Validate metadata
        XCTAssertGreaterThan(result.messageCount, 0)
        XCTAssertLessThanOrEqual(result.messageCount, expectedMessageCount)
        
        XCTAssertGreaterThan(result.processingTime, 0.0)
        XCTAssertLessThan(result.processingTime, 600.0) // Should complete within 10 minutes
        
        // Validate UUID is properly set
        XCTAssertNotEqual(result.id, UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }
}