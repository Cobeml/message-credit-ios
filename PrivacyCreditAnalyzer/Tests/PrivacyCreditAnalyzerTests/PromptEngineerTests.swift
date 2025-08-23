import XCTest
@testable import PrivacyCreditAnalyzer

final class PromptEngineerTests: XCTestCase {
    
    var promptEngineer: PromptEngineer!
    var testMessages: [Message]!
    var testPersonalityTraits: PersonalityTraits!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        promptEngineer = PromptEngineer()
        testMessages = createTestMessages()
        testPersonalityTraits = createTestPersonalityTraits()
    }
    
    override func tearDownWithError() throws {
        promptEngineer = nil
        testMessages = nil
        testPersonalityTraits = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Personality Analysis Prompt Tests
    
    func testPersonalityAnalysisPromptGeneration() {
        let prompt = promptEngineer.createPersonalityAnalysisPrompt(messages: testMessages)
        
        // Verify prompt structure
        XCTAssertTrue(prompt.contains("Big Five"))
        XCTAssertTrue(prompt.contains("OCEAN"))
        XCTAssertTrue(prompt.contains("OPENNESS"))
        XCTAssertTrue(prompt.contains("CONSCIENTIOUSNESS"))
        XCTAssertTrue(prompt.contains("EXTRAVERSION"))
        XCTAssertTrue(prompt.contains("AGREEABLENESS"))
        XCTAssertTrue(prompt.contains("NEUROTICISM"))
        
        // Verify message context is included
        XCTAssertTrue(prompt.contains("MESSAGE CONTEXT:"))
        
        // Verify output format specification
        XCTAssertTrue(prompt.contains("OUTPUT FORMAT"))
        XCTAssertTrue(prompt.contains("JSON"))
        
        // Verify message count is mentioned
        XCTAssertTrue(prompt.contains("\(testMessages.count)"))
    }
    
    func testPersonalityPromptWithVariousMessageCounts() {
        // Test with small message set
        let smallMessages = Array(testMessages.prefix(3))
        let smallPrompt = promptEngineer.createPersonalityAnalysisPrompt(messages: smallMessages)
        XCTAssertTrue(smallPrompt.contains("\(smallMessages.count)"))
        
        // Test with large message set
        let largeMessages = createLargeMessageSet()
        let largePrompt = promptEngineer.createPersonalityAnalysisPrompt(messages: largeMessages)
        XCTAssertTrue(largePrompt.contains("\(largeMessages.count)"))
        
        // Both should have consistent structure
        XCTAssertTrue(smallPrompt.contains("Big Five"))
        XCTAssertTrue(largePrompt.contains("Big Five"))
    }
    
    // MARK: - Trustworthiness Analysis Prompt Tests
    
    func testTrustworthinessPromptGeneration() {
        let prompt = promptEngineer.createTrustworthinessPrompt(
            messages: testMessages,
            personalityTraits: testPersonalityTraits
        )
        
        // Verify trustworthiness analysis structure
        XCTAssertTrue(prompt.contains("trustworthiness"))
        XCTAssertTrue(prompt.contains("creditworthiness"))
        XCTAssertTrue(prompt.contains("COMMUNICATION_STYLE"))
        XCTAssertTrue(prompt.contains("FINANCIAL_RESPONSIBILITY"))
        XCTAssertTrue(prompt.contains("RELATIONSHIP_STABILITY"))
        XCTAssertTrue(prompt.contains("EMOTIONAL_INTELLIGENCE"))
        
        // Verify personality context is included
        XCTAssertTrue(prompt.contains("PERSONALITY CONTEXT:"))
        XCTAssertTrue(prompt.contains("Openness:"))
        XCTAssertTrue(prompt.contains("Conscientiousness:"))
        
        // Verify message context is included
        XCTAssertTrue(prompt.contains("MESSAGE CONTEXT:"))
        
        // Verify output format specification
        XCTAssertTrue(prompt.contains("OUTPUT FORMAT"))
        XCTAssertTrue(prompt.contains("overall_score"))
        XCTAssertTrue(prompt.contains("factors"))
        XCTAssertTrue(prompt.contains("explanation"))
    }
    
    // MARK: - Specialized Prompt Tests
    
    func testFinancialBehaviorPromptGeneration() {
        let financialMessages = createFinancialMessages()
        let prompt = promptEngineer.createFinancialBehaviorPrompt(messages: financialMessages)
        
        // Should focus on financial aspects
        XCTAssertTrue(prompt.contains("financial behavior"))
        XCTAssertTrue(prompt.contains("spending discipline"))
        XCTAssertTrue(prompt.contains("budgeting"))
        XCTAssertTrue(prompt.contains("debt management"))
        XCTAssertTrue(prompt.contains("investment"))
        
        // Should include relevant message context
        XCTAssertTrue(prompt.contains("MESSAGE CONTEXT:"))
    }
    
    func testRelationshipAnalysisPromptGeneration() {
        let relationshipMessages = createRelationshipMessages()
        let prompt = promptEngineer.createRelationshipAnalysisPrompt(messages: relationshipMessages)
        
        // Should focus on relationship aspects
        XCTAssertTrue(prompt.contains("relationship stability"))
        XCTAssertTrue(prompt.contains("social support"))
        XCTAssertTrue(prompt.contains("conflict resolution"))
        XCTAssertTrue(prompt.contains("emotional maturity"))
        XCTAssertTrue(prompt.contains("trust"))
        
        // Should include relevant message context
        XCTAssertTrue(prompt.contains("MESSAGE CONTEXT:"))
    }
    
    // MARK: - Response Parsing Tests
    
    func testPersonalityResponseParsing() {
        let mockResponse = """
        Based on the analysis, here are the personality traits:
        
        {
          "openness": 0.7,
          "conscientiousness": 0.8,
          "extraversion": 0.6,
          "agreeableness": 0.9,
          "neuroticism": 0.3,
          "confidence": 0.85,
          "analysis_notes": "Strong creative tendencies and high reliability"
        }
        
        The analysis shows high conscientiousness and agreeableness.
        """
        
        do {
            let traits = try promptEngineer.parsePersonalityResponse(mockResponse)
            
            XCTAssertEqual(traits.openness, 0.7, accuracy: 0.01)
            XCTAssertEqual(traits.conscientiousness, 0.8, accuracy: 0.01)
            XCTAssertEqual(traits.extraversion, 0.6, accuracy: 0.01)
            XCTAssertEqual(traits.agreeableness, 0.9, accuracy: 0.01)
            XCTAssertEqual(traits.neuroticism, 0.3, accuracy: 0.01)
            XCTAssertEqual(traits.confidence, 0.85, accuracy: 0.01)
            
        } catch {
            XCTFail("Failed to parse valid personality response: \(error)")
        }
    }
    
    func testTrustworthinessResponseParsing() {
        let mockResponse = """
        Analysis of trustworthiness indicators:
        
        {
          "overall_score": 0.75,
          "factors": {
            "communication_style": 0.8,
            "financial_responsibility": 0.7,
            "relationship_stability": 0.9,
            "emotional_intelligence": 0.6
          },
          "explanation": "High relationship stability and good communication patterns indicate strong trustworthiness",
          "risk_indicators": ["occasional impulsive spending"],
          "positive_indicators": ["consistent payment history", "strong family relationships"]
        }
        """
        
        do {
            let trustworthiness = try promptEngineer.parseTrustworthinessResponse(mockResponse)
            
            XCTAssertEqual(trustworthiness.score, 0.75, accuracy: 0.01)
            XCTAssertEqual(trustworthiness.factors["communication_style"] ?? 0.0, 0.8, accuracy: 0.01)
            XCTAssertEqual(trustworthiness.factors["financial_responsibility"] ?? 0.0, 0.7, accuracy: 0.01)
            XCTAssertEqual(trustworthiness.factors["relationship_stability"] ?? 0.0, 0.9, accuracy: 0.01)
            XCTAssertEqual(trustworthiness.factors["emotional_intelligence"] ?? 0.0, 0.6, accuracy: 0.01)
            XCTAssertTrue(trustworthiness.explanation.contains("trustworthiness"))
            
        } catch {
            XCTFail("Failed to parse valid trustworthiness response: \(error)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidPersonalityResponseParsing() {
        let invalidResponses = [
            "No JSON content here",
            "{ invalid json }",
            "{ \"openness\": \"not_a_number\" }",
            "{}"
        ]
        
        for invalidResponse in invalidResponses {
            do {
                _ = try promptEngineer.parsePersonalityResponse(invalidResponse)
                XCTFail("Should have failed parsing invalid response: \(invalidResponse)")
            } catch PromptError.invalidResponse {
                // Expected error
            } catch PromptError.parsingError {
                // Also acceptable
            } catch {
                XCTFail("Unexpected error type for invalid response: \(error)")
            }
        }
    }
    
    func testInvalidTrustworthinessResponseParsing() {
        let invalidResponses = [
            "No JSON content",
            "{ \"overall_score\": \"invalid\" }",
            "{ \"factors\": \"not_an_object\" }"
        ]
        
        for invalidResponse in invalidResponses {
            do {
                _ = try promptEngineer.parseTrustworthinessResponse(invalidResponse)
                XCTFail("Should have failed parsing invalid response: \(invalidResponse)")
            } catch PromptError.invalidResponse {
                // Expected error
            } catch PromptError.parsingError {
                // Also acceptable
            } catch {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }
    
    // MARK: - Prompt Quality Tests
    
    func testPromptLength() {
        let prompt = promptEngineer.createPersonalityAnalysisPrompt(messages: testMessages)
        
        // Prompt should be substantial but not excessive
        XCTAssertGreaterThan(prompt.count, 500)   // Should have detailed instructions
        XCTAssertLessThan(prompt.count, 10000)    // Should not be excessive
    }
    
    func testPromptContextTruncation() {
        let veryLargeMessages = createVeryLargeMessageSet()
        let prompt = promptEngineer.createPersonalityAnalysisPrompt(messages: veryLargeMessages)
        
        // Should handle large message sets gracefully
        XCTAssertLessThan(prompt.count, 20000) // Should be truncated if necessary
        XCTAssertTrue(prompt.contains("MESSAGE CONTEXT:"))
    }
    
    // MARK: - Message Filtering Tests
    
    func testFinancialMessageFiltering() {
        let mixedMessages = createMixedContentMessages()
        let financialPrompt = promptEngineer.createFinancialBehaviorPrompt(messages: mixedMessages)
        
        // Should focus on financial content
        XCTAssertTrue(financialPrompt.contains("payment"))
        XCTAssertTrue(financialPrompt.contains("budget"))
    }
    
    func testRelationshipMessageFiltering() {
        let mixedMessages = createMixedContentMessages()
        let relationshipPrompt = promptEngineer.createRelationshipAnalysisPrompt(messages: mixedMessages)
        
        // Should focus on relationship content
        XCTAssertTrue(relationshipPrompt.contains("love"))
        XCTAssertTrue(relationshipPrompt.contains("family"))
    }
}

// MARK: - Test Data Creation

extension PromptEngineerTests {
    
    private func createTestMessages() -> [Message] {
        let baseDate = Date()
        return [
            Message(content: "I love being creative and trying new things", timestamp: baseDate, sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "I always plan my finances carefully", timestamp: baseDate.addingTimeInterval(300), sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "Parties are so much fun! I love meeting people", timestamp: baseDate.addingTimeInterval(600), sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "I'm always happy to help others", timestamp: baseDate.addingTimeInterval(900), sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "I stay calm under pressure", timestamp: baseDate.addingTimeInterval(1200), sender: "User", recipient: "Friend", isFromUser: true)
        ]
    }
    
    private func createTestPersonalityTraits() -> PersonalityTraits {
        return PersonalityTraits(
            openness: 0.7,
            conscientiousness: 0.8,
            extraversion: 0.6,
            agreeableness: 0.9,
            neuroticism: 0.3,
            confidence: 0.85
        )
    }
    
    private func createFinancialMessages() -> [Message] {
        let baseDate = Date()
        return [
            Message(content: "Just paid my rent, $1200 this month", timestamp: baseDate, sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "Need to budget better for groceries", timestamp: baseDate.addingTimeInterval(300), sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "My savings account is growing nicely", timestamp: baseDate.addingTimeInterval(600), sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "Thinking about investing in stocks", timestamp: baseDate.addingTimeInterval(900), sender: "User", recipient: "Friend", isFromUser: true)
        ]
    }
    
    private func createRelationshipMessages() -> [Message] {
        let baseDate = Date()
        return [
            Message(content: "I love spending time with my family", timestamp: baseDate, sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "Trust is so important in relationships", timestamp: baseDate.addingTimeInterval(300), sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "I'm always there to support my friends", timestamp: baseDate.addingTimeInterval(600), sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "Communication helps resolve conflicts", timestamp: baseDate.addingTimeInterval(900), sender: "User", recipient: "Friend", isFromUser: true)
        ]
    }
    
    private func createLargeMessageSet() -> [Message] {
        var messages: [Message] = []
        let baseDate = Date()
        
        for i in 0..<50 {
            messages.append(Message(
                content: "Test message number \(i) with varied content about life and experiences",
                timestamp: baseDate.addingTimeInterval(TimeInterval(i * 60)),
                sender: i % 2 == 0 ? "User" : "Friend",
                recipient: i % 2 == 0 ? "Friend" : "User",
                isFromUser: i % 2 == 0
            ))
        }
        
        return messages
    }
    
    private func createVeryLargeMessageSet() -> [Message] {
        var messages: [Message] = []
        let baseDate = Date()
        
        // Create 200 messages to test context truncation
        for i in 0..<200 {
            messages.append(Message(
                content: "This is a very long test message number \(i) with lots of content to test context truncation functionality and ensure prompts don't exceed reasonable length limits",
                timestamp: baseDate.addingTimeInterval(TimeInterval(i * 30)),
                sender: i % 3 == 0 ? "User" : "Contact\(i % 5)",
                recipient: i % 3 == 0 ? "Contact\(i % 5)" : "User",
                isFromUser: i % 3 == 0
            ))
        }
        
        return messages
    }
    
    private func createMixedContentMessages() -> [Message] {
        let baseDate = Date()
        return [
            Message(content: "I love my family so much", timestamp: baseDate, sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "Need to pay my credit card bill", timestamp: baseDate.addingTimeInterval(300), sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "What's the weather like today?", timestamp: baseDate.addingTimeInterval(600), sender: "Friend", recipient: "User", isFromUser: false),
            Message(content: "My budget is really tight this month", timestamp: baseDate.addingTimeInterval(900), sender: "User", recipient: "Friend", isFromUser: true),
            Message(content: "I care deeply about my relationships", timestamp: baseDate.addingTimeInterval(1200), sender: "User", recipient: "Friend", isFromUser: true)
        ]
    }
}