import Foundation

/// Represents a trustworthiness score with contributing factors and explanation
struct TrustworthinessScore: Codable, Equatable {
    let score: Double // 0.0 to 1.0
    let factors: [String: Double]
    let explanation: String
    
    init(score: Double, factors: [String: Double], explanation: String) {
        // Ensure score is within valid range [0.0, 1.0]
        self.score = max(0.0, min(1.0, score))
        
        // Ensure all factor values are within valid range [0.0, 1.0]
        self.factors = factors.mapValues { max(0.0, min(1.0, $0)) }
        
        self.explanation = explanation
    }
    
    /// Validates that the score and factors are within acceptable ranges
    func isValid() -> Bool {
        guard score >= 0.0 && score <= 1.0 else { return false }
        guard !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        
        // Validate all factor values are within range
        return factors.values.allSatisfy { $0 >= 0.0 && $0 <= 1.0 }
    }
    
    /// Returns the weighted average of all factors
    func calculateWeightedScore() -> Double {
        guard !factors.isEmpty else { return score }
        
        let totalWeight = factors.values.reduce(0, +)
        guard totalWeight > 0 else { return score }
        
        return factors.values.reduce(0, +) / Double(factors.count)
    }
    
    /// Returns the most significant contributing factor
    func primaryFactor() -> (key: String, value: Double)? {
        return factors.max { $0.value < $1.value }
    }
    
    /// Returns a dictionary representation for JSON serialization
    func toDictionary() -> [String: Any] {
        return [
            "score": score,
            "factors": factors,
            "explanation": explanation
        ]
    }
}