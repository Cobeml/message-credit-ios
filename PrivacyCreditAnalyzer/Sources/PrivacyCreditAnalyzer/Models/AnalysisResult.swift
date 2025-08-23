import Foundation

/// Represents the complete analysis result containing personality traits and trustworthiness score
public struct AnalysisResult: Codable, Identifiable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let personalityTraits: PersonalityTraits
    public let trustworthinessScore: TrustworthinessScore
    public let messageCount: Int
    public let processingTime: TimeInterval
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), personalityTraits: PersonalityTraits, trustworthinessScore: TrustworthinessScore, messageCount: Int, processingTime: TimeInterval) {
        self.id = id
        self.timestamp = timestamp
        self.personalityTraits = personalityTraits
        self.trustworthinessScore = trustworthinessScore
        self.messageCount = messageCount // Don't clamp here to allow validation to catch invalid values
        self.processingTime = processingTime // Don't clamp here to allow validation to catch invalid values
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
        
        return """
        Analysis Summary:
        - Messages Analyzed: \(messageCount)
        - Processing Time: \(String(format: "%.2f", processingTime))s
        - Average Personality Score: \(String(format: "%.2f", avgPersonality))
        - Trustworthiness Score: \(String(format: "%.2f", trustScore))
        """
    }
    
    /// Returns a dictionary representation for JSON serialization
    public func toDictionary() -> [String: Any] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return [
            "id": id.uuidString,
            "timestamp": formatter.string(from: timestamp),
            "personalityTraits": personalityTraits.toDictionary(),
            "trustworthinessScore": trustworthinessScore.toDictionary(),
            "messageCount": messageCount,
            "processingTime": processingTime
        ]
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
        
        return AnalysisResult(
            id: id,
            timestamp: validTimestamp,
            personalityTraits: personalityTraits,
            trustworthinessScore: trustworthinessScore,
            messageCount: messageCount,
            processingTime: processingTime
        )
    }
}

public enum AnalysisError: Error, LocalizedError {
    case invalidDictionary
    
    public var errorDescription: String? {
        switch self {
        case .invalidDictionary:
            return "Invalid dictionary format for AnalysisResult"
        }
    }
}