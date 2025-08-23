import Foundation

/// Represents a single message from iMessages
public struct Message: Codable, Identifiable, Equatable {
    public let id: UUID
    public let content: String
    public let timestamp: Date
    public let sender: String
    public let recipient: String
    public let isFromUser: Bool
    
    public init(id: UUID = UUID(), content: String, timestamp: Date, sender: String, recipient: String, isFromUser: Bool) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.sender = sender
        self.recipient = recipient
        self.isFromUser = isFromUser
    }
    
    /// Validates that the message has required fields
    public func isValid() -> Bool {
        return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !sender.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Returns a sanitized version of the message content for processing
    public func sanitizedContent() -> String {
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}