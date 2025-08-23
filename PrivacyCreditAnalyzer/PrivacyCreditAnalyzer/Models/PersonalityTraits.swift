import Foundation

/// Represents Big Five personality traits extracted from message analysis
struct PersonalityTraits: Codable, Equatable {
    let openness: Double
    let conscientiousness: Double
    let extraversion: Double
    let agreeableness: Double
    let neuroticism: Double
    let confidence: Double
    
    init(openness: Double, conscientiousness: Double, extraversion: Double, agreeableness: Double, neuroticism: Double, confidence: Double) {
        // Ensure all values are within valid range [0.0, 1.0]
        self.openness = max(0.0, min(1.0, openness))
        self.conscientiousness = max(0.0, min(1.0, conscientiousness))
        self.extraversion = max(0.0, min(1.0, extraversion))
        self.agreeableness = max(0.0, min(1.0, agreeableness))
        self.neuroticism = max(0.0, min(1.0, neuroticism))
        self.confidence = max(0.0, min(1.0, confidence))
    }
    
    /// Validates that all trait values are within acceptable range
    func isValid() -> Bool {
        let traits = [openness, conscientiousness, extraversion, agreeableness, neuroticism, confidence]
        return traits.allSatisfy { $0 >= 0.0 && $0 <= 1.0 }
    }
    
    /// Returns the average of all personality traits
    func averageScore() -> Double {
        return (openness + conscientiousness + extraversion + agreeableness + neuroticism) / 5.0
    }
    
    /// Returns a dictionary representation for JSON serialization
    func toDictionary() -> [String: Double] {
        return [
            "openness": openness,
            "conscientiousness": conscientiousness,
            "extraversion": extraversion,
            "agreeableness": agreeableness,
            "neuroticism": neuroticism,
            "confidence": confidence
        ]
    }
}