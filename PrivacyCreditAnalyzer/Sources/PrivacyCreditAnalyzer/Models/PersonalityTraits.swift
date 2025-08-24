import Foundation

/// Represents Big Five personality traits extracted from message analysis
public struct PersonalityTraits: Codable, Equatable {
    public let openness: Double
    public let conscientiousness: Double
    public let extraversion: Double
    public let agreeableness: Double
    public let neuroticism: Double
    public let confidence: Double
    
    public init(openness: Double, conscientiousness: Double, extraversion: Double, agreeableness: Double, neuroticism: Double, confidence: Double) {
        // Ensure all values are within valid range [0.0, 1.0]
        self.openness = max(0.0, min(1.0, openness))
        self.conscientiousness = max(0.0, min(1.0, conscientiousness))
        self.extraversion = max(0.0, min(1.0, extraversion))
        self.agreeableness = max(0.0, min(1.0, agreeableness))
        self.neuroticism = max(0.0, min(1.0, neuroticism))
        self.confidence = max(0.0, min(1.0, confidence))
    }
    
    /// Validates that all trait values are within acceptable range
    public func isValid() -> Bool {
        let traits = [openness, conscientiousness, extraversion, agreeableness, neuroticism, confidence]
        return traits.allSatisfy { $0 >= 0.0 && $0 <= 1.0 }
    }
    
    /// Returns the average of all personality traits
    public func averageScore() -> Double {
        return (openness + conscientiousness + extraversion + agreeableness + neuroticism) / 5.0
    }
    
    /// Returns a dictionary representation for JSON serialization
    public func toDictionary() -> [String: Double] {
        return [
            "openness": openness,
            "conscientiousness": conscientiousness,
            "extraversion": extraversion,
            "agreeableness": agreeableness,
            "neuroticism": neuroticism,
            "confidence": confidence
        ]
    }
    
    /// Creates weighted average of personality traits from multiple sources
    public static func weightedAverage(_ traits: [(PersonalityTraits, weight: Double)]) -> PersonalityTraits {
        guard !traits.isEmpty else {
            return PersonalityTraits(openness: 0.5, conscientiousness: 0.5, extraversion: 0.5, agreeableness: 0.5, neuroticism: 0.5, confidence: 0.0)
        }
        
        let totalWeight = traits.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else {
            return traits.first!.0
        }
        
        let weightedOpenness = traits.reduce(0.0) { $0 + ($1.0.openness * $1.weight) } / totalWeight
        let weightedConscientiousness = traits.reduce(0.0) { $0 + ($1.0.conscientiousness * $1.weight) } / totalWeight
        let weightedExtraversion = traits.reduce(0.0) { $0 + ($1.0.extraversion * $1.weight) } / totalWeight
        let weightedAgreeableness = traits.reduce(0.0) { $0 + ($1.0.agreeableness * $1.weight) } / totalWeight
        let weightedNeuroticism = traits.reduce(0.0) { $0 + ($1.0.neuroticism * $1.weight) } / totalWeight
        let weightedConfidence = traits.reduce(0.0) { $0 + ($1.0.confidence * $1.weight) } / totalWeight
        
        return PersonalityTraits(
            openness: weightedOpenness,
            conscientiousness: weightedConscientiousness,
            extraversion: weightedExtraversion,
            agreeableness: weightedAgreeableness,
            neuroticism: weightedNeuroticism,
            confidence: weightedConfidence
        )
    }
    
    /// Calculates variance across multiple personality trait measurements
    public static func calculateVariance(_ traits: [PersonalityTraits]) -> PersonalityTraitsVariance {
        guard traits.count > 1 else {
            return PersonalityTraitsVariance()
        }
        
        // Calculate means for each trait
        let count = Double(traits.count)
        let meanOpenness = traits.reduce(0.0) { $0 + $1.openness } / count
        let meanConscientiousness = traits.reduce(0.0) { $0 + $1.conscientiousness } / count
        let meanExtraversion = traits.reduce(0.0) { $0 + $1.extraversion } / count
        let meanAgreeableness = traits.reduce(0.0) { $0 + $1.agreeableness } / count
        let meanNeuroticism = traits.reduce(0.0) { $0 + $1.neuroticism } / count
        
        let mean = PersonalityTraits(
            openness: meanOpenness,
            conscientiousness: meanConscientiousness,
            extraversion: meanExtraversion,
            agreeableness: meanAgreeableness,
            neuroticism: meanNeuroticism,
            confidence: 0.0 // Not used in variance calculation
        )
        
        let opennessVariance = traits.reduce(0.0) { $0 + pow($1.openness - mean.openness, 2) } / Double(traits.count - 1)
        let conscientiousnessVariance = traits.reduce(0.0) { $0 + pow($1.conscientiousness - mean.conscientiousness, 2) } / Double(traits.count - 1)
        let extraversionVariance = traits.reduce(0.0) { $0 + pow($1.extraversion - mean.extraversion, 2) } / Double(traits.count - 1)
        let agreeablenessVariance = traits.reduce(0.0) { $0 + pow($1.agreeableness - mean.agreeableness, 2) } / Double(traits.count - 1)
        let neuroticismVariance = traits.reduce(0.0) { $0 + pow($1.neuroticism - mean.neuroticism, 2) } / Double(traits.count - 1)
        
        return PersonalityTraitsVariance(
            openness: sqrt(opennessVariance),
            conscientiousness: sqrt(conscientiousnessVariance),
            extraversion: sqrt(extraversionVariance),
            agreeableness: sqrt(agreeablenessVariance),
            neuroticism: sqrt(neuroticismVariance)
        )
    }
}

/// Represents variance/standard deviation in personality trait measurements
public struct PersonalityTraitsVariance: Codable, Equatable {
    public let openness: Double
    public let conscientiousness: Double
    public let extraversion: Double
    public let agreeableness: Double
    public let neuroticism: Double
    
    public init(openness: Double = 0.0, conscientiousness: Double = 0.0, extraversion: Double = 0.0, agreeableness: Double = 0.0, neuroticism: Double = 0.0) {
        self.openness = openness
        self.conscientiousness = conscientiousness
        self.extraversion = extraversion
        self.agreeableness = agreeableness
        self.neuroticism = neuroticism
    }
    
    /// Average variance across all traits (stability metric)
    public var averageVariance: Double {
        return (openness + conscientiousness + extraversion + agreeableness + neuroticism) / 5.0
    }
    
    /// Stability score (inverse of variance, 0.0 to 1.0)
    public var stabilityScore: Double {
        let avgVariance = averageVariance
        return max(0.0, 1.0 - (avgVariance * 4.0)) // Scale variance to 0-1 range
    }
}

/// Represents personality traits analysis from a single batch with metadata
public struct BatchedPersonalityTraits: Codable, Equatable {
    public let traits: PersonalityTraits
    public let batchMetadata: BatchAnalysisMetadata
    public let analysisNotes: String?
    
    public init(traits: PersonalityTraits, batchMetadata: BatchAnalysisMetadata, analysisNotes: String? = nil) {
        self.traits = traits
        self.batchMetadata = batchMetadata
        self.analysisNotes = analysisNotes
    }
    
    /// Weight for aggregation based on confidence and message count
    public var aggregationWeight: Double {
        let confidenceWeight = traits.confidence
        let messageCountWeight = min(1.0, Double(batchMetadata.messageCount) / 100.0)
        let qualityWeight = batchMetadata.batchQuality
        
        return (confidenceWeight * 0.4) + (messageCountWeight * 0.3) + (qualityWeight * 0.3)
    }
}

/// Metadata for batch-level personality analysis
public struct BatchAnalysisMetadata: Codable, Equatable {
    public let batchId: UUID
    public let batchIndex: Int
    public let totalBatches: Int
    public let messageCount: Int
    public let startDate: Date
    public let endDate: Date
    public let processingTime: TimeInterval
    public let batchQuality: Double
    public let financialKeywordCount: Int
    public let relationshipKeywordCount: Int
    
    public init(batchId: UUID, batchIndex: Int, totalBatches: Int, messageCount: Int, startDate: Date, endDate: Date, processingTime: TimeInterval, batchQuality: Double, financialKeywordCount: Int = 0, relationshipKeywordCount: Int = 0) {
        self.batchId = batchId
        self.batchIndex = batchIndex
        self.totalBatches = totalBatches
        self.messageCount = messageCount
        self.startDate = startDate
        self.endDate = endDate
        self.processingTime = processingTime
        self.batchQuality = batchQuality
        self.financialKeywordCount = financialKeywordCount
        self.relationshipKeywordCount = relationshipKeywordCount
    }
    
    /// Keyword density as a percentage of total messages
    public var keywordDensity: Double {
        guard messageCount > 0 else { return 0.0 }
        return Double(financialKeywordCount + relationshipKeywordCount) / Double(messageCount) * 100.0
    }
}