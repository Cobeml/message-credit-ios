import XCTest
@testable import PrivacyCreditAnalyzer

final class MessagesExportParserTests: XCTestCase {
    
    var parser: MessagesExportParser!
    
    override func setUp() {
        super.setUp()
        parser = MessagesExportParser()
    }
    
    override func tearDown() {
        parser = nil
        super.tearDown()
    }
    
    // MARK: - Basic Parsing Tests
    
    func testParseValidMessagesArray() async throws {
        let jsonData = """
        [
            {
                "content": "Hello there!",
                "timestamp": 1640995200,
                "sender": "John Doe",
                "recipient": "Me",
                "isFromUser": false
            },
            {
                "content": "Hi John!",
                "timestamp": 1640995260,
                "sender": "Me",
                "recipient": "John Doe",
                "isFromUser": true
            }
        ]
        """.data(using: .utf8)!
        
        let messages = try await parser.parseMessagesData(jsonData)
        
        XCTAssertEqual(messages.count, 2)
        
        let firstMessage = messages[0]
        XCTAssertEqual(firstMessage.content, "Hello there!")
        XCTAssertEqual(firstMessage.sender, "John Doe")
        XCTAssertEqual(firstMessage.recipient, "Me")
        XCTAssertFalse(firstMessage.isFromUser)
        
        let secondMessage = messages[1]
        XCTAssertEqual(secondMessage.content, "Hi John!")
        XCTAssertEqual(secondMessage.sender, "Me")
        XCTAssertEqual(secondMessage.recipient, "John Doe")
        XCTAssertTrue(secondMessage.isFromUser)
    }
    
    func testParseMessagesWithRootObject() async throws {
        let jsonData = """
        {
            "messages": [
                {
                    "text": "Test message",
                    "date": "2022-01-01T12:00:00Z",
                    "from": "Alice",
                    "to": "Bob"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let messages = try await parser.parseMessagesData(jsonData)
        
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].content, "Test message")
        XCTAssertEqual(messages[0].sender, "Alice")
        XCTAssertEqual(messages[0].recipient, "Bob")
    }
    
    func testParseMessagesWithDataRoot() async throws {
        let jsonData = """
        {
            "data": [
                {
                    "body": "Another test",
                    "timestamp": 1640995200000,
                    "handle": "+1234567890",
                    "chat": "Family Group"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let messages = try await parser.parseMessagesData(jsonData)
        
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].content, "Another test")
        XCTAssertEqual(messages[0].sender, "+1234567890")
        XCTAssertEqual(messages[0].recipient, "Family Group")
    }
    
    // MARK: - Error Handling Tests
    
    func testParseInvalidJSON() async {
        let invalidJsonData = "{ invalid json }".data(using: .utf8)!
        
        do {
            _ = try await parser.parseMessagesData(invalidJsonData)
            XCTFail("Should have thrown invalidJSON error")
        } catch MessagesExportParser.ParseError.invalidJSON {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testParseEmptyData() async {
        let emptyData = Data()
        
        do {
            _ = try await parser.parseMessagesData(emptyData)
            XCTFail("Should have thrown emptyFile error")
        } catch MessagesExportParser.ParseError.emptyFile {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testParseEmptyMessagesArray() async {
        let jsonData = "[]".data(using: .utf8)!
        
        do {
            _ = try await parser.parseMessagesData(jsonData)
            XCTFail("Should have thrown emptyFile error")
        } catch MessagesExportParser.ParseError.emptyFile {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testParseUnsupportedFormat() async {
        let jsonData = """
        {
            "unsupported": "format",
            "no_messages": true
        }
        """.data(using: .utf8)!
        
        do {
            _ = try await parser.parseMessagesData(jsonData)
            XCTFail("Should have thrown unsupportedFormat error")
        } catch MessagesExportParser.ParseError.unsupportedFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Field Extraction Tests
    
    func testExtractContentFromVariousFields() async throws {
        let jsonData = """
        [
            {
                "content": "Content field",
                "timestamp": 1640995200,
                "sender": "Test",
                "recipient": "Test"
            },
            {
                "text": "Text field",
                "timestamp": 1640995200,
                "sender": "Test",
                "recipient": "Test"
            },
            {
                "body": "Body field",
                "timestamp": 1640995200,
                "sender": "Test",
                "recipient": "Test"
            },
            {
                "message": "Message field",
                "timestamp": 1640995200,
                "sender": "Test",
                "recipient": "Test"
            }
        ]
        """.data(using: .utf8)!
        
        let messages = try await parser.parseMessagesData(jsonData)
        
        XCTAssertEqual(messages.count, 4)
        XCTAssertEqual(messages[0].content, "Content field")
        XCTAssertEqual(messages[1].content, "Text field")
        XCTAssertEqual(messages[2].content, "Body field")
        XCTAssertEqual(messages[3].content, "Message field")
    }
    
    func testExtractSenderFromVariousFields() async throws {
        let jsonData = """
        [
            {
                "content": "Test",
                "timestamp": 1640995200,
                "sender": "Sender field",
                "recipient": "Test"
            },
            {
                "content": "Test",
                "timestamp": 1640995200,
                "from": "From field",
                "recipient": "Test"
            },
            {
                "content": "Test",
                "timestamp": 1640995200,
                "handle": "+1234567890",
                "recipient": "Test"
            }
        ]
        """.data(using: .utf8)!
        
        let messages = try await parser.parseMessagesData(jsonData)
        
        XCTAssertEqual(messages.count, 3)
        XCTAssertEqual(messages[0].sender, "Sender field")
        XCTAssertEqual(messages[1].sender, "From field")
        XCTAssertEqual(messages[2].sender, "+1234567890")
    }
    
    // MARK: - Timestamp Parsing Tests
    
    func testParseUnixTimestampSeconds() async throws {
        let jsonData = """
        [
            {
                "content": "Test",
                "timestamp": 1640995200,
                "sender": "Test",
                "recipient": "Test"
            }
        ]
        """.data(using: .utf8)!
        
        let messages = try await parser.parseMessagesData(jsonData)
        
        XCTAssertEqual(messages.count, 1)
        let expectedDate = Date(timeIntervalSince1970: 1640995200)
        XCTAssertEqual(messages[0].timestamp.timeIntervalSince1970, expectedDate.timeIntervalSince1970, accuracy: 1.0)
    }
    
    func testParseUnixTimestampMilliseconds() async throws {
        let jsonData = """
        [
            {
                "content": "Test",
                "timestamp": 1640995200000,
                "sender": "Test",
                "recipient": "Test"
            }
        ]
        """.data(using: .utf8)!
        
        let messages = try await parser.parseMessagesData(jsonData)
        
        XCTAssertEqual(messages.count, 1)
        let expectedDate = Date(timeIntervalSince1970: 1640995200)
        XCTAssertEqual(messages[0].timestamp.timeIntervalSince1970, expectedDate.timeIntervalSince1970, accuracy: 1.0)
    }
    
    func testParseISO8601Timestamp() async throws {
        let jsonData = """
        [
            {
                "content": "Test",
                "date": "2022-01-01T12:00:00Z",
                "sender": "Test",
                "recipient": "Test"
            }
        ]
        """.data(using: .utf8)!
        
        let messages = try await parser.parseMessagesData(jsonData)
        
        XCTAssertEqual(messages.count, 1)
        // Verify the date was parsed (exact comparison depends on timezone)
        XCTAssertNotNil(messages[0].timestamp)
    }
    
    func testParseCustomDateFormats() async throws {
        let jsonData = """
        [
            {
                "content": "Test 1",
                "date": "2022-01-01 12:00:00",
                "sender": "Test",
                "recipient": "Test"
            },
            {
                "content": "Test 2",
                "date": "01/01/2022 12:00:00",
                "sender": "Test",
                "recipient": "Test"
            },
            {
                "content": "Test 3",
                "date": "2022-01-01",
                "sender": "Test",
                "recipient": "Test"
            }
        ]
        """.data(using: .utf8)!
        
        let messages = try await parser.parseMessagesData(jsonData)
        
        XCTAssertEqual(messages.count, 3)
        // Verify all dates were parsed
        for message in messages {
            XCTAssertNotNil(message.timestamp)
        }
    }
    
    // MARK: - IsFromUser Detection Tests
    
    func testIsFromUserExplicitField() async throws {
        let jsonData = """
        [
            {
                "content": "Test 1",
                "timestamp": 1640995200,
                "sender": "Test",
                "recipient": "Test",
                "isFromUser": true
            },
            {
                "content": "Test 2",
                "timestamp": 1640995200,
                "sender": "Test",
                "recipient": "Test",
                "isFromMe": false
            }
        ]
        """.data(using: .utf8)!
        
        let messages = try await parser.parseMessagesData(jsonData)
        
        XCTAssertEqual(messages.count, 2)
        XCTAssertTrue(messages[0].isFromUser)
        XCTAssertFalse(messages[1].isFromUser)
    }
    
    func testIsFromUserDirectionField() async throws {
        let jsonData = """
        [
            {
                "content": "Test 1",
                "timestamp": 1640995200,
                "sender": "Test",
                "recipient": "Test",
                "direction": "outgoing"
            },
            {
                "content": "Test 2",
                "timestamp": 1640995200,
                "sender": "Test",
                "recipient": "Test",
                "direction": "incoming"
            }
        ]
        """.data(using: .utf8)!
        
        let messages = try await parser.parseMessagesData(jsonData)
        
        XCTAssertEqual(messages.count, 2)
        XCTAssertTrue(messages[0].isFromUser)
        XCTAssertFalse(messages[1].isFromUser)
    }
    
    func testIsFromUserSenderHeuristic() async throws {
        let jsonData = """
        [
            {
                "content": "Test 1",
                "timestamp": 1640995200,
                "sender": "Me",
                "recipient": "Test"
            },
            {
                "content": "Test 2",
                "timestamp": 1640995200,
                "sender": "John Doe",
                "recipient": "Test"
            }
        ]
        """.data(using: .utf8)!
        
        let messages = try await parser.parseMessagesData(jsonData)
        
        XCTAssertEqual(messages.count, 2)
        XCTAssertTrue(messages[0].isFromUser)
        XCTAssertFalse(messages[1].isFromUser)
    }
    
    // MARK: - Malformed Data Handling Tests
    
    func testSkipMalformedMessages() async throws {
        let jsonData = """
        [
            {
                "content": "Valid message",
                "timestamp": 1640995200,
                "sender": "Test",
                "recipient": "Test"
            },
            {
                "timestamp": 1640995200,
                "sender": "Test",
                "recipient": "Test"
            },
            {
                "content": "Another valid message",
                "timestamp": 1640995200,
                "sender": "Test",
                "recipient": "Test"
            }
        ]
        """.data(using: .utf8)!
        
        let messages = try await parser.parseMessagesData(jsonData)
        
        // Should skip the malformed message (missing content) but parse the valid ones
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0].content, "Valid message")
        XCTAssertEqual(messages[1].content, "Another valid message")
    }
    
    func testDefaultValuesForMissingFields() async throws {
        let jsonData = """
        [
            {
                "content": "Minimal message",
                "timestamp": 1640995200
            }
        ]
        """.data(using: .utf8)!
        
        let messages = try await parser.parseMessagesData(jsonData)
        
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].content, "Minimal message")
        XCTAssertEqual(messages[0].sender, "Unknown")
        XCTAssertEqual(messages[0].recipient, "Unknown")
        XCTAssertFalse(messages[0].isFromUser)
    }
    
    // MARK: - Real-world Format Tests
    
    func testAppleMessagesExportFormat() async throws {
        // Simulates actual Apple Messages export format
        let jsonData = """
        {
            "messages": [
                {
                    "messageText": "Hey, can you lend me $50?",
                    "dateTime": "2022-01-01T10:30:00-08:00",
                    "fromHandle": "+1234567890",
                    "chatName": "John Doe",
                    "isFromMe": false
                },
                {
                    "messageText": "Sure, I'll send it now",
                    "dateTime": "2022-01-01T10:32:00-08:00",
                    "fromHandle": "me",
                    "chatName": "John Doe",
                    "isFromMe": true
                }
            ]
        }
        """.data(using: .utf8)!
        
        let messages = try await parser.parseMessagesData(jsonData)
        
        XCTAssertEqual(messages.count, 2)
        
        let firstMessage = messages[0]
        XCTAssertEqual(firstMessage.content, "Hey, can you lend me $50?")
        XCTAssertEqual(firstMessage.sender, "+1234567890")
        XCTAssertEqual(firstMessage.recipient, "John Doe")
        XCTAssertFalse(firstMessage.isFromUser)
        
        let secondMessage = messages[1]
        XCTAssertEqual(secondMessage.content, "Sure, I'll send it now")
        XCTAssertEqual(secondMessage.sender, "me")
        XCTAssertEqual(secondMessage.recipient, "John Doe")
        XCTAssertTrue(secondMessage.isFromUser)
    }
}