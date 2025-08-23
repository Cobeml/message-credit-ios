import XCTest
@testable import PrivacyCreditAnalyzer

final class MessageFilterEngineTests: XCTestCase {
    
    var filterEngine: MessageFilterEngine!
    var testMessages: [Message]!
    
    override func setUp() {
        super.setUp()
        filterEngine = MessageFilterEngine()
        testMessages = createTestMessages()
    }
    
    override func tearDown() {
        filterEngine = nil
        testMessages = nil
        super.tearDown()
    }
    
    // MARK: - Test Data Creation
    
    private func createTestMessages() -> [Message] {
        let baseDate = Date()
        
        return [
            // Messages from loved one (high frequency, emotional content)
            Message(content: "Hey honey, how was your day? ❤️", timestamp: baseDate.addingTimeInterval(-3600), sender: "Alice", recipient: "Me", isFromUser: false),
            Message(content: "I love you so much! Can't wait to see you", timestamp: baseDate.addingTimeInterval(-3500), sender: "Alice", recipient: "Me", isFromUser: false),
            Message(content: "Thanks for being there for me", timestamp: baseDate.addingTimeInterval(-3400), sender: "Alice", recipient: "Me", isFromUser: false),
            Message(content: "Love you too! See you soon", timestamp: baseDate.addingTimeInterval(-3300), sender: "Me", recipient: "Alice", isFromUser: true),
            Message(content: "Can you lend me $50 for groceries?", timestamp: baseDate.addingTimeInterval(-3200), sender: "Alice", recipient: "Me", isFromUser: false),
            Message(content: "Of course! I'll transfer it now", timestamp: baseDate.addingTimeInterval(-3100), sender: "Me", recipient: "Alice", isFromUser: true),
            Message(content: "You're the best! I'll pay you back tomorrow", timestamp: baseDate.addingTimeInterval(-3000), sender: "Alice", recipient: "Me", isFromUser: false),
            Message(content: "No rush, take your time", timestamp: baseDate.addingTimeInterval(-2900), sender: "Me", recipient: "Alice", isFromUser: true),
            Message(content: "How's your mom doing?", timestamp: baseDate.addingTimeInterval(-2800), sender: "Alice", recipient: "Me", isFromUser: false),
            Message(content: "She's doing better, thanks for asking", timestamp: baseDate.addingTimeInterval(-2700), sender: "Me", recipient: "Alice", isFromUser: true),
            Message(content: "I'm so happy to hear that!", timestamp: baseDate.addingTimeInterval(-2600), sender: "Alice", recipient: "Me", isFromUser: false),
            Message(content: "Want to grab dinner tonight?", timestamp: baseDate.addingTimeInterval(-2500), sender: "Alice", recipient: "Me", isFromUser: false),
            
            // Messages from acquaintance (lower frequency, some financial content)
            Message(content: "Hey, can you help me with rent this month?", timestamp: baseDate.addingTimeInterval(-2400), sender: "Bob", recipient: "Me", isFromUser: false),
            Message(content: "I need about $200 for utilities", timestamp: baseDate.addingTimeInterval(-2300), sender: "Bob", recipient: "Me", isFromUser: false),
            Message(content: "I can help with $100", timestamp: baseDate.addingTimeInterval(-2200), sender: "Me", recipient: "Bob", isFromUser: true),
            Message(content: "Thanks, that helps a lot", timestamp: baseDate.addingTimeInterval(-2100), sender: "Bob", recipient: "Me", isFromUser: false),
            
            // Messages from casual contact (low frequency, no financial content)
            Message(content: "Hey, what's up?", timestamp: baseDate.addingTimeInterval(-2000), sender: "Charlie", recipient: "Me", isFromUser: false),
            Message(content: "Not much, just working", timestamp: baseDate.addingTimeInterval(-1900), sender: "Me", recipient: "Charlie", isFromUser: true),
            Message(content: "Cool, talk later", timestamp: baseDate.addingTimeInterval(-1800), sender: "Charlie", recipient: "Me", isFromUser: false),
            
            // Financial messages from various contacts
            Message(content: "The mortgage payment is due next week", timestamp: baseDate.addingTimeInterval(-1700), sender: "Bank", recipient: "Me", isFromUser: false),
            Message(content: "Your credit card bill is $150.75", timestamp: baseDate.addingTimeInterval(-1600), sender: "CreditCard", recipient: "Me", isFromUser: false),
            Message(content: "Investment portfolio update: +$500 this month", timestamp: baseDate.addingTimeInterval(-1500), sender: "Investment", recipient: "Me", isFromUser: false),
            
            // More messages from loved one to increase frequency
            Message(content: "Good morning beautiful! 😍", timestamp: baseDate.addingTimeInterval(-1400), sender: "Alice", recipient: "Me", isFromUser: false),
            Message(content: "Good morning! Have a great day", timestamp: baseDate.addingTimeInterval(-1300), sender: "Me", recipient: "Alice", isFromUser: true),
            Message(content: "Thinking of you ❤️", timestamp: baseDate.addingTimeInterval(-1200), sender: "Alice", recipient: "Me", isFromUser: false),
            Message(content: "Miss you too!", timestamp: baseDate.addingTimeInterval(-1100), sender: "Me", recipient: "Alice", isFromUser: true),
        ]
    }
    
    // MARK: - Basic Filtering Tests
    
    func testFilterAllMessages() {
        let result = filterEngine.filterMessages(testMessages, strategy: .all)
        
        XCTAssertEqual(result.filteredMessages.count, testMessages.count)
        XCTAssertEqual(result.totalOriginalCount, testMessages.count)
    }
    
    func testFilterByLovedOnes() {
        let result = filterEngine.filterMessages(testMessages, strategy: .lovedOnes)
        
        // Alice should be identified as a loved one due to high frequency and emotional content
        let aliceMessages = result.filteredMessages.filter { message in
            message.sender == "Alice" || message.recipient == "Alice"
        }
        
        XCTAssertTrue(aliceMessages.count > 0, "Should include messages from loved ones")
        XCTAssertTrue(result.filteredMessages.count < testMessages.count, "Should filter out some messages")
        
        // Check that relationship score for Alice is high
        XCTAssertTrue(result.filteringStats.relationshipScores["Alice"] ?? 0.0 > 0.6, "Alice should have high relationship score")
    }
    
    func testFilterByFinancialKeywords() {
        let result = filterEngine.filterMessages(testMessages, strategy: .financialKeywords)
        
        // Should include messages with financial content
        XCTAssertTrue(result.filteredMessages.count > 0, "Should find financial messages")
        XCTAssertTrue(result.filteredMessages.count < testMessages.count, "Should filter out non-financial messages")
        
        // Verify that most filtered messages contain financial keywords
        let financialContentCount = result.filteredMessages.filter { message in
            let content = message.content.lowercased()
            return content.contains("$") || 
                   content.contains("lend") || 
                   content.contains("rent") || 
                   content.contains("utilities") ||
                   content.contains("mortgage") ||
                   content.contains("credit") ||
                   content.contains("investment") ||
                   content.contains("bill") ||
                   content.contains("payment") ||
                   content.contains("borrow") ||
                   content.contains("pay") ||
                   content.contains("money") ||
                   content.contains("cash") ||
                   content.contains("dollar") ||
                   content.contains("cost") ||
                   content.contains("price")
        }.count
        
        XCTAssertGreaterThan(financialContentCount, 0, "Should find messages with financial content")
    }
    
    func testCombinedFiltering() {
        let result = filterEngine.filterMessages(testMessages, strategy: .combined(lovedOnes: true, financialKeywords: true))
        
        // Should include both loved ones messages and financial messages
        let lovedOnesResult = filterEngine.filterMessages(testMessages, strategy: .lovedOnes)
        let financialResult = filterEngine.filterMessages(testMessages, strategy: .financialKeywords)
        
        // Combined result should be at least as large as the larger individual result
        let maxIndividualCount = max(lovedOnesResult.filteredMessages.count, financialResult.filteredMessages.count)
        XCTAssertGreaterThanOrEqual(result.filteredMessages.count, maxIndividualCount)
    }
    
    // MARK: - Relationship Score Tests
    
    func testRelationshipScoreCalculation() {
        // Use a lower frequency threshold to ensure all contacts get scores
        let config = MessageFilterEngine.FilterConfiguration(minMessageFrequency: 2)
        let result = filterEngine.filterMessages(testMessages, strategy: .all, configuration: config)
        let relationshipScores = result.filteringStats.relationshipScores
        
        // Alice should have the highest relationship score due to frequency and emotional content
        let aliceScore = relationshipScores["Alice"] ?? 0.0
        let bobScore = relationshipScores["Bob"] ?? 0.0
        let charlieScore = relationshipScores["Charlie"] ?? 0.0
        
        XCTAssertGreaterThan(aliceScore, bobScore, "Alice should have higher score than Bob")
        XCTAssertGreaterThan(aliceScore, charlieScore, "Alice should have higher score than Charlie")
        // Bob and Charlie might have similar low scores, so just check Alice is highest
        XCTAssertGreaterThan(aliceScore, 0.0, "Alice should have a positive relationship score")
    }
    
    func testMinimumMessageFrequencyThreshold() {
        let config = MessageFilterEngine.FilterConfiguration(minMessageFrequency: 5)
        let result = filterEngine.filterMessages(testMessages, strategy: .lovedOnes, configuration: config)
        
        // Only contacts with 5+ messages should be considered
        let includedContacts = Set(result.filteredMessages.map { message in
            message.isFromUser ? message.recipient : message.sender
        })
        
        // Charlie has only 2 messages, so should not be included
        XCTAssertFalse(includedContacts.contains("Charlie"), "Charlie should not be included due to low message frequency")
    }
    
    // MARK: - Financial Content Detection Tests
    
    func testCurrencyPatternDetection() {
        let messagesWithCurrency = [
            Message(content: "I need $100 for rent", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false),
            Message(content: "The cost is €50", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false),
            Message(content: "That's £25.50", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false),
            Message(content: "Just 50 cents", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false),
            Message(content: "About 100 dollars", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false),
        ]
        
        let result = filterEngine.filterMessages(messagesWithCurrency, strategy: .financialKeywords)
        
        XCTAssertEqual(result.filteredMessages.count, messagesWithCurrency.count, "All currency messages should be detected")
    }
    
    func testFinancialContextDetection() {
        let messagesWithFinancialContext = [
            Message(content: "Can you lend me some money?", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false),
            Message(content: "I need to borrow cash", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false),
            Message(content: "I'll pay you back tomorrow", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false),
            Message(content: "Short on cash this month", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false),
            Message(content: "Can you help with rent?", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false),
            Message(content: "Venmo me when you can", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false),
        ]
        
        let result = filterEngine.filterMessages(messagesWithFinancialContext, strategy: .financialKeywords)
        
        XCTAssertEqual(result.filteredMessages.count, messagesWithFinancialContext.count, "All financial context messages should be detected")
    }
    
    func testFinancialKeywordStats() {
        let result = filterEngine.filterMessages(testMessages, strategy: .all)
        let keywordStats = result.filteringStats.topFinancialKeywords
        
        XCTAssertTrue(keywordStats.count > 0, "Should find financial keywords")
        
        // Check that common keywords are found
        let allKeywords = keywordStats.keys
        let hasExpectedKeywords = allKeywords.contains { keyword in
            ["$", "lend", "rent", "utilities", "mortgage", "credit", "investment", "bill", "payment"].contains(keyword)
        }
        
        XCTAssertTrue(hasExpectedKeywords, "Should find expected financial keywords")
    }
    
    // MARK: - Emotional Content Detection Tests
    
    func testEmotionalContentDetection() {
        let emotionalMessages = [
            Message(content: "I love you so much! ❤️", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false),
            Message(content: "Thanks for being there for me", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false),
            Message(content: "I'm so happy to hear that!", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false),
            Message(content: "Miss you too! 😢", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false),
            Message(content: "You're the best friend ever", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false),
        ]
        
        // Create multiple messages from the same sender to meet frequency threshold
        var allMessages: [Message] = []
        for _ in 0..<3 {
            allMessages.append(contentsOf: emotionalMessages)
        }
        
        let result = filterEngine.filterMessages(allMessages, strategy: .lovedOnes)
        
        // Should identify this contact as a loved one due to emotional content
        XCTAssertTrue(result.filteredMessages.count > 0, "Should identify emotional messages as from loved ones")
    }
    
    // MARK: - Configuration Tests
    
    func testCustomConfiguration() {
        let strictConfig = MessageFilterEngine.FilterConfiguration(
            minMessageFrequency: 15,
            relationshipScoreThreshold: 0.8,
            financialKeywordWeight: 1.5,
            emotionalContentWeight: 1.2
        )
        
        let lenientConfig = MessageFilterEngine.FilterConfiguration(
            minMessageFrequency: 2,
            relationshipScoreThreshold: 0.3,
            financialKeywordWeight: 0.5,
            emotionalContentWeight: 0.5
        )
        
        let strictResult = filterEngine.filterMessages(testMessages, strategy: .lovedOnes, configuration: strictConfig)
        let lenientResult = filterEngine.filterMessages(testMessages, strategy: .lovedOnes, configuration: lenientConfig)
        
        // Lenient configuration should include more messages
        XCTAssertGreaterThanOrEqual(lenientResult.filteredMessages.count, strictResult.filteredMessages.count)
    }
    
    // MARK: - Statistics Tests
    
    func testFilteringStats() {
        let result = filterEngine.filterMessages(testMessages, strategy: .all)
        let stats = result.filteringStats
        
        XCTAssertGreaterThan(stats.lovedOnesCount, 0, "Should identify some loved ones")
        XCTAssertGreaterThan(stats.financialMessagesCount, 0, "Should identify some financial messages")
        XCTAssertGreaterThan(stats.relationshipScores.count, 0, "Should calculate relationship scores")
        XCTAssertGreaterThan(stats.topFinancialKeywords.count, 0, "Should find financial keywords")
    }
    
    func testTopContacts() {
        let topContacts = filterEngine.getTopContacts(testMessages, limit: 3)
        
        XCTAssertLessThanOrEqual(topContacts.count, 3, "Should respect the limit")
        XCTAssertTrue(topContacts.count > 0, "Should find some contacts")
        
        // Should be sorted by score (highest first)
        for i in 1..<topContacts.count {
            XCTAssertGreaterThanOrEqual(topContacts[i-1].score, topContacts[i].score, "Should be sorted by score")
        }
        
        // Alice should be the top contact
        XCTAssertEqual(topContacts.first?.contact, "Alice", "Alice should be the top contact")
    }
    
    func testFinancialStats() {
        let (totalFinancial, topKeywords, averageLength) = filterEngine.getFinancialStats(testMessages)
        
        XCTAssertGreaterThan(totalFinancial, 0, "Should find financial messages")
        XCTAssertGreaterThan(topKeywords.count, 0, "Should find financial keywords")
        XCTAssertGreaterThan(averageLength, 0, "Should calculate average length")
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyMessageArray() {
        let result = filterEngine.filterMessages([], strategy: .all)
        
        XCTAssertEqual(result.filteredMessages.count, 0)
        XCTAssertEqual(result.totalOriginalCount, 0)
        XCTAssertEqual(result.filteringStats.lovedOnesCount, 0)
        XCTAssertEqual(result.filteringStats.financialMessagesCount, 0)
    }
    
    func testSingleMessage() {
        let singleMessage = [Message(content: "Hello", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false)]
        let result = filterEngine.filterMessages(singleMessage, strategy: .lovedOnes)
        
        // Single message shouldn't meet frequency threshold
        XCTAssertEqual(result.filteredMessages.count, 0)
    }
    
    func testMessagesWithoutFinancialContent() {
        let nonFinancialMessages = [
            Message(content: "How are you?", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false),
            Message(content: "I'm good, thanks", timestamp: Date(), sender: "Me", recipient: "Test", isFromUser: true),
            Message(content: "What's the weather like?", timestamp: Date(), sender: "Test", recipient: "Me", isFromUser: false),
        ]
        
        let result = filterEngine.filterMessages(nonFinancialMessages, strategy: .financialKeywords)
        
        XCTAssertEqual(result.filteredMessages.count, 0, "Should not find any financial messages")
        XCTAssertEqual(result.filteringStats.financialMessagesCount, 0)
    }
    
    func testDuplicateMessageHandling() {
        // Use a message that contains financial content to ensure it gets filtered
        let financialMessage = Message(content: "Can you lend me $50?", timestamp: Date(), sender: "Alice", recipient: "Me", isFromUser: false)
        let duplicateMessages = Array(repeating: financialMessage, count: 15) // Ensure it meets frequency threshold
        let result = filterEngine.filterMessages(duplicateMessages, strategy: .combined(lovedOnes: true, financialKeywords: true))
        
        // Should handle duplicates gracefully and include financial messages
        XCTAssertGreaterThan(result.filteredMessages.count, 0, "Should include financial messages")
        XCTAssertEqual(result.totalOriginalCount, duplicateMessages.count)
    }
    
    // MARK: - Performance Tests
    
    func testLargeMessageSetPerformance() {
        // Create a large set of messages
        var largeMessageSet: [Message] = []
        for _ in 0..<100 {
            largeMessageSet.append(contentsOf: testMessages)
        }
        
        measure {
            let _ = filterEngine.filterMessages(largeMessageSet, strategy: .combined(lovedOnes: true, financialKeywords: true))
        }
    }
}