import Foundation

/// Handles data received from iOS Shortcuts for message import
public class ShortcutsDataHandler {
    
    // MARK: - Configuration
    
    public struct Configuration {
        public let maxMessagesPerConversation: Int
        public let maxTotalMessages: Int
        public let maxDataSizeBytes: Int
        
        public static let `default` = Configuration(
            maxMessagesPerConversation: 1000,
            maxTotalMessages: 5000,
            maxDataSizeBytes: 10 * 1024 * 1024 // 10MB
        )
        
        public init(maxMessagesPerConversation: Int, maxTotalMessages: Int, maxDataSizeBytes: Int) {
            self.maxMessagesPerConversation = maxMessagesPerConversation
            self.maxTotalMessages = maxTotalMessages
            self.maxDataSizeBytes = maxDataSizeBytes
        }
    }
    
    // MARK: - Performance Tiers
    
    public enum PerformanceTier: String, CaseIterable {
        case quick = "quick"
        case standard = "standard"
        case deep = "deep"
        
        public var messageLimit: Int {
            switch self {
            case .quick: return 200
            case .standard: return 1000
            case .deep: return 5000
            }
        }
        
        public var timeRangeDays: Int {
            switch self {
            case .quick: return 7
            case .standard: return 30
            case .deep: return 90
            }
        }
        
        public var displayName: String {
            switch self {
            case .quick: return "Quick Analysis"
            case .standard: return "Standard Analysis"
            case .deep: return "Deep Analysis"
            }
        }
        
        public var description: String {
            switch self {
            case .quick: return "Fast daily check-ins, recent financial activity (~30 seconds)"
            case .standard: return "Monthly financial behavior assessment (~2-3 minutes)"
            case .deep: return "Comprehensive creditworthiness evaluation (~5-10 minutes)"
            }
        }
    }
    
    // MARK: - Errors
    
    public enum ShortcutDataError: Error, LocalizedError {
        case tooManyMessages(count: Int, limit: Int)
        case dataSizeTooLarge(size: Int, limit: Int)
        case timeoutDuringExtraction
        case insufficientPermissions
        case invalidDataFormat
        case samplingRequired(originalCount: Int, targetCount: Int)
        case emptyDataset
        case invalidJSON
        
        public var errorDescription: String? {
            switch self {
            case .tooManyMessages(let count, let limit):
                return "Too many messages (\(count)). Maximum allowed: \(limit)"
            case .dataSizeTooLarge(let size, let limit):
                return "Data size too large (\(size) bytes). Maximum allowed: \(limit) bytes"
            case .timeoutDuringExtraction:
                return "Timeout occurred during message extraction"
            case .insufficientPermissions:
                return "Insufficient permissions to access Messages data"
            case .invalidDataFormat:
                return "Invalid data format received from Shortcut"
            case .samplingRequired(let original, let target):
                return "Dataset too large (\(original) messages). Sampling to \(target) messages recommended"
            case .emptyDataset:
                return "No messages found in the provided dataset"
            case .invalidJSON:
                return "Invalid JSON format in Shortcut data"
            }
        }
    }
    
    // MARK: - Properties
    
    private let configuration: Configuration
    
    // MARK: - Initialization
    
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
    }
    
    // MARK: - Public Methods
    
    /// Processes data received from iOS Shortcuts
    public func processShortcutData(_ data: Data) throws -> [Message] {
        // Validate data size
        guard data.count <= configuration.maxDataSizeBytes else {
            throw ShortcutDataError.dataSizeTooLarge(size: data.count, limit: configuration.maxDataSizeBytes)
        }
        
        // Parse JSON data
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let shortcutData: ShortcutMessageData
        do {
            shortcutData = try decoder.decode(ShortcutMessageData.self, from: data)
        } catch {
            print("JSON decoding error: \(error)")
            throw ShortcutDataError.invalidJSON
        }
        
        // Validate version compatibility
        do {
            try ShortcutVersionManager.validateDataVersion(shortcutData.version)
        } catch {
            print("Version validation error: \(error)")
            // For now, continue processing even with version mismatch
            // In production, you might want to throw an error here
        }
        
        // Validate message count
        let totalMessages = shortcutData.messages.count
        guard totalMessages > 0 else {
            throw ShortcutDataError.emptyDataset
        }
        
        // Apply smart sampling if needed
        let processedMessages: [Message]
        if totalMessages > configuration.maxTotalMessages {
            processedMessages = try applySampling(to: shortcutData.messages, targetCount: configuration.maxTotalMessages)
        } else {
            processedMessages = shortcutData.messages
        }
        
        return processedMessages
    }
    
    /// Validates incoming Shortcut data without full processing
    public func validateShortcutData(_ data: Data) throws -> ValidationResult {
        guard data.count <= configuration.maxDataSizeBytes else {
            throw ShortcutDataError.dataSizeTooLarge(size: data.count, limit: configuration.maxDataSizeBytes)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let shortcutData = try decoder.decode(ShortcutMessageData.self, from: data)
            let messageCount = shortcutData.messages.count
            
            return ValidationResult(
                isValid: true,
                messageCount: messageCount,
                dataSize: data.count,
                needsSampling: messageCount > configuration.maxTotalMessages,
                recommendedSampleSize: min(messageCount, configuration.maxTotalMessages)
            )
        } catch {
            print("JSON validation error: \(error)")
            throw ShortcutDataError.invalidJSON
        }
    }
    
    /// Applies smart sampling to reduce message count while maintaining quality
    public func applySampling(to messages: [Message], targetCount: Int) throws -> [Message] {
        guard messages.count > targetCount else {
            return messages
        }
        
        // Sort messages by timestamp (newest first)
        let sortedMessages = messages.sorted { $0.timestamp > $1.timestamp }
        
        // Apply smart sampling algorithm
        var sampledMessages: [Message] = []
        
        // 1. Prioritize financial conversations (40% of target)
        let financialCount = Int(Double(targetCount) * 0.4)
        let financialMessages = sortedMessages.filter { containsFinancialKeywords($0.content) }
        sampledMessages.append(contentsOf: Array(financialMessages.prefix(financialCount)))
        
        // 2. Add recent messages (30% of target)
        let recentCount = Int(Double(targetCount) * 0.3)
        let recentMessages = sortedMessages.prefix(recentCount)
        for message in recentMessages {
            if !sampledMessages.contains(where: { $0.id == message.id }) {
                sampledMessages.append(message)
            }
        }
        
        // 3. Ensure conversation diversity (20% of target)
        let diversityCount = Int(Double(targetCount) * 0.2)
        let diverseMessages = sampleAcrossConversations(sortedMessages, targetCount: diversityCount)
        for message in diverseMessages {
            if !sampledMessages.contains(where: { $0.id == message.id }) {
                sampledMessages.append(message)
            }
        }
        
        // 4. Fill remaining slots with temporal distribution (10% of target)
        let remainingSlots = targetCount - sampledMessages.count
        if remainingSlots > 0 {
            let temporalMessages = sampleAcrossTimeRange(sortedMessages, targetCount: remainingSlots)
            for message in temporalMessages {
                if !sampledMessages.contains(where: { $0.id == message.id }) && sampledMessages.count < targetCount {
                    sampledMessages.append(message)
                }
            }
        }
        
        // Ensure we don't exceed target count
        return Array(sampledMessages.prefix(targetCount))
    }
    
    // MARK: - Private Methods
    
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
    
    private func sampleAcrossConversations(_ messages: [Message], targetCount: Int) -> [Message] {
        // Group messages by conversation (sender-recipient pair)
        let conversations = Dictionary(grouping: messages) { message in
            let participants = [message.sender, message.recipient].sorted()
            return participants.joined(separator: "-")
        }
        
        var sampledMessages: [Message] = []
        let messagesPerConversation = max(1, targetCount / conversations.count)
        
        for (_, conversationMessages) in conversations {
            let sample = Array(conversationMessages.prefix(messagesPerConversation))
            sampledMessages.append(contentsOf: sample)
            
            if sampledMessages.count >= targetCount {
                break
            }
        }
        
        return Array(sampledMessages.prefix(targetCount))
    }
    
    private func sampleAcrossTimeRange(_ messages: [Message], targetCount: Int) -> [Message] {
        guard !messages.isEmpty else { return [] }
        
        let sortedMessages = messages.sorted { $0.timestamp < $1.timestamp }
        let timeSpan = sortedMessages.last!.timestamp.timeIntervalSince(sortedMessages.first!.timestamp)
        let interval = timeSpan / Double(targetCount)
        
        var sampledMessages: [Message] = []
        var currentTime = sortedMessages.first!.timestamp
        
        for _ in 0..<targetCount {
            // Find the message closest to the current time
            if let closestMessage = sortedMessages.min(by: { abs($0.timestamp.timeIntervalSince(currentTime)) < abs($1.timestamp.timeIntervalSince(currentTime)) }) {
                sampledMessages.append(closestMessage)
            }
            currentTime.addTimeInterval(interval)
        }
        
        return sampledMessages
    }
}

// MARK: - Supporting Types

/// Data structure for messages received from iOS Shortcuts
public struct ShortcutMessageData: Codable {
    public let messages: [Message]
    public let extractionDate: Date
    public let performanceTier: String
    public let version: String
    
    public init(messages: [Message], extractionDate: Date, performanceTier: String, version: String) {
        self.messages = messages
        self.extractionDate = extractionDate
        self.performanceTier = performanceTier
        self.version = version
    }
}

/// Result of data validation
public struct ValidationResult {
    public let isValid: Bool
    public let messageCount: Int
    public let dataSize: Int
    public let needsSampling: Bool
    public let recommendedSampleSize: Int
    
    public init(isValid: Bool, messageCount: Int, dataSize: Int, needsSampling: Bool, recommendedSampleSize: Int) {
        self.isValid = isValid
        self.messageCount = messageCount
        self.dataSize = dataSize
        self.needsSampling = needsSampling
        self.recommendedSampleSize = recommendedSampleSize
    }
}