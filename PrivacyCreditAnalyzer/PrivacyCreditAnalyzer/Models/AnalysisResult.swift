import Foundation

/// Represents the complete analysis result containing personality traits and trustworthiness score
struct AnalysisResult: Codable, Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let personalityTraits: PersonalityTraits
    let trustworthinessScore: TrustworthinessScore
    let messageCount: Int
    let processingTime: TimeInterval
    
    init(id: UUID = UUID(), timestamp: Date = Date(), personalityTraits: PersonalityTraits, trustworthinessScore: TrustworthinessScore, messageCount: Int, processingTime: TimeInterval) {
        self.id = id
        self.timestamp = timestamp
        self.personalityTraits = personalityTraits
        self.trustworthinessScore = trustworthinessScore
        self.messageCount = max(0, messageCount) // Ensure non-negative
        self.processingTime = max(0, processingTime) // Ensure non-negative
    }
    
    /// Validates that the analysis result has valid data
    func isValid() -> Bool {
        return personalityTraits.isValid() &&
               trustworthinessScore.isValid() &&
               messageCount >= 0 &&
               processingTime >= 0
    }
    
    /// Returns a summary of the analysis
    func summary() -> String {
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
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "personalityTraits": personalityTraits.toDictionary(),
            "trustworthinessScore": trustworthinessScore.toDictionary(),
            "messageCount": messageCount,
            "processingTime": processingTime
        ]
    }
    
    /// Creates an AnalysisResult from a dictionary
    static func fromDictionary(_ dict: [String: Any]) throws -> AnalysisResult {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let timestampString = dict["timestamp"] as? String,
              let timestamp = ISO8601DateFormatter().date(from: timestampString),
              let personalityDict = dict["personalityTraits"] as? [String: Double],
              let trustDict = dict["trustworthinessScore"] as? [String: Any],
              let messageCount = dict["messageCount"] as? Int,
              let processingTime = dict["processingTime"] as? TimeInterval else {
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
            timestamp: timestamp,
            personalityTraits: personalityTraits,
            trustworthinessScore: trustworthinessScore,
            messageCount: messageCount,
            processingTime: processingTime
        )
    }
}

enum AnalysisError: Error, LocalizedError {
    case invalidDictionary
    
    var errorDescription: String? {
        switch self {
        case .invalidDictionary:
            return "Invalid dictionary format for AnalysisResult"
        }
    }
}