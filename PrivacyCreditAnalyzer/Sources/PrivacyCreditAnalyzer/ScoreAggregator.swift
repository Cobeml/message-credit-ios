import Foundation

/// Aggregates personality traits and trustworthiness scores from multiple batches using intelligent weighting
public class ScoreAggregator {
    
    // MARK: - Configuration
    
    public struct AggregationConfiguration {
        let confidenceWeight: Double
        let messageCountWeight: Double
        let qualityWeight: Double
        let temporalDecayFactor: Double
        let minBatchConfidence: Double
        
        public static let `default` = AggregationConfiguration(
            confidenceWeight: 0.4,
            messageCountWeight: 0.3,
            qualityWeight: 0.3,
            temporalDecayFactor: 0.95, // Recent batches get slight preference
            minBatchConfidence: 0.2
        )
        
        public init(confidenceWeight: Double = 0.4, messageCountWeight: Double = 0.3, qualityWeight: Double = 0.3, temporalDecayFactor: Double = 0.95, minBatchConfidence: Double = 0.2) {
            self.confidenceWeight = confidenceWeight
            self.messageCountWeight = messageCountWeight
            self.qualityWeight = qualityWeight
            self.temporalDecayFactor = temporalDecayFactor
            self.minBatchConfidence = minBatchConfidence
        }
    }
    
    // MARK: - Properties
    
    private let configuration: AggregationConfiguration
    
    public init(configuration: AggregationConfiguration = .default) {
        self.configuration = configuration
    }
    
    // MARK: - Public Interface
    
    /// Aggregates personality traits from multiple batches using weighted averaging
    public func aggregatePersonalityTraits(_ batchedTraits: [BatchedPersonalityTraits]) throws -> AggregatedPersonalityResult {
        guard !batchedTraits.isEmpty else {
            throw AggregationError.noBatchesProvided
        }
        
        // Filter out low-confidence batches
        let validBatches = batchedTraits.filter { $0.traits.confidence >= configuration.minBatchConfidence }
        
        guard !validBatches.isEmpty else {
            throw AggregationError.noValidBatches("All batches below minimum confidence threshold (\(configuration.minBatchConfidence))")
        }
        
        // Calculate weights for each batch
        let weightedTraits = validBatches.map { batchedTrait -> (PersonalityTraits, weight: Double) in
            let weight = calculateBatchWeight(batchedTrait)
            return (batchedTrait.traits, weight: weight)
        }
        
        // Aggregate using weighted average
        let aggregatedTraits = PersonalityTraits.weightedAverage(weightedTraits)
        
        // Calculate variance across batches
        let allTraits = validBatches.map(\.traits)
        let varianceMetrics = PersonalityTraits.calculateVariance(allTraits)
        
        // Calculate aggregation confidence
        let aggregationConfidence = calculateAggregationConfidence(validBatches, varianceMetrics: varianceMetrics)
        
        return AggregatedPersonalityResult(
            aggregatedTraits: aggregatedTraits,
            varianceMetrics: varianceMetrics,
            batchCount: validBatches.count,
            totalMessageCount: validBatches.reduce(0) { $0 + $1.batchMetadata.messageCount },
            aggregationConfidence: aggregationConfidence,
            batchWeights: weightedTraits.map(\.weight),
            processingMethod: determineProcessingMethod(validBatches)
        )
    }
    
    /// Aggregates trustworthiness scores from multiple batches
    public func aggregateTrustworthinessScores(_ scores: [BatchedTrustworthinessScore]) throws -> AggregatedTrustworthinessResult {
        guard !scores.isEmpty else {
            throw AggregationError.noBatchesProvided
        }
        
        // Calculate weights based on batch quality and message count
        let weightedScores = scores.map { batchedScore -> (TrustworthinessScore, weight: Double) in
            let weight = calculateTrustworthinessWeight(batchedScore)
            return (batchedScore.score, weight: weight)
        }
        
        let totalWeight = weightedScores.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else {
            throw AggregationError.invalidWeights("Total weight is zero")
        }
        
        // Aggregate overall score
        let aggregatedScore = weightedScores.reduce(0.0) { $0 + ($1.0.score * $1.weight) } / totalWeight
        
        // Aggregate factors
        let aggregatedFactors = aggregateFactors(weightedScores)
        
        // Create aggregated explanation
        let explanation = createAggregatedExplanation(scores, aggregatedScore: aggregatedScore)
        
        let aggregatedTrustScore = TrustworthinessScore(
            score: aggregatedScore,
            factors: aggregatedFactors,
            explanation: explanation
        )
        
        return AggregatedTrustworthinessResult(
            aggregatedScore: aggregatedTrustScore,
            batchCount: scores.count,
            scoreVariance: calculateScoreVariance(scores.map(\.score)),
            factorVariances: calculateFactorVariances(scores.map(\.score)),
            aggregationConfidence: calculateTrustworthinessConfidence(scores)
        )
    }
    
    /// Creates a final analysis result from aggregated components
    public func createFinalResult(
        personalityResult: AggregatedPersonalityResult,
        trustworthinessResult: AggregatedTrustworthinessResult,
        totalProcessingTime: TimeInterval,
        overlapPercentage: Double
    ) -> AnalysisResult {
        
        let batchingInfo = BatchingInfo(
            totalBatches: personalityResult.batchCount,
            averageBatchQuality: personalityResult.processingMethod == .singleBatch ? 1.0 : 0.8,
            processingMethod: personalityResult.processingMethod,
            overlapPercentage: overlapPercentage
        )
        
        return AnalysisResult(
            personalityTraits: personalityResult.aggregatedTraits,
            trustworthinessScore: trustworthinessResult.aggregatedScore,
            messageCount: personalityResult.totalMessageCount,
            processingTime: totalProcessingTime,
            batchingInfo: batchingInfo,
            varianceMetrics: personalityResult.varianceMetrics
        )
    }
}

// MARK: - Private Methods

extension ScoreAggregator {
    
    private func calculateBatchWeight(_ batchedTrait: BatchedPersonalityTraits) -> Double {
        // Confidence component
        let confidenceComponent = batchedTrait.traits.confidence * configuration.confidenceWeight
        
        // Message count component (normalized to 0-1, with 100 messages as target)
        let messageCountNormalized = min(1.0, Double(batchedTrait.batchMetadata.messageCount) / 100.0)
        let messageCountComponent = messageCountNormalized * configuration.messageCountWeight
        
        // Quality component
        let qualityComponent = batchedTrait.batchMetadata.batchQuality * configuration.qualityWeight
        
        // Temporal decay (more recent batches get slight preference)
        let temporalComponent = pow(configuration.temporalDecayFactor, Double(batchedTrait.batchMetadata.batchIndex))
        
        let baseWeight = confidenceComponent + messageCountComponent + qualityComponent
        return baseWeight * temporalComponent
    }
    
    private func calculateTrustworthinessWeight(_ batchedScore: BatchedTrustworthinessScore) -> Double {
        // Similar to personality weight but focuses on trustworthiness-specific factors
        let qualityComponent = batchedScore.batchMetadata.batchQuality * 0.5
        let messageCountNormalized = min(1.0, Double(batchedScore.batchMetadata.messageCount) / 100.0)
        let messageCountComponent = messageCountNormalized * 0.3
        
        // Financial/relationship keyword density bonus
        let keywordDensity = batchedScore.batchMetadata.keywordDensity / 100.0 // Convert percentage to 0-1
        let keywordComponent = min(1.0, keywordDensity * 2.0) * 0.2 // Bonus for relevant keywords
        
        return qualityComponent + messageCountComponent + keywordComponent
    }
    
    private func calculateAggregationConfidence(_ batches: [BatchedPersonalityTraits], varianceMetrics: PersonalityTraitsVariance) -> Double {
        // Base confidence from individual batch confidences
        let averageConfidence = batches.reduce(0.0) { $0 + $1.traits.confidence } / Double(batches.count)
        
        // Stability bonus (lower variance = higher confidence)
        let stabilityBonus = varianceMetrics.stabilityScore * 0.2
        
        // Sample size bonus (more batches = higher confidence)
        let sampleSizeBonus = min(0.2, Double(batches.count) / 50.0) // Max bonus at 50 batches
        
        let confidence = averageConfidence + stabilityBonus + sampleSizeBonus
        return max(0.0, min(1.0, confidence))
    }
    
    private func calculateTrustworthinessConfidence(_ scores: [BatchedTrustworthinessScore]) -> Double {
        let averageQuality = scores.reduce(0.0) { $0 + $1.batchMetadata.batchQuality } / Double(scores.count)
        let sampleSizeBonus = min(0.3, Double(scores.count) / 30.0)
        return max(0.0, min(1.0, averageQuality + sampleSizeBonus))
    }
    
    private func aggregateFactors(_ weightedScores: [(TrustworthinessScore, weight: Double)]) -> [String: Double] {
        var aggregatedFactors: [String: Double] = [:]
        let totalWeight = weightedScores.reduce(0.0) { $0 + $1.weight }
        
        // Collect all unique factor keys
        let allFactorKeys = Set(weightedScores.flatMap { $0.0.factors.keys })
        
        for factorKey in allFactorKeys {
            let weightedSum = weightedScores.reduce(0.0) { sum, item in
                let factorValue = item.0.factors[factorKey] ?? 0.5 // Default to neutral if missing
                return sum + (factorValue * item.weight)
            }
            aggregatedFactors[factorKey] = weightedSum / totalWeight
        }
        
        return aggregatedFactors
    }
    
    private func calculateScoreVariance(_ scores: [TrustworthinessScore]) -> Double {
        guard scores.count > 1 else { return 0.0 }
        
        let values = scores.map(\.score)
        let mean = values.reduce(0.0, +) / Double(values.count)
        let variance = values.reduce(0.0) { $0 + pow($1 - mean, 2) } / Double(values.count - 1)
        
        return sqrt(variance)
    }
    
    private func calculateFactorVariances(_ scores: [TrustworthinessScore]) -> [String: Double] {
        guard scores.count > 1 else { return [:] }
        
        var factorVariances: [String: Double] = [:]
        let allFactorKeys = Set(scores.flatMap { $0.factors.keys })
        
        for factorKey in allFactorKeys {
            let values = scores.compactMap { $0.factors[factorKey] }
            guard values.count > 1 else { continue }
            
            let mean = values.reduce(0.0, +) / Double(values.count)
            let variance = values.reduce(0.0) { $0 + pow($1 - mean, 2) } / Double(values.count - 1)
            factorVariances[factorKey] = sqrt(variance)
        }
        
        return factorVariances
    }
    
    private func createAggregatedExplanation(_ scores: [BatchedTrustworthinessScore], aggregatedScore: Double) -> String {
        let batchCount = scores.count
        let totalMessages = scores.reduce(0) { $0 + $1.batchMetadata.messageCount }
        
        let scoreCategory = {
            switch aggregatedScore {
            case 0.8...: return "excellent"
            case 0.6..<0.8: return "good"
            case 0.4..<0.6: return "fair"
            case 0.2..<0.4: return "poor"
            default: return "very poor"
            }
        }()
        
        return """
        Aggregated trustworthiness analysis based on \(batchCount) batches covering \(totalMessages) messages. \
        Overall assessment shows \(scoreCategory) creditworthiness indicators. Analysis incorporates \
        communication patterns, financial responsibility markers, and relationship stability factors \
        across temporal segments to provide comprehensive credit risk evaluation.
        """
    }
    
    private func determineProcessingMethod(_ batches: [BatchedPersonalityTraits]) -> ProcessingMethod {
        if batches.count == 1 {
            return .singleBatch
        } else if batches.count <= 5 {
            return .overlappingBatches
        } else {
            return .hybridBatching
        }
    }
}

// MARK: - Supporting Types

/// Result of aggregating personality traits from multiple batches
public struct AggregatedPersonalityResult {
    public let aggregatedTraits: PersonalityTraits
    public let varianceMetrics: PersonalityTraitsVariance
    public let batchCount: Int
    public let totalMessageCount: Int
    public let aggregationConfidence: Double
    public let batchWeights: [Double]
    public let processingMethod: ProcessingMethod
}

/// Result of aggregating trustworthiness scores from multiple batches
public struct AggregatedTrustworthinessResult {
    public let aggregatedScore: TrustworthinessScore
    public let batchCount: Int
    public let scoreVariance: Double
    public let factorVariances: [String: Double]
    public let aggregationConfidence: Double
}

/// Represents trustworthiness score analysis from a single batch
public struct BatchedTrustworthinessScore {
    public let score: TrustworthinessScore
    public let batchMetadata: BatchAnalysisMetadata
    public let analysisNotes: String?
    
    public init(score: TrustworthinessScore, batchMetadata: BatchAnalysisMetadata, analysisNotes: String? = nil) {
        self.score = score
        self.batchMetadata = batchMetadata
        self.analysisNotes = analysisNotes
    }
}

/// Errors that can occur during aggregation
public enum AggregationError: Error, LocalizedError {
    case noBatchesProvided
    case noValidBatches(String)
    case invalidWeights(String)
    case aggregationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .noBatchesProvided:
            return "No batches provided for aggregation"
        case .noValidBatches(let reason):
            return "No valid batches for aggregation: \(reason)"
        case .invalidWeights(let reason):
            return "Invalid weights for aggregation: \(reason)"
        case .aggregationFailed(let reason):
            return "Aggregation failed: \(reason)"
        }
    }
}