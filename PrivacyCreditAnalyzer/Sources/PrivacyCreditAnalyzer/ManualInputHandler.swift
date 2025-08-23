import Foundation

/// Handler for converting manual text input into Message objects
public class ManualInputHandler {
    
    public init() {}
    
    /// Errors that can occur during manual input processing
    public enum InputError: Error, LocalizedError {
        case emptyInput
        case noValidMessages
        case invalidFormat
        
        public var errorDescription: String? {
            switch self {
            case .emptyInput:
                return "Input text is empty"
            case .noValidMessages:
                return "No valid messages found in the input text"
            case .invalidFormat:
                return "Input text format is not recognized"
            }
        }
    }
    
    /// Converts raw text input into Message objects
    /// - Parameter text: Raw text input containing messages
    /// - Returns: Array of parsed Message objects
    /// - Throws: InputError if parsing fails
    public func parseManualInput(_ text: String) throws -> [Message] {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanedText.isEmpty else {
            throw InputError.emptyInput
        }
        
        // Try different parsing strategies
        var messages: [Message] = []
        
        // Strategy 1: Try to parse as structured conversation format
        if let structuredMessages = try? parseStructuredConversation(cleanedText) {
            messages = structuredMessages
        }
        // Strategy 2: Try to parse as timestamped messages
        else if let timestampedMessages = try? parseTimestampedMessages(cleanedText) {
            messages = timestampedMessages
        }
        // Strategy 3: Parse as simple line-by-line messages
        else {
            messages = parseSimpleMessages(cleanedText)
        }
        
        guard !messages.isEmpty else {
            throw InputError.noValidMessages
        }
        
        return messages
    }
    
    /// Parses structured conversation format like:
    /// "John: Hello there!"
    /// "Me: Hi John!"
    /// "John: How are you?"
    private func parseStructuredConversation(_ text: String) throws -> [Message] {
        let lines = text.components(separatedBy: .newlines)
        var messages: [Message] = []
        let currentTimestamp = Date()
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines
            guard !trimmedLine.isEmpty else { continue }
            
            // First, try to extract timestamp if present
            var workingLine = trimmedLine
            var messageTimestamp = currentTimestamp.addingTimeInterval(TimeInterval(index * 60))
            
            if let timestampMatch = extractTimestampFromLine(trimmedLine) {
                workingLine = timestampMatch.remainingText
                messageTimestamp = timestampMatch.timestamp
            }
            
            // Look for pattern: "Speaker: Message content"
            if let colonRange = workingLine.range(of: ":") {
                let speaker = String(workingLine[..<colonRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let content = String(workingLine[colonRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard !speaker.isEmpty && !content.isEmpty else { continue }
                
                let isFromUser = isUserSpeaker(speaker)
                let recipient = isFromUser ? "Unknown" : "Me"
                
                let message = Message(
                    content: content,
                    timestamp: messageTimestamp,
                    sender: speaker,
                    recipient: recipient,
                    isFromUser: isFromUser
                )
                
                messages.append(message)
            }
        }
        
        guard !messages.isEmpty else {
            throw InputError.noValidMessages
        }
        
        return messages
    }
    
    /// Parses timestamped messages format like:
    /// "[2022-01-01 10:30] John: Hello there!"
    /// "[2022-01-01 10:32] Me: Hi John!"
    private func parseTimestampedMessages(_ text: String) throws -> [Message] {
        let lines = text.components(separatedBy: .newlines)
        var messages: [Message] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines
            guard !trimmedLine.isEmpty else { continue }
            
            // Look for pattern: "[timestamp] Speaker: Message content"
            if let timestampMatch = extractTimestampFromLine(trimmedLine) {
                let remainingText = timestampMatch.remainingText
                
                // Now look for speaker pattern
                if let colonRange = remainingText.range(of: ":") {
                    let speaker = String(remainingText[..<colonRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let content = String(remainingText[colonRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    guard !speaker.isEmpty && !content.isEmpty else { continue }
                    
                    let isFromUser = isUserSpeaker(speaker)
                    let recipient = isFromUser ? "Unknown" : "Me"
                    
                    let message = Message(
                        content: content,
                        timestamp: timestampMatch.timestamp,
                        sender: speaker,
                        recipient: recipient,
                        isFromUser: isFromUser
                    )
                    
                    messages.append(message)
                }
            }
        }
        
        guard !messages.isEmpty else {
            throw InputError.noValidMessages
        }
        
        return messages
    }
    
    /// Parses simple messages where each line is a separate message
    /// Alternates between user and other person
    private func parseSimpleMessages(_ text: String) -> [Message] {
        let lines = text.components(separatedBy: .newlines)
        var messages: [Message] = []
        var currentTimestamp = Date()
        var messageIndex = 0
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines or lines that are just punctuation
            guard !trimmedLine.isEmpty && trimmedLine.count > 1 else { continue }
            
            // Skip lines that are just colons or other single characters
            if trimmedLine == ":" || trimmedLine.count == 1 {
                continue
            }
            
            // Alternate between user and other person
            let isFromUser = messageIndex % 2 == 0
            let sender = isFromUser ? "Me" : "Other"
            let recipient = isFromUser ? "Other" : "Me"
            
            // Increment timestamp by 1 minute for each message
            currentTimestamp = currentTimestamp.addingTimeInterval(TimeInterval(messageIndex * 60))
            
            let message = Message(
                content: trimmedLine,
                timestamp: currentTimestamp,
                sender: sender,
                recipient: recipient,
                isFromUser: isFromUser
            )
            
            messages.append(message)
            messageIndex += 1
        }
        
        return messages
    }
    
    /// Extracts timestamp from a line that starts with [timestamp]
    private func extractTimestampFromLine(_ line: String) -> (timestamp: Date, remainingText: String)? {
        // Look for patterns like [2022-01-01 10:30], [10:30], [Jan 1, 2022 10:30 AM], etc.
        let timestampPatterns = [
            "^\\[(\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2})\\]\\s*",   // [2022-01-01 10:30:45]
            "^\\[(\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2})\\]\\s*",           // [2022-01-01 10:30]
            "^\\[(\\d{1,2}/\\d{1,2}/\\d{2,4}, \\d{1,2}:\\d{2}:\\d{2} [AP]M)\\]\\s*", // [1/1/22, 10:30:15 AM]
            "^\\[(\\d{2}:\\d{2}:\\d{2})\\]\\s*",                        // [10:30:45]
            "^\\[(\\d{2}:\\d{2})\\]\\s*",                               // [10:30]
            "^\\[([^\\]]+)\\]\\s*"                                      // [any text]
        ]
        
        for pattern in timestampPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                
                let timestampRange = Range(match.range(at: 1), in: line)!
                let timestampString = String(line[timestampRange])
                
                if let timestamp = parseTimestampString(timestampString) {
                    let remainingRange = Range(NSRange(location: match.range.upperBound, length: line.count - match.range.upperBound), in: line)!
                    let remainingText = String(line[remainingRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    return (timestamp: timestamp, remainingText: remainingText)
                }
            }
        }
        
        return nil
    }
    
    /// Parses various timestamp string formats
    private func parseTimestampString(_ timestampString: String) -> Date? {
        let formatters = [
            createDateFormatter("yyyy-MM-dd HH:mm:ss"),
            createDateFormatter("yyyy-MM-dd HH:mm"),
            createDateFormatter("M/d/yy, h:mm:ss a"),      // WhatsApp format: 1/1/22, 10:30:15 AM
            createDateFormatter("MM/dd/yy, h:mm:ss a"),    // WhatsApp format: 01/01/22, 10:30:15 AM
            createDateFormatter("HH:mm:ss"),
            createDateFormatter("HH:mm"),
            createDateFormatter("MMM d, yyyy HH:mm:ss"),
            createDateFormatter("MMM d, yyyy HH:mm"),
            createDateFormatter("MM/dd/yyyy HH:mm:ss"),
            createDateFormatter("MM/dd/yyyy HH:mm"),
            createDateFormatter("dd/MM/yyyy HH:mm:ss"),
            createDateFormatter("dd/MM/yyyy HH:mm")
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: timestampString) {
                // For time-only formats, use today's date
                if timestampString.contains(":") && !timestampString.contains("-") && !timestampString.contains("/") && !timestampString.contains(",") {
                    let calendar = Calendar.current
                    let today = Date()
                    let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: date)
                    if let combinedDate = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                                       minute: timeComponents.minute ?? 0,
                                                       second: timeComponents.second ?? 0,
                                                       of: today) {
                        return combinedDate
                    }
                }
                return date
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
    
    /// Determines if a speaker name represents the user
    private func isUserSpeaker(_ speaker: String) -> Bool {
        let speakerLower = speaker.lowercased()
        let userIndicators = ["me", "i", "myself", "self", "you", "user"]
        
        return userIndicators.contains(speakerLower) || speakerLower.hasPrefix("me ")
    }
    
    /// Preprocesses text to clean up common formatting issues
    public func preprocessText(_ text: String) -> String {
        var processed = text
        
        // Normalize line endings
        processed = processed.replacingOccurrences(of: "\r\n", with: "\n")
        processed = processed.replacingOccurrences(of: "\r", with: "\n")
        
        // Remove excessive whitespace within lines (but preserve line structure)
        let lines = processed.components(separatedBy: "\n")
        let cleanedLines = lines.map { line in
            line.replacingOccurrences(of: "[ \t]+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        processed = cleanedLines.joined(separator: "\n")
        
        // Remove excessive newlines (more than 2 consecutive)
        processed = processed.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        
        // Trim leading and trailing whitespace
        processed = processed.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return processed
    }
    
    /// Detects message boundaries in continuous text
    public func detectMessageBoundaries(_ text: String) -> [String] {
        let preprocessed = preprocessText(text)
        
        // Strategy 1: Split by clear conversation markers
        let conversationMarkers = [
            "\\n[A-Za-z]+:",           // Name followed by colon
            "\\n\\[[^\\]]+\\]",        // Timestamp in brackets
            "\\n\\d{1,2}:\\d{2}",      // Time format
            "\\n[A-Za-z]+ says:",     // "Name says:"
            "\\n[A-Za-z]+ wrote:"     // "Name wrote:"
        ]
        
        for pattern in conversationMarkers {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: preprocessed, options: [], range: NSRange(location: 0, length: preprocessed.count))
                
                if matches.count > 1 {
                    // Split at these boundaries
                    var boundaries: [String] = []
                    var lastIndex = 0
                    
                    for match in matches {
                        if match.range.location > lastIndex {
                            let range = Range(NSRange(location: lastIndex, length: match.range.location - lastIndex), in: preprocessed)!
                            let segment = String(preprocessed[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                            if !segment.isEmpty {
                                boundaries.append(segment)
                            }
                        }
                        lastIndex = match.range.location
                    }
                    
                    // Add the last segment
                    if lastIndex < preprocessed.count {
                        let range = Range(NSRange(location: lastIndex, length: preprocessed.count - lastIndex), in: preprocessed)!
                        let segment = String(preprocessed[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                        if !segment.isEmpty {
                            boundaries.append(segment)
                        }
                    }
                    
                    return boundaries
                }
            }
        }
        
        // Strategy 2: Split by double newlines (paragraph breaks)
        let paragraphs = preprocessed.components(separatedBy: "\n\n")
        if paragraphs.count > 1 {
            return paragraphs.compactMap { paragraph in
                let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
        }
        
        // Strategy 3: Split by single newlines if they seem to separate messages
        let lines = preprocessed.components(separatedBy: "\n")
        if lines.count > 1 {
            return lines.compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
        }
        
        // Fallback: Return the entire text as one message
        return [preprocessed]
    }
}