import Foundation

/// Represents a single message from iMessages
struct Message: Codable, Identifiable, Equatable {
    let id: UUID
    let content: String
    let timestamp: Date
    let sender: String
    let recipient: String
    let isFromUser: Bool
    
    init(id: UUID = UUID(), content: String, timestamp: Date, sender: String, recipient: String, isFromUser: Bool) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.sender = sender
        self.recipient = recipient
        self.isFromUser = isFromUser
    }
    
    /// Validates that the message has required fields
    func isValid() -> Bool {
        return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !sender.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Returns a sanitized version of the message content for processing
    func sanitizedContent() -> String {
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}