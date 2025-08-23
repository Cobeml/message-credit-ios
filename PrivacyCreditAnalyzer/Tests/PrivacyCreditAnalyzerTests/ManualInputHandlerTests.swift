import XCTest
@testable import PrivacyCreditAnalyzer

final class ManualInputHandlerTests: XCTestCase {
    
    var handler: ManualInputHandler!
    
    override func setUp() {
        super.setUp()
        handler = ManualInputHandler()
    }
    
    override func tearDown() {
        handler = nil
        super.tearDown()
    }
    
    // MARK: - Basic Parsing Tests
    
    func testParseStructuredConversation() throws {
        let input = """
        John: Hey, can you lend me $50?
        Me: Sure, I can help you out
        John: Thanks! I'll pay you back next week
        Me: No problem at all
        """
        
        let messages = try handler.parseManualInput(input)
        
        XCTAssertEqual(messages.count, 4)
        
        XCTAssertEqual(messages[0].content, "Hey, can you lend me $50?")
        XCTAssertEqual(messages[0].sender, "John")
        XCTAssertEqual(messages[0].recipient, "Me")
        XCTAssertFalse(messages[0].isFromUser)
        
        XCTAssertEqual(messages[1].content, "Sure, I can help you out")
        XCTAssertEqual(messages[1].sender, "Me")
        XCTAssertEqual(messages[1].recipient, "Unknown")
        XCTAssertTrue(messages[1].isFromUser)
        
        XCTAssertEqual(messages[2].content, "Thanks! I'll pay you back next week")
        XCTAssertEqual(messages[2].sender, "John")
        XCTAssertFalse(messages[2].isFromUser)
        
        XCTAssertEqual(messages[3].content, "No problem at all")
        XCTAssertEqual(messages[3].sender, "Me")
        XCTAssertTrue(messages[3].isFromUser)
    }
    
    func testParseTimestampedMessages() throws {
        let input = """
        [2022-01-01 10:30] Alice: I need to borrow $100
        [2022-01-01 10:32] Me: When do you need it by?
        [2022-01-01 10:35] Alice: By tomorrow if possible
        [2022-01-01 10:37] Me: I can transfer it now
        """
        
        let messages = try handler.parseManualInput(input)
        
        XCTAssertEqual(messages.count, 4)
        
        XCTAssertEqual(messages[0].content, "I need to borrow $100")
        XCTAssertEqual(messages[0].sender, "Alice")
        XCTAssertFalse(messages[0].isFromUser)
        
        XCTAssertEqual(messages[1].content, "When do you need it by?")
        XCTAssertEqual(messages[1].sender, "Me")
        XCTAssertTrue(messages[1].isFromUser)
        
        XCTAssertEqual(messages[2].content, "By tomorrow if possible")
        XCTAssertEqual(messages[2].sender, "Alice")
        XCTAssertFalse(messages[2].isFromUser)
        
        XCTAssertEqual(messages[3].content, "I can transfer it now")
        XCTAssertEqual(messages[3].sender, "Me")
        XCTAssertTrue(messages[3].isFromUser)
    }
    
    func testParseSimpleMessages() throws {
        let input = """
        Can you help me with rent this month?
        How much do you need?
        About $500 would be great
        I can send it tomorrow
        """
        
        let messages = try handler.parseManualInput(input)
        
        XCTAssertEqual(messages.count, 4)
        
        // First message should be from user (index 0)
        XCTAssertEqual(messages[0].content, "Can you help me with rent this month?")
        XCTAssertEqual(messages[0].sender, "Me")
        XCTAssertTrue(messages[0].isFromUser)
        
        // Second message should be from other (index 1)
        XCTAssertEqual(messages[1].content, "How much do you need?")
        XCTAssertEqual(messages[1].sender, "Other")
        XCTAssertFalse(messages[1].isFromUser)
        
        // Third message should be from user (index 2)
        XCTAssertEqual(messages[2].content, "About $500 would be great")
        XCTAssertEqual(messages[2].sender, "Me")
        XCTAssertTrue(messages[2].isFromUser)
        
        // Fourth message should be from other (index 3)
        XCTAssertEqual(messages[3].content, "I can send it tomorrow")
        XCTAssertEqual(messages[3].sender, "Other")
        XCTAssertFalse(messages[3].isFromUser)
    }
    
    // MARK: - Error Handling Tests
    
    func testParseEmptyInput() {
        let input = ""
        
        XCTAssertThrowsError(try handler.parseManualInput(input)) { error in
            XCTAssertTrue(error is ManualInputHandler.InputError)
            if case ManualInputHandler.InputError.emptyInput = error {
                // Expected error
            } else {
                XCTFail("Expected emptyInput error")
            }
        }
    }
    
    func testParseWhitespaceOnlyInput() {
        let input = "   \n\t  \n  "
        
        XCTAssertThrowsError(try handler.parseManualInput(input)) { error in
            XCTAssertTrue(error is ManualInputHandler.InputError)
            if case ManualInputHandler.InputError.emptyInput = error {
                // Expected error
            } else {
                XCTFail("Expected emptyInput error")
            }
        }
    }
    
    func testParseNoValidMessages() {
        let input = """
        :
        :
        :
        """
        
        XCTAssertThrowsError(try handler.parseManualInput(input)) { error in
            XCTAssertTrue(error is ManualInputHandler.InputError)
            if case ManualInputHandler.InputError.noValidMessages = error {
                // Expected error
            } else {
                XCTFail("Expected noValidMessages error")
            }
        }
    }
    
    // MARK: - Timestamp Parsing Tests
    
    func testParseVariousTimestampFormats() throws {
        let input = """
        [2022-01-01 10:30:45] Bob: Full timestamp format
        [10:30] Alice: Time only format
        [Jan 1, 2022 10:30] Charlie: Month name format
        [01/01/2022 10:30] Dave: US date format
        """
        
        let messages = try handler.parseManualInput(input)
        
        XCTAssertEqual(messages.count, 4)
        
        XCTAssertEqual(messages[0].content, "Full timestamp format")
        XCTAssertEqual(messages[0].sender, "Bob")
        
        XCTAssertEqual(messages[1].content, "Time only format")
        XCTAssertEqual(messages[1].sender, "Alice")
        
        XCTAssertEqual(messages[2].content, "Month name format")
        XCTAssertEqual(messages[2].sender, "Charlie")
        
        XCTAssertEqual(messages[3].content, "US date format")
        XCTAssertEqual(messages[3].sender, "Dave")
    }
    
    // MARK: - User Detection Tests
    
    func testUserSpeakerDetection() throws {
        let input = """
        Me: I am the user
        I: Also the user
        Myself: Still the user
        You: Another user indicator
        John: Not the user
        Alice: Also not the user
        """
        
        let messages = try handler.parseManualInput(input)
        
        XCTAssertEqual(messages.count, 6)
        
        XCTAssertTrue(messages[0].isFromUser)   // Me
        XCTAssertTrue(messages[1].isFromUser)   // I
        XCTAssertTrue(messages[2].isFromUser)   // Myself
        XCTAssertTrue(messages[3].isFromUser)   // You
        XCTAssertFalse(messages[4].isFromUser)  // John
        XCTAssertFalse(messages[5].isFromUser)  // Alice
    }
    
    // MARK: - Text Preprocessing Tests
    
    func testPreprocessText() {
        let input = "  Line 1  \r\n\r\n  Line 2  \n\n\n\n  Line 3  \t\t\n  "
        let expected = "Line 1\n\nLine 2\n\nLine 3"
        
        let result = handler.preprocessText(input)
        
        XCTAssertEqual(result, expected)
    }
    
    func testPreprocessTextRemovesExcessiveWhitespace() {
        let input = "Word1    \t   Word2     Word3"
        let expected = "Word1 Word2 Word3"
        
        let result = handler.preprocessText(input)
        
        XCTAssertEqual(result, expected)
    }
    
    func testPreprocessTextNormalizesLineEndings() {
        let input = "Line1\r\nLine2\rLine3\nLine4"
        let expected = "Line1\nLine2\nLine3\nLine4"
        
        let result = handler.preprocessText(input)
        
        XCTAssertEqual(result, expected)
    }
    
    // MARK: - Message Boundary Detection Tests
    
    func testDetectMessageBoundariesWithConversationMarkers() {
        let input = """
        John: First message
        Alice: Second message
        Bob: Third message
        """
        
        let boundaries = handler.detectMessageBoundaries(input)
        
        XCTAssertEqual(boundaries.count, 3)
        XCTAssertTrue(boundaries[0].contains("First message"))
        XCTAssertTrue(boundaries[1].contains("Second message"))
        XCTAssertTrue(boundaries[2].contains("Third message"))
    }
    
    func testDetectMessageBoundariesWithTimestamps() {
        let input = """
        [10:30] First message
        [10:32] Second message
        [10:35] Third message
        """
        
        let boundaries = handler.detectMessageBoundaries(input)
        
        XCTAssertEqual(boundaries.count, 3)
        XCTAssertTrue(boundaries[0].contains("First message"))
        XCTAssertTrue(boundaries[1].contains("Second message"))
        XCTAssertTrue(boundaries[2].contains("Third message"))
    }
    
    func testDetectMessageBoundariesWithParagraphs() {
        let input = """
        First paragraph message.
        
        Second paragraph message.
        
        Third paragraph message.
        """
        
        let boundaries = handler.detectMessageBoundaries(input)
        
        XCTAssertEqual(boundaries.count, 3)
        XCTAssertEqual(boundaries[0], "First paragraph message.")
        XCTAssertEqual(boundaries[1], "Second paragraph message.")
        XCTAssertEqual(boundaries[2], "Third paragraph message.")
    }
    
    func testDetectMessageBoundariesWithLines() {
        let input = """
        First line message
        Second line message
        Third line message
        """
        
        let boundaries = handler.detectMessageBoundaries(input)
        
        XCTAssertEqual(boundaries.count, 3)
        XCTAssertEqual(boundaries[0], "First line message")
        XCTAssertEqual(boundaries[1], "Second line message")
        XCTAssertEqual(boundaries[2], "Third line message")
    }
    
    func testDetectMessageBoundariesFallback() {
        let input = "Single continuous message without clear boundaries"
        
        let boundaries = handler.detectMessageBoundaries(input)
        
        XCTAssertEqual(boundaries.count, 1)
        XCTAssertEqual(boundaries[0], input)
    }
    
    // MARK: - Edge Cases Tests
    
    func testParseMessagesWithEmptyLines() throws {
        let input = """
        John: First message
        
        Alice: Second message
        
        
        Bob: Third message
        """
        
        let messages = try handler.parseManualInput(input)
        
        XCTAssertEqual(messages.count, 3)
        XCTAssertEqual(messages[0].sender, "John")
        XCTAssertEqual(messages[1].sender, "Alice")
        XCTAssertEqual(messages[2].sender, "Bob")
    }
    
    func testParseMessagesWithSpecialCharacters() throws {
        let input = """
        John: Hey! Can you help with $100? 💰
        Me: Sure thing! 😊 When do you need it?
        John: ASAP please... it's urgent! 🙏
        """
        
        let messages = try handler.parseManualInput(input)
        
        XCTAssertEqual(messages.count, 3)
        XCTAssertEqual(messages[0].content, "Hey! Can you help with $100? 💰")
        XCTAssertEqual(messages[1].content, "Sure thing! 😊 When do you need it?")
        XCTAssertEqual(messages[2].content, "ASAP please... it's urgent! 🙏")
    }
    
    func testParseMessagesWithLongContent() throws {
        let longMessage = String(repeating: "This is a very long message. ", count: 50).trimmingCharacters(in: .whitespacesAndNewlines)
        let input = """
        John: \(longMessage)
        Me: Got it, thanks for the detailed explanation
        """
        
        let messages = try handler.parseManualInput(input)
        
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0].content, longMessage)
        XCTAssertEqual(messages[1].content, "Got it, thanks for the detailed explanation")
    }
    
    func testParseMessagesWithColonsInContent() throws {
        let input = """
        John: The time is 10:30 AM and the ratio is 3:1
        Me: Meeting at 2:00 PM: don't forget!
        """
        
        let messages = try handler.parseManualInput(input)
        
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0].content, "The time is 10:30 AM and the ratio is 3:1")
        XCTAssertEqual(messages[1].content, "Meeting at 2:00 PM: don't forget!")
    }
    
    // MARK: - Real-world Format Tests
    
    func testParseWhatsAppExportFormat() throws {
        let input = """
        [1/1/22, 10:30:15 AM] John Doe: Can you lend me some money?
        [1/1/22, 10:32:20 AM] Me: How much do you need?
        [1/1/22, 10:35:10 AM] John Doe: About $200 for groceries
        [1/1/22, 10:37:45 AM] Me: I can help you out
        """
        
        let messages = try handler.parseManualInput(input)
        
        XCTAssertEqual(messages.count, 4)
        XCTAssertEqual(messages[0].content, "Can you lend me some money?")
        XCTAssertEqual(messages[0].sender, "John Doe")
        XCTAssertFalse(messages[0].isFromUser)
        
        XCTAssertEqual(messages[1].content, "How much do you need?")
        XCTAssertEqual(messages[1].sender, "Me")
        XCTAssertTrue(messages[1].isFromUser)
    }
    
    func testParseSlackExportFormat() throws {
        let input = """
        Alice: I'm running short on cash this month
        You: What do you need help with?
        Alice: Could you spot me $150 for utilities?
        You: Sure, I'll send it over
        """
        
        let messages = try handler.parseManualInput(input)
        
        XCTAssertEqual(messages.count, 4)
        XCTAssertEqual(messages[0].content, "I'm running short on cash this month")
        XCTAssertEqual(messages[0].sender, "Alice")
        XCTAssertFalse(messages[0].isFromUser)
        
        XCTAssertEqual(messages[1].content, "What do you need help with?")
        XCTAssertEqual(messages[1].sender, "You")
        XCTAssertTrue(messages[1].isFromUser)
    }
}