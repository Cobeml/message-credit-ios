import Foundation

/// Represents the complete analysis result containing personality traits and trustworthiness score
public struct AnalysisResult: Codable, Identifiable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let personalityTraits: PersonalityTraits
    public let trustworthinessScore: TrustworthinessScore
    public let messageCount: Int
    public let processingTime: TimeInterval
    public let batchingInfo: BatchingInfo?
    public let varianceMetrics: PersonalityTraitsVariance?
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), personalityTraits: PersonalityTraits, trustworthinessScore: TrustworthinessScore, messageCount: Int, processingTime: TimeInterval, batchingInfo: BatchingInfo? = nil, varianceMetrics: PersonalityTraitsVariance? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.personalityTraits = personalityTraits
        self.trustworthinessScore = trustworthinessScore
        self.messageCount = messageCount // Don't clamp here to allow validation to catch invalid values
        self.processingTime = processingTime // Don't clamp here to allow validation to catch invalid values
        self.batchingInfo = batchingInfo
        self.varianceMetrics = varianceMetrics
    }
    
    /// Validates that the analysis result has valid data
    public func isValid() -> Bool {
        return personalityTraits.isValid() &&
               trustworthinessScore.isValid() &&
               messageCount >= 0 &&
               processingTime >= 0
    }
    
    /// Returns a summary of the analysis
    public func summary() -> String {
        let avgPersonality = personalityTraits.averageScore()
        let trustScore = trustworthinessScore.score
        
        var summary = """
        Analysis Summary:
        - Messages Analyzed: \(messageCount)
        - Processing Time: \(String(format: "%.2f", processingTime))s
        - Average Personality Score: \(String(format: "%.2f", avgPersonality))
        - Trustworthiness Score: \(String(format: "%.2f", trustScore))
        """
        
        if let batchingInfo = batchingInfo {
            summary += """
            
        Batching Information:
        - Total Batches: \(batchingInfo.totalBatches)
        - Processing Method: \(batchingInfo.processingMethod.description)
        - Average Batch Quality: \(String(format: "%.2f", batchingInfo.averageBatchQuality))
        """
        }
        
        if let varianceMetrics = varianceMetrics {
            summary += """
            
        Stability Metrics:
        - Personality Stability: \(String(format: "%.2f", varianceMetrics.stabilityScore))
        - Average Variance: \(String(format: "%.3f", varianceMetrics.averageVariance))
        """
        }
        
        return summary
    }
    
    /// Returns a dictionary representation for JSON serialization
    public func toDictionary() -> [String: Any] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var dict: [String: Any] = [
            "id": id.uuidString,
            "timestamp": formatter.string(from: timestamp),
            "personalityTraits": personalityTraits.toDictionary(),
            "trustworthinessScore": trustworthinessScore.toDictionary(),
            "messageCount": messageCount,
            "processingTime": processingTime
        ]
        
        if let batchingInfo = batchingInfo {
            dict["batchingInfo"] = [
                "totalBatches": batchingInfo.totalBatches,
                "averageBatchQuality": batchingInfo.averageBatchQuality,
                "processingMethod": batchingInfo.processingMethod.rawValue,
                "overlapPercentage": batchingInfo.overlapPercentage
            ]
        }
        
        if let varianceMetrics = varianceMetrics {
            dict["varianceMetrics"] = [
                "openness": varianceMetrics.openness,
                "conscientiousness": varianceMetrics.conscientiousness,
                "extraversion": varianceMetrics.extraversion,
                "agreeableness": varianceMetrics.agreeableness,
                "neuroticism": varianceMetrics.neuroticism,
                "stabilityScore": varianceMetrics.stabilityScore
            ]
        }
        
        return dict
    }
    
    /// Creates an AnalysisResult from a dictionary
    public static func fromDictionary(_ dict: [String: Any]) throws -> AnalysisResult {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let timestampString = dict["timestamp"] as? String,
              let personalityDict = dict["personalityTraits"] as? [String: Double],
              let trustDict = dict["trustworthinessScore"] as? [String: Any],
              let messageCount = dict["messageCount"] as? Int,
              let processingTime = dict["processingTime"] as? TimeInterval else {
            throw AnalysisError.invalidDictionary
        }
        
        // Use a more flexible date formatter
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.date(from: timestampString) ?? ISO8601DateFormatter().date(from: timestampString)
        
        guard let validTimestamp = timestamp else {
            throw AnalysisError.invalidDictionary
        }
        
        // Parse personality traits
        let personalityTraits = PersonalityTraits(
            openness: personalityDict["openness"] ?? 0.0,
            conscientiousness: personalityDict["conscientiousness"] ?? 0.0,
            extraversion: personalityDict["extraversion"] ?? 0.0,
            agreeableness: personalityDict["agreeableness"] ?? 0.0,
            neuroticism: personalityDict["neuroticism"] ?? 0.0,
            confidence: personalityDict["confidence"] ?? 0.0
        )
        
        // Parse trustworthiness score
        guard let score = trustDict["score"] as? Double,
              let factors = trustDict["factors"] as? [String: Double],
              let explanation = trustDict["explanation"] as? String else {
            throw AnalysisError.invalidDictionary
        }
        
        let trustworthinessScore = TrustworthinessScore(
            score: score,
            factors: factors,
            explanation: explanation
        )
        
        // Parse batching info if present
        var batchingInfo: BatchingInfo?
        if let batchingDict = dict["batchingInfo"] as? [String: Any],
           let totalBatches = batchingDict["totalBatches"] as? Int,
           let averageBatchQuality = batchingDict["averageBatchQuality"] as? Double,
           let processingMethodString = batchingDict["processingMethod"] as? String,
           let processingMethod = ProcessingMethod(rawValue: processingMethodString),
           let overlapPercentage = batchingDict["overlapPercentage"] as? Double {
            batchingInfo = BatchingInfo(
                totalBatches: totalBatches,
                averageBatchQuality: averageBatchQuality,
                processingMethod: processingMethod,
                overlapPercentage: overlapPercentage
            )
        }
        
        // Parse variance metrics if present
        var varianceMetrics: PersonalityTraitsVariance?
        if let varianceDict = dict["varianceMetrics"] as? [String: Double] {
            varianceMetrics = PersonalityTraitsVariance(
                openness: varianceDict["openness"] ?? 0.0,
                conscientiousness: varianceDict["conscientiousness"] ?? 0.0,
                extraversion: varianceDict["extraversion"] ?? 0.0,
                agreeableness: varianceDict["agreeableness"] ?? 0.0,
                neuroticism: varianceDict["neuroticism"] ?? 0.0
            )
        }
        
        return AnalysisResult(
            id: id,
            timestamp: validTimestamp,
            personalityTraits: personalityTraits,
            trustworthinessScore: trustworthinessScore,
            messageCount: messageCount,
            processingTime: processingTime,
            batchingInfo: batchingInfo,
            varianceMetrics: varianceMetrics
        )
    }
}

/// Information about batching used in the analysis
public struct BatchingInfo: Codable, Equatable {
    public let totalBatches: Int
    public let averageBatchQuality: Double
    public let processingMethod: ProcessingMethod
    public let overlapPercentage: Double
    
    public init(totalBatches: Int, averageBatchQuality: Double, processingMethod: ProcessingMethod, overlapPercentage: Double) {
        self.totalBatches = totalBatches
        self.averageBatchQuality = averageBatchQuality
        self.processingMethod = processingMethod
        self.overlapPercentage = overlapPercentage
    }
}

/// Method used for processing large message sets
public enum ProcessingMethod: String, Codable, CaseIterable {
    case singleBatch = "single_batch"
    case overlappingBatches = "overlapping_batches"
    case intelligentSampling = "intelligent_sampling"
    case hybridBatching = "hybrid_batching"
    
    public var description: String {
        switch self {
        case .singleBatch:
            return "Single Batch"
        case .overlappingBatches:
            return "Overlapping Batches"
        case .intelligentSampling:
            return "Intelligent Sampling"
        case .hybridBatching:
            return "Hybrid Batching"
        }
    }
}

public enum AnalysisError: Error, LocalizedError {
    case invalidDictionary
    case batchProcessingFailed(String)
    case aggregationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidDictionary:
            return "Invalid dictionary format for AnalysisResult"
        case .batchProcessingFailed(let reason):
            return "Batch processing failed: \(reason)"
        case .aggregationFailed(let reason):
            return "Score aggregation failed: \(reason)"
        }
    }
}