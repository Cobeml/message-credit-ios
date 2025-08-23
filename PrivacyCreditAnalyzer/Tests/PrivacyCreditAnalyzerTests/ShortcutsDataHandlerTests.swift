import XCTest
@testable import PrivacyCreditAnalyzer

final class ShortcutsDataHandlerTests: XCTestCase {
    
    var handler: ShortcutsDataHandler!
    
    override func setUp() {
        super.setUp()
        handler = ShortcutsDataHandler()
    }
    
    override func tearDown() {
        handler = nil
        super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testDefaultConfiguration() {
        let config = ShortcutsDataHandler.Configuration.default
        XCTAssertEqual(config.maxMessagesPerConversation, 1000)
        XCTAssertEqual(config.maxTotalMessages, 5000)
        XCTAssertEqual(config.maxDataSizeBytes, 10 * 1024 * 1024)
    }
    
    // MARK: - Performance Tier Tests
    
    func testPerformanceTierProperties() {
        XCTAssertEqual(ShortcutsDataHandler.PerformanceTier.quick.messageLimit, 200)
        XCTAssertEqual(ShortcutsDataHandler.PerformanceTier.quick.timeRangeDays, 7)
        
        XCTAssertEqual(ShortcutsDataHandler.PerformanceTier.standard.messageLimit, 1000)
        XCTAssertEqual(ShortcutsDataHandler.PerformanceTier.standard.timeRangeDays, 30)
        
        XCTAssertEqual(ShortcutsDataHandler.PerformanceTier.deep.messageLimit, 5000)
        XCTAssertEqual(ShortcutsDataHandler.PerformanceTier.deep.timeRangeDays, 90)
    }
    
    // MARK: - Data Processing Tests
    
    func testProcessValidShortcutData() throws {
        let messages = createTestMessages(count: 10)
        let shortcutData = ShortcutMessageData(
            messages: messages,
            extractionDate: Date(),
            performanceTier: "quick",
            version: "1.0.0"
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(shortcutData)
        let processedMessages = try handler.processShortcutData(jsonData)
        
        XCTAssertEqual(processedMessages.count, 10)
        XCTAssertEqual(processedMessages.first?.content, messages.first?.content)
    }
    
    func testProcessDataWithSampling() throws {
        let messages = createTestMessages(count: 6000) // Exceeds max limit
        let shortcutData = ShortcutMessageData(
            messages: messages,
            extractionDate: Date(),
            performanceTier: "deep",
            version: "1.0.0"
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(shortcutData)
        let processedMessages = try handler.processShortcutData(jsonData)
        
        // Should be sampled down to at most the max limit
        XCTAssertLessThanOrEqual(processedMessages.count, 5000)
        XCTAssertGreaterThan(processedMessages.count, 1000) // Should have substantial data
    }
    
    func testProcessEmptyData() throws {
        let shortcutData = ShortcutMessageData(
            messages: [],
            extractionDate: Date(),
            performanceTier: "quick",
            version: "1.0.0"
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(shortcutData)
        
        XCTAssertThrowsError(try handler.processShortcutData(jsonData)) { error in
            XCTAssertTrue(error is ShortcutsDataHandler.ShortcutDataError)
            if case ShortcutsDataHandler.ShortcutDataError.emptyDataset = error {
                // Expected error
            } else {
                XCTFail("Expected emptyDataset error, got: \(error)")
            }
        }
    }
    
    func testProcessOversizedData() throws {
        let config = ShortcutsDataHandler.Configuration(
            maxMessagesPerConversation: 1000,
            maxTotalMessages: 5000,
            maxDataSizeBytes: 100 // Very small limit for testing
        )
        let handler = ShortcutsDataHandler(configuration: config)
        
        let messages = createTestMessages(count: 10)
        let shortcutData = ShortcutMessageData(
            messages: messages,
            extractionDate: Date(),
            performanceTier: "quick",
            version: "1.0.0"
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(shortcutData)
        
        XCTAssertThrowsError(try handler.processShortcutData(jsonData)) { error in
            XCTAssertTrue(error is ShortcutsDataHandler.ShortcutDataError)
            if case ShortcutsDataHandler.ShortcutDataError.dataSizeTooLarge = error {
                // Expected error
            } else {
                XCTFail("Expected dataSizeTooLarge error")
            }
        }
    }
    
    func testProcessInvalidJSON() throws {
        let invalidData = "invalid json".data(using: .utf8)!
        
        XCTAssertThrowsError(try handler.processShortcutData(invalidData)) { error in
            XCTAssertTrue(error is ShortcutsDataHandler.ShortcutDataError)
            if case ShortcutsDataHandler.ShortcutDataError.invalidJSON = error {
                // Expected error
            } else {
                XCTFail("Expected invalidJSON error")
            }
        }
    }
    
    // MARK: - Validation Tests
    
    func testValidateValidData() throws {
        let messages = createTestMessages(count: 100)
        let shortcutData = ShortcutMessageData(
            messages: messages,
            extractionDate: Date(),
            performanceTier: "standard",
            version: "1.0.0"
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(shortcutData)
        let validation = try handler.validateShortcutData(jsonData)
        
        XCTAssertTrue(validation.isValid)
        XCTAssertEqual(validation.messageCount, 100)
        XCTAssertFalse(validation.needsSampling)
        XCTAssertEqual(validation.recommendedSampleSize, 100)
    }
    
    func testValidateDataNeedingSampling() throws {
        let messages = createTestMessages(count: 6000)
        let shortcutData = ShortcutMessageData(
            messages: messages,
            extractionDate: Date(),
            performanceTier: "deep",
            version: "1.0.0"
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(shortcutData)
        let validation = try handler.validateShortcutData(jsonData)
        
        XCTAssertTrue(validation.isValid)
        XCTAssertEqual(validation.messageCount, 6000)
        XCTAssertTrue(validation.needsSampling)
        XCTAssertEqual(validation.recommendedSampleSize, 5000)
    }
    
    // MARK: - Sampling Tests
    
    func testApplySamplingWithFinancialMessages() throws {
        let financialMessages = createFinancialMessages(count: 50)
        let regularMessages = createTestMessages(count: 50)
        let allMessages = financialMessages + regularMessages
        
        let sampledMessages = try handler.applySampling(to: allMessages, targetCount: 60)
        
        // Should return at most the target count
        XCTAssertLessThanOrEqual(sampledMessages.count, 60)
        XCTAssertGreaterThan(sampledMessages.count, 0)
        
        // Should prioritize financial messages
        let financialInSample = sampledMessages.filter { containsFinancialKeywords($0.content) }
        XCTAssertGreaterThan(financialInSample.count, 10) // Should have significant financial content
    }
    
    func testApplySamplingWithNoSamplingNeeded() throws {
        let messages = createTestMessages(count: 50)
        let sampledMessages = try handler.applySampling(to: messages, targetCount: 100)
        
        XCTAssertEqual(sampledMessages.count, 50) // Should return all messages
    }
    
    func testApplySamplingPreservesMessageIntegrity() throws {
        let messages = createTestMessages(count: 100)
        let sampledMessages = try handler.applySampling(to: messages, targetCount: 50)
        
        // Should return at most the target count
        XCTAssertLessThanOrEqual(sampledMessages.count, 50)
        XCTAssertGreaterThan(sampledMessages.count, 0)
        
        // All sampled messages should be from the original set
        for sampledMessage in sampledMessages {
            XCTAssertTrue(messages.contains { $0.id == sampledMessage.id })
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testShortcutDataErrorDescriptions() {
        let errors: [ShortcutsDataHandler.ShortcutDataError] = [
            .tooManyMessages(count: 6000, limit: 5000),
            .dataSizeTooLarge(size: 20000000, limit: 10000000),
            .timeoutDuringExtraction,
            .insufficientPermissions,
            .invalidDataFormat,
            .samplingRequired(originalCount: 6000, targetCount: 5000),
            .emptyDataset,
            .invalidJSON
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestMessages(count: Int) -> [Message] {
        return (0..<count).map { index in
            Message(
                content: "Test message \(index)",
                timestamp: Date().addingTimeInterval(TimeInterval(-index * 3600)), // 1 hour apart
                sender: index % 2 == 0 ? "Alice" : "Bob",
                recipient: index % 2 == 0 ? "Bob" : "Alice",
                isFromUser: index % 2 == 0
            )
        }
    }
    
    private func createFinancialMessages(count: Int) -> [Message] {
        let financialKeywords = ["money", "loan", "payment", "bank", "credit", "$100", "budget"]
        
        return (0..<count).map { index in
            let keyword = financialKeywords[index % financialKeywords.count]
            return Message(
                content: "Message about \(keyword) and financial matters \(index)",
                timestamp: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                sender: index % 2 == 0 ? "Alice" : "Bob",
                recipient: index % 2 == 0 ? "Bob" : "Alice",
                isFromUser: index % 2 == 0
            )
        }
    }
    
    private func containsFinancialKeywords(_ content: String) -> Bool {
        let financialKeywords = [
            "money", "loan", "payment", "bank", "credit", "debt", "mortgage",
            "finance", "budget", "savings", "investment", "cash", "dollar",
            "pay", "owe", "borrow", "lend", "interest", "account", "balance",
            "$", "USD", "cost", "price", "buy", "sell", "purchase", "expense"
        ]
        
        let lowercaseContent = content.lowercased()
        return financialKeywords.contains { lowercaseContent.contains($0) }
    }
}