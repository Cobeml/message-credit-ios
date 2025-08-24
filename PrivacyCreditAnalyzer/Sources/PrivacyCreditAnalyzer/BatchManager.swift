import Foundation

/// Manages intelligent batching of messages for scalable MLX processing
public class BatchManager {
    
    // MARK: - Configuration
    
    public struct BatchConfiguration {
        let targetBatchSize: Int
        let maxTokensPerBatch: Int
        let overlapPercentage: Double
        let minBatchSize: Int
        let maxBatchSize: Int
        
        public static let `default` = BatchConfiguration(
            targetBatchSize: 80,
            maxTokensPerBatch: 3500,
            overlapPercentage: 0.25,
            minBatchSize: 10,
            maxBatchSize: 150
        )
        
        public init(targetBatchSize: Int = 80, maxTokensPerBatch: Int = 3500, overlapPercentage: Double = 0.25, minBatchSize: Int = 10, maxBatchSize: Int = 150) {
            self.targetBatchSize = targetBatchSize
            self.maxTokensPerBatch = maxTokensPerBatch
            self.overlapPercentage = max(0.0, min(0.5, overlapPercentage))
            self.minBatchSize = minBatchSize
            self.maxBatchSize = maxBatchSize
        }
    }
    
    // MARK: - Properties
    
    private let configuration: BatchConfiguration
    private let tokenEstimator: TokenEstimator
    
    public init(configuration: BatchConfiguration = .default) {
        self.configuration = configuration
        self.tokenEstimator = TokenEstimator()
    }
    
    // MARK: - Public Interface
    
    /// Creates batches from messages with intelligent sliding window overlap
    public func createBatches(from messages: [Message]) -> [MessageBatch] {
        guard !messages.isEmpty else { return [] }
        
        // Sort messages chronologically for temporal continuity
        let sortedMessages = messages.sorted { $0.timestamp < $1.timestamp }
        
        // If small dataset, create single batch
        if sortedMessages.count <= configuration.maxBatchSize {
            let batch = MessageBatch(
                id: UUID(),
                batchIndex: 0,
                totalBatches: 1,
                messages: sortedMessages,
                metadata: createBatchMetadata(for: sortedMessages, index: 0, total: 1)
            )
            return [batch]
        }
        
        // Create overlapping batches for larger datasets
        return createOverlappingBatches(from: sortedMessages)
    }
    
    /// Validates batch quality and characteristics
    public func validateBatch(_ batch: MessageBatch) -> BatchValidationResult {
        var warnings: [String] = []
        var errors: [String] = []
        
        // Check minimum batch size
        if batch.messages.count < configuration.minBatchSize {
            errors.append("Batch size (\(batch.messages.count)) below minimum (\(configuration.minBatchSize))")
        }
        
        // Check message diversity
        let uniqueSenders = Set(batch.messages.map { $0.isFromUser ? "user" : $0.sender })
        if uniqueSenders.count < 2 {
            warnings.append("Low sender diversity - only \(uniqueSenders.count) unique sender(s)")
        }
        
        // Check temporal span
        if let firstMessage = batch.messages.first, let lastMessage = batch.messages.last {
            let timeSpan = lastMessage.timestamp.timeIntervalSince(firstMessage.timestamp)
            if timeSpan < 3600 { // Less than 1 hour
                warnings.append("Short temporal span (\(String(format: "%.1f", timeSpan / 3600)) hours)")
            }
        }
        
        // Check content diversity
        let totalCharacters = batch.messages.map(\.content.count).reduce(0, +)
        let averageLength = Double(totalCharacters) / Double(batch.messages.count)
        if averageLength < 10 {
            warnings.append("Very short average message length (\(String(format: "%.1f", averageLength)) chars)")
        }
        
        // Estimate token usage
        let estimatedTokens = tokenEstimator.estimateTokens(for: batch.messages)
        if estimatedTokens > configuration.maxTokensPerBatch {
            errors.append("Estimated tokens (\(estimatedTokens)) exceed limit (\(configuration.maxTokensPerBatch))")
        }
        
        let isValid = errors.isEmpty
        let quality = calculateBatchQuality(batch)
        
        return BatchValidationResult(
            isValid: isValid,
            quality: quality,
            warnings: warnings,
            errors: errors,
            estimatedTokens: estimatedTokens
        )
    }
    
    /// Calculates quality score for a batch (0.0 to 1.0)
    public func calculateBatchQuality(_ batch: MessageBatch) -> Double {
        var qualityFactors: [Double] = []
        
        // Size appropriateness (target around configured batch size)
        let sizeScore = 1.0 - abs(Double(batch.messages.count - configuration.targetBatchSize)) / Double(configuration.targetBatchSize)
        qualityFactors.append(max(0.0, min(1.0, sizeScore)))
        
        // Sender diversity
        let uniqueSenders = Set(batch.messages.map { $0.isFromUser ? "user" : $0.sender })
        let diversityScore = min(1.0, Double(uniqueSenders.count) / 5.0) // Normalize to max 5 senders
        qualityFactors.append(diversityScore)
        
        // Content richness
        let totalCharacters = batch.messages.map(\.content.count).reduce(0, +)
        let richnessScore = min(1.0, Double(totalCharacters) / 5000.0) // Normalize to 5K chars
        qualityFactors.append(richnessScore)
        
        // Temporal distribution
        if batch.messages.count > 1 {
            let timestamps = batch.messages.map(\.timestamp).sorted()
            let timeSpan = timestamps.last!.timeIntervalSince(timestamps.first!)
            let distributionScore = min(1.0, timeSpan / (24 * 3600)) // Normalize to 24 hours
            qualityFactors.append(distributionScore)
        } else {
            qualityFactors.append(0.5) // Neutral for single message
        }
        
        // Average the quality factors
        return qualityFactors.reduce(0, +) / Double(qualityFactors.count)
    }
}

// MARK: - Private Methods

extension BatchManager {
    
    private func createOverlappingBatches(from messages: [Message]) -> [MessageBatch] {
        var batches: [MessageBatch] = []
        var currentIndex = 0
        let totalMessages = messages.count
        
        // Calculate overlap size
        let overlapSize = Int(Double(configuration.targetBatchSize) * configuration.overlapPercentage)
        let stepSize = configuration.targetBatchSize - overlapSize
        
        var batchIndex = 0
        
        while currentIndex < totalMessages {
            let endIndex = min(currentIndex + configuration.targetBatchSize, totalMessages)
            let batchMessages = Array(messages[currentIndex..<endIndex])
            
            // Skip if batch is too small (unless it's the last batch)
            if batchMessages.count < configuration.minBatchSize && endIndex < totalMessages {
                currentIndex += stepSize
                continue
            }
            
            // Adjust batch size based on token estimation
            let adjustedMessages = adjustBatchForTokens(batchMessages)
            
            if !adjustedMessages.isEmpty {
                let batch = MessageBatch(
                    id: UUID(),
                    batchIndex: batchIndex,
                    totalBatches: estimateTotalBatches(messageCount: totalMessages),
                    messages: adjustedMessages,
                    metadata: createBatchMetadata(for: adjustedMessages, index: batchIndex, total: estimateTotalBatches(messageCount: totalMessages))
                )
                
                batches.append(batch)
                batchIndex += 1
            }
            
            // Move to next batch position
            if endIndex >= totalMessages {
                break
            }
            
            currentIndex += stepSize
        }
        
        // Update total batch count in all batches
        for i in 0..<batches.count {
            batches[i].updateTotalBatches(batches.count)
        }
        
        return batches
    }
    
    private func adjustBatchForTokens(_ messages: [Message]) -> [Message] {
        let estimatedTokens = tokenEstimator.estimateTokens(for: messages)
        
        if estimatedTokens <= configuration.maxTokensPerBatch {
            return messages
        }
        
        // Binary search to find optimal message count
        var low = configuration.minBatchSize
        var high = messages.count
        var bestMessages = Array(messages.prefix(configuration.minBatchSize))
        
        while low <= high {
            let mid = (low + high) / 2
            let candidateMessages = Array(messages.prefix(mid))
            let tokens = tokenEstimator.estimateTokens(for: candidateMessages)
            
            if tokens <= configuration.maxTokensPerBatch {
                bestMessages = candidateMessages
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        
        return bestMessages
    }
    
    private func estimateTotalBatches(messageCount: Int) -> Int {
        if messageCount <= configuration.maxBatchSize {
            return 1
        }
        
        let overlapSize = Int(Double(configuration.targetBatchSize) * configuration.overlapPercentage)
        let stepSize = configuration.targetBatchSize - overlapSize
        
        return max(1, Int(ceil(Double(messageCount - overlapSize) / Double(stepSize))))
    }
    
    private func createBatchMetadata(for messages: [Message], index: Int, total: Int) -> BatchMetadata {
        guard !messages.isEmpty else {
            return BatchMetadata(
                batchIndex: index,
                totalBatches: total,
                messageCount: 0,
                startDate: Date(),
                endDate: Date(),
                estimatedTokens: 0,
                senderCount: 0,
                averageMessageLength: 0.0,
                financialKeywordCount: 0,
                relationshipKeywordCount: 0
            )
        }
        
        let startDate = messages.first!.timestamp
        let endDate = messages.last!.timestamp
        let estimatedTokens = tokenEstimator.estimateTokens(for: messages)
        let uniqueSenders = Set(messages.map { $0.isFromUser ? "user" : $0.sender })
        
        let totalCharacters = messages.map(\.content.count).reduce(0, +)
        let averageLength = Double(totalCharacters) / Double(messages.count)
        
        // Count financial and relationship keywords
        let financialKeywords = ["money", "payment", "pay", "bill", "cost", "budget", "save", "loan", "debt", "credit", "bank", "financial", "rent", "mortgage", "insurance", "salary", "income"]
        let relationshipKeywords = ["love", "care", "miss", "relationship", "family", "friend", "support", "trust", "honest", "commitment", "emotion", "feel", "heart"]
        
        let financialCount = messages.reduce(0) { count, message in
            let content = message.content.lowercased()
            return count + financialKeywords.filter { content.contains($0) }.count
        }
        
        let relationshipCount = messages.reduce(0) { count, message in
            let content = message.content.lowercased()
            return count + relationshipKeywords.filter { content.contains($0) }.count
        }
        
        return BatchMetadata(
            batchIndex: index,
            totalBatches: total,
            messageCount: messages.count,
            startDate: startDate,
            endDate: endDate,
            estimatedTokens: estimatedTokens,
            senderCount: uniqueSenders.count,
            averageMessageLength: averageLength,
            financialKeywordCount: financialCount,
            relationshipKeywordCount: relationshipCount
        )
    }
}

// MARK: - Supporting Types

/// Represents a batch of messages for processing
public struct MessageBatch {
    public let id: UUID
    public let batchIndex: Int
    public private(set) var totalBatches: Int
    public let messages: [Message]
    public let metadata: BatchMetadata
    
    public init(id: UUID, batchIndex: Int, totalBatches: Int, messages: [Message], metadata: BatchMetadata) {
        self.id = id
        self.batchIndex = batchIndex
        self.totalBatches = totalBatches
        self.messages = messages
        self.metadata = metadata
    }
    
    mutating func updateTotalBatches(_ total: Int) {
        self.totalBatches = total
    }
    
    /// Returns the percentage progress through all batches
    public var progressPercentage: Double {
        guard totalBatches > 0 else { return 0.0 }
        return Double(batchIndex) / Double(totalBatches)
    }
    
    /// Returns a summary description of the batch
    public var summary: String {
        return """
        Batch \(batchIndex + 1)/\(totalBatches):
        - Messages: \(messages.count)
        - Date Range: \(DateFormatter.batchShortDate.string(from: metadata.startDate)) - \(DateFormatter.batchShortDate.string(from: metadata.endDate))
        - Estimated Tokens: \(metadata.estimatedTokens)
        - Senders: \(metadata.senderCount)
        - Financial Keywords: \(metadata.financialKeywordCount)
        - Relationship Keywords: \(metadata.relationshipKeywordCount)
        """
    }
}

/// Metadata about a batch for analysis and quality assessment
public struct BatchMetadata {
    public let batchIndex: Int
    public let totalBatches: Int
    public let messageCount: Int
    public let startDate: Date
    public let endDate: Date
    public let estimatedTokens: Int
    public let senderCount: Int
    public let averageMessageLength: Double
    public let financialKeywordCount: Int
    public let relationshipKeywordCount: Int
    
    /// Time span covered by this batch in hours
    public var timeSpanHours: Double {
        return endDate.timeIntervalSince(startDate) / 3600.0
    }
    
    /// Keyword density as a percentage of total messages
    public var keywordDensity: Double {
        guard messageCount > 0 else { return 0.0 }
        return Double(financialKeywordCount + relationshipKeywordCount) / Double(messageCount) * 100.0
    }
}

/// Result of batch validation
public struct BatchValidationResult {
    public let isValid: Bool
    public let quality: Double // 0.0 to 1.0
    public let warnings: [String]
    public let errors: [String]
    public let estimatedTokens: Int
    
    public var qualityDescription: String {
        switch quality {
        case 0.8...1.0: return "Excellent"
        case 0.6..<0.8: return "Good"
        case 0.4..<0.6: return "Fair"
        case 0.2..<0.4: return "Poor"
        default: return "Very Poor"
        }
    }
}

/// Estimates token usage for messages
private class TokenEstimator {
    
    /// Rough estimation: 4 characters per token for English text
    private let charactersPerToken: Double = 4.0
    
    /// Estimates total tokens needed for a list of messages including formatting
    func estimateTokens(for messages: [Message]) -> Int {
        let messageContent = messages.map { message in
            let sender = message.isFromUser ? "User" : message.sender
            let timestamp = DateFormatter.batchTimestampFormatter.string(from: message.timestamp)
            return "[\(timestamp)] \(sender): \(message.content)"
        }.joined(separator: "\n")
        
        // Add overhead for prompt structure (roughly 500 tokens)
        let contentTokens = Int(Double(messageContent.count) / charactersPerToken)
        let promptOverhead = 500
        
        return contentTokens + promptOverhead
    }
}

// MARK: - Extensions

private extension DateFormatter {
    static let batchShortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
    
    static let batchTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter
    }()
}