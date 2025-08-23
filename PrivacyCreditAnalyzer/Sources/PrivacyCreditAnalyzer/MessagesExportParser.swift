import Foundation

/// Parser for Messages Export JSON files from iOS/macOS Messages app
public class MessagesExportParser {
    
    public init() {}
    
    /// Errors that can occur during Messages Export parsing
    public enum ParseError: Error, LocalizedError {
        case invalidJSON
        case missingRequiredFields(String)
        case invalidDateFormat(String)
        case emptyFile
        case unsupportedFormat
        
        public var errorDescription: String? {
            switch self {
            case .invalidJSON:
                return "The file contains invalid JSON data"
            case .missingRequiredFields(let field):
                return "Missing required field: \(field)"
            case .invalidDateFormat(let date):
                return "Invalid date format: \(date)"
            case .emptyFile:
                return "The file is empty or contains no messages"
            case .unsupportedFormat:
                return "Unsupported Messages Export format"
            }
        }
    }
    
    /// Parses Messages Export JSON file and returns array of Message objects
    /// - Parameter url: URL to the Messages Export JSON file
    /// - Returns: Array of parsed Message objects
    /// - Throws: ParseError if parsing fails
    public func parseMessagesExport(from url: URL) async throws -> [Message] {
        guard url.startAccessingSecurityScopedResource() else {
            throw ParseError.unsupportedFormat
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ParseError.invalidJSON
        }
        
        guard !data.isEmpty else {
            throw ParseError.emptyFile
        }
        
        return try await parseMessagesData(data)
    }
    
    /// Parses Messages Export JSON data and returns array of Message objects
    /// - Parameter data: JSON data from Messages Export
    /// - Returns: Array of parsed Message objects
    /// - Throws: ParseError if parsing fails
    public func parseMessagesData(_ data: Data) async throws -> [Message] {
        guard !data.isEmpty else {
            throw ParseError.emptyFile
        }
        
        let json: Any
        do {
            json = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            throw ParseError.invalidJSON
        }
        
        // Handle different possible JSON structures from Messages Export
        if let messagesArray = json as? [[String: Any]] {
            // Direct array of message objects
            return try parseMessageArray(messagesArray)
        } else if let rootObject = json as? [String: Any] {
            // Root object containing messages array
            if let messagesArray = rootObject["messages"] as? [[String: Any]] {
                return try parseMessageArray(messagesArray)
            } else if let messagesArray = rootObject["data"] as? [[String: Any]] {
                return try parseMessageArray(messagesArray)
            } else {
                throw ParseError.unsupportedFormat
            }
        } else {
            throw ParseError.unsupportedFormat
        }
    }
    
    /// Parses an array of message dictionaries
    /// - Parameter messagesArray: Array of message dictionaries
    /// - Returns: Array of parsed Message objects
    /// - Throws: ParseError if parsing fails
    private func parseMessageArray(_ messagesArray: [[String: Any]]) throws -> [Message] {
        guard !messagesArray.isEmpty else {
            throw ParseError.emptyFile
        }
        
        var messages: [Message] = []
        
        for (index, messageDict) in messagesArray.enumerated() {
            do {
                let message = try parseMessageDictionary(messageDict)
                messages.append(message)
            } catch {
                // Log parsing error but continue with other messages
                print("Warning: Failed to parse message at index \(index): \(error)")
                continue
            }
        }
        
        guard !messages.isEmpty else {
            throw ParseError.emptyFile
        }
        
        return messages
    }
    
    /// Parses a single message dictionary into a Message object
    /// - Parameter messageDict: Dictionary containing message data
    /// - Returns: Parsed Message object
    /// - Throws: ParseError if required fields are missing or invalid
    private func parseMessageDictionary(_ messageDict: [String: Any]) throws -> Message {
        // Extract content (try multiple possible field names)
        guard let content = extractContent(from: messageDict) else {
            throw ParseError.missingRequiredFields("content/text/body")
        }
        
        // Extract timestamp (try multiple possible field names and formats)
        let timestamp = try extractTimestamp(from: messageDict)
        
        // Extract sender information
        let sender = extractSender(from: messageDict)
        
        // Extract recipient information
        let recipient = extractRecipient(from: messageDict)
        
        // Determine if message is from user
        let isFromUser = extractIsFromUser(from: messageDict, sender: sender)
        
        return Message(
            content: content,
            timestamp: timestamp,
            sender: sender,
            recipient: recipient,
            isFromUser: isFromUser
        )
    }
    
    /// Extracts message content from various possible field names
    private func extractContent(from dict: [String: Any]) -> String? {
        let possibleKeys = ["content", "text", "body", "message", "messageText"]
        
        for key in possibleKeys {
            if let content = dict[key] as? String, !content.isEmpty {
                return content
            }
        }
        
        return nil
    }
    
    /// Extracts timestamp from various possible field names and formats
    private func extractTimestamp(from dict: [String: Any]) throws -> Date {
        let possibleKeys = ["timestamp", "date", "time", "dateTime", "created_at", "sent_at"]
        
        for key in possibleKeys {
            if let timestampValue = dict[key] {
                if let date = parseTimestampValue(timestampValue) {
                    return date
                }
            }
        }
        
        // If no timestamp found, use current date as fallback
        return Date()
    }
    
    /// Parses various timestamp formats
    private func parseTimestampValue(_ value: Any) -> Date? {
        if let timestamp = value as? TimeInterval {
            // Unix timestamp (seconds or milliseconds)
            if timestamp > 1_000_000_000_000 {
                // Milliseconds
                return Date(timeIntervalSince1970: timestamp / 1000)
            } else {
                // Seconds
                return Date(timeIntervalSince1970: timestamp)
            }
        } else if let timestampString = value as? String {
            return parseTimestampString(timestampString)
        } else if let timestamp = value as? Double {
            // Handle as Unix timestamp
            if timestamp > 1_000_000_000_000 {
                return Date(timeIntervalSince1970: timestamp / 1000)
            } else {
                return Date(timeIntervalSince1970: timestamp)
            }
        }
        
        return nil
    }
    
    /// Parses timestamp strings in various formats
    private func parseTimestampString(_ timestampString: String) -> Date? {
        let formatters = [
            // ISO 8601 formats
            ISO8601DateFormatter(),
            // Custom formats
            createDateFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSZ"),
            createDateFormatter("yyyy-MM-dd'T'HH:mm:ssZ"),
            createDateFormatter("yyyy-MM-dd HH:mm:ss"),
            createDateFormatter("MM/dd/yyyy HH:mm:ss"),
            createDateFormatter("dd/MM/yyyy HH:mm:ss"),
            createDateFormatter("yyyy-MM-dd"),
            createDateFormatter("MM/dd/yyyy"),
            createDateFormatter("dd/MM/yyyy")
        ]
        
        for formatter in formatters {
            if let isoFormatter = formatter as? ISO8601DateFormatter {
                if let date = isoFormatter.date(from: timestampString) {
                    return date
                }
            } else if let dateFormatter = formatter as? DateFormatter {
                if let date = dateFormatter.date(from: timestampString) {
                    return date
                }
            }
        }
        
        return nil
    }
    
    /// Creates a DateFormatter with the specified format
    private func createDateFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    /// Extracts sender information
    private func extractSender(from dict: [String: Any]) -> String {
        let possibleKeys = ["sender", "from", "fromHandle", "handle", "phoneNumber", "email"]
        
        for key in possibleKeys {
            if let sender = dict[key] as? String, !sender.isEmpty {
                return sender
            }
        }
        
        return "Unknown"
    }
    
    /// Extracts recipient information
    private func extractRecipient(from dict: [String: Any]) -> String {
        let possibleKeys = ["recipient", "to", "toHandle", "chat", "chatName", "groupName"]
        
        for key in possibleKeys {
            if let recipient = dict[key] as? String, !recipient.isEmpty {
                return recipient
            }
        }
        
        return "Unknown"
    }
    
    /// Determines if message is from the user
    private func extractIsFromUser(from dict: [String: Any], sender: String) -> Bool {
        // Check explicit fields first
        if let isFromUser = dict["isFromUser"] as? Bool {
            return isFromUser
        }
        
        if let isFromMe = dict["isFromMe"] as? Bool {
            return isFromMe
        }
        
        if let direction = dict["direction"] as? String {
            return direction.lowercased() == "outgoing" || direction.lowercased() == "sent"
        }
        
        // Heuristic: if sender contains "Me" or similar indicators
        let senderLower = sender.lowercased()
        return senderLower.contains("me") || senderLower.contains("self") || senderLower == "you"
    }
}