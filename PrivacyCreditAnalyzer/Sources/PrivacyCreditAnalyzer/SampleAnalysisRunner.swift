import Foundation

/// Runs sample data through the MLX inference engine and stores results for frontend testing
public class SampleAnalysisRunner {
    
    private let inferenceEngine: MLXInferenceEngine
    
    public init() {
        self.inferenceEngine = MLXInferenceEngine()
    }
    
    // MARK: - Analysis Execution
    
    /// Runs both sample datasets through analysis and stores results
    public func runSampleAnalysis() async throws -> (responsible: AnalysisResult, irresponsible: AnalysisResult) {
        print("🚀 Starting sample data analysis...")
        
        // Initialize inference engine
        do {
            try await inferenceEngine.initialize()
            print("✅ MLX Inference engine initialized successfully")
        } catch {
            print("⚠️  MLX initialization failed, using enhanced mock analysis: \(error)")
        }
        
        // Analyze responsible user
        print("\n📊 Analyzing responsible user messages...")
        let responsibleMessages = SampleDataGenerator.generateResponsibleUserMessages()
        let responsibleResult = try await analyzeWithFallback(messages: responsibleMessages, userType: "responsible")
        
        // Analyze irresponsible user  
        print("\n📊 Analyzing irresponsible user messages...")
        let irresponsibleMessages = SampleDataGenerator.generateIrresponsibleUserMessages()
        let irresponsibleResult = try await analyzeWithFallback(messages: irresponsibleMessages, userType: "irresponsible")
        
        // Store results for frontend testing
        SampleDataGenerator.storeAnalysisResults(responsibleResult, irresponsibleResult)
        
        print("\n✅ Sample analysis complete! Results stored for frontend testing.")
        
        return (responsibleResult, irresponsibleResult)
    }
    
    /// Generates sample JSON files for manual testing
    public func generateSampleJSONFiles() throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Generate responsible user JSON
        let responsibleJSON = SampleDataGenerator.responsibleUserJSON()
        let responsibleURL = documentsPath.appendingPathComponent("responsible_user_sample.json")
        try responsibleJSON.write(to: responsibleURL, atomically: true, encoding: .utf8)
        
        // Generate irresponsible user JSON
        let irresponsibleJSON = SampleDataGenerator.irresponsibleUserJSON()
        let irresponsibleURL = documentsPath.appendingPathComponent("irresponsible_user_sample.json")
        try irresponsibleJSON.write(to: irresponsibleURL, atomically: true, encoding: .utf8)
        
        print("📄 Sample JSON files generated:")
        print("   Responsible: \(responsibleURL.path)")
        print("   Irresponsible: \(irresponsibleURL.path)")
    }
    
    // MARK: - Private Analysis Methods
    
    private func analyzeWithFallback(messages: [Message], userType: String) async throws -> AnalysisResult {
        if inferenceEngine.isInitialized {
            // Use real MLX inference
            do {
                let result = try await inferenceEngine.processInBackground(messages: messages)
                print("✅ Real MLX analysis completed for \(userType) user")
                printAnalysisResults(result, userType: userType)
                return result
            } catch {
                print("⚠️  MLX analysis failed for \(userType), falling back to mock: \(error)")
                return generateEnhancedMockResult(messages: messages, userType: userType)
            }
        } else {
            // Use enhanced mock analysis based on message content
            return generateEnhancedMockResult(messages: messages, userType: userType)
        }
    }
    
    private func generateEnhancedMockResult(messages: [Message], userType: String) -> AnalysisResult {
        let startTime = Date()
        
        // Analyze message content for indicators
        let indicators = analyzeMessageIndicators(messages)
        
        let result: AnalysisResult
        
        if userType == "responsible" {
            result = createResponsibleResult(indicators: indicators, messageCount: messages.count)
        } else {
            result = createIrresponsibleResult(indicators: indicators, messageCount: messages.count)
        }
        
        let processingTime = Date().timeIntervalSince(startTime)
        let updatedResult = AnalysisResult(
            id: result.id,
            timestamp: result.timestamp,
            personalityTraits: result.personalityTraits,
            trustworthinessScore: result.trustworthinessScore,
            messageCount: result.messageCount,
            processingTime: processingTime
        )
        
        print("✅ Enhanced mock analysis completed for \(userType) user")
        printAnalysisResults(updatedResult, userType: userType)
        
        return updatedResult
    }
    
    private func analyzeMessageIndicators(_ messages: [Message]) -> MessageIndicators {
        var indicators = MessageIndicators()
        
        for message in messages {
            let content = message.content.lowercased()
            
            // Financial responsibility indicators
            if content.contains("budget") || content.contains("save") || content.contains("plan") {
                indicators.financialResponsibility += 1
            }
            if content.contains("overdraft") || content.contains("maxed out") || content.contains("broke") {
                indicators.financialIrresponsibility += 1
            }
            
            // Emotional stability indicators
            if content.contains("calm") || content.contains("stable") || content.contains("manage") {
                indicators.emotionalStability += 1
            }
            if content.contains("😭") || content.contains("hate") || content.contains("falling apart") {
                indicators.emotionalVolatility += 1
            }
            
            // Relationship indicators
            if content.contains("family") || content.contains("support") || content.contains("thank") {
                indicators.positiveRelationships += 1
            }
            if content.contains("fight") || content.contains("judge") || content.contains("tired of") {
                indicators.relationshipStrain += 1
            }
            
            // Planning indicators
            if content.contains("deadline") || content.contains("ahead") || content.contains("schedule") {
                indicators.goodPlanning += 1
            }
            if content.contains("forgot") || content.contains("rush") || content.contains("putting off") {
                indicators.poorPlanning += 1
            }
        }
        
        return indicators
    }
    
    private func createResponsibleResult(indicators: MessageIndicators, messageCount: Int) -> AnalysisResult {
        // Adjust base scores based on message content analysis
        let financialFactor = min(1.0, Double(indicators.financialResponsibility) / Double(max(messageCount / 3, 1)))
        let stabilityFactor = min(1.0, Double(indicators.emotionalStability) / Double(max(messageCount / 4, 1)))
        let relationshipFactor = min(1.0, Double(indicators.positiveRelationships) / Double(max(messageCount / 3, 1)))
        let planningFactor = min(1.0, Double(indicators.goodPlanning) / Double(max(messageCount / 4, 1)))
        
        let traits = PersonalityTraits(
            openness: 0.60 + (planningFactor * 0.15),
            conscientiousness: 0.75 + (financialFactor * 0.15) + (planningFactor * 0.10),
            extraversion: 0.55 + (relationshipFactor * 0.10),
            agreeableness: 0.75 + (relationshipFactor * 0.15),
            neuroticism: max(0.1, 0.35 - (stabilityFactor * 0.20)),
            confidence: 0.80 + (financialFactor * 0.10)
        )
        
        let trustworthiness = TrustworthinessScore(
            score: 0.75 + (financialFactor * 0.15) + (stabilityFactor * 0.10),
            factors: [
                "communication_style": 0.75 + (relationshipFactor * 0.10),
                "financial_responsibility": 0.80 + (financialFactor * 0.15),
                "relationship_stability": 0.75 + (relationshipFactor * 0.15),
                "emotional_intelligence": 0.70 + (stabilityFactor * 0.15)
            ],
            explanation: "Enhanced analysis based on message content shows strong financial responsibility indicators (\(indicators.financialResponsibility) mentions), emotional stability (\(indicators.emotionalStability) indicators), and positive relationship patterns (\(indicators.positiveRelationships) mentions). High creditworthiness indicated."
        )
        
        return AnalysisResult(
            personalityTraits: traits,
            trustworthinessScore: trustworthiness,
            messageCount: messageCount,
            processingTime: 0.0 // Will be set by caller
        )
    }
    
    private func createIrresponsibleResult(indicators: MessageIndicators, messageCount: Int) -> AnalysisResult {
        // Adjust base scores based on negative indicators
        let financialRisk = min(1.0, Double(indicators.financialIrresponsibility) / Double(max(messageCount / 3, 1)))
        let volatilityFactor = min(1.0, Double(indicators.emotionalVolatility) / Double(max(messageCount / 4, 1)))
        let relationshipRisk = min(1.0, Double(indicators.relationshipStrain) / Double(max(messageCount / 3, 1)))
        let planningRisk = min(1.0, Double(indicators.poorPlanning) / Double(max(messageCount / 4, 1)))
        
        let traits = PersonalityTraits(
            openness: max(0.2, 0.50 - (planningRisk * 0.15)),
            conscientiousness: max(0.1, 0.40 - (financialRisk * 0.20) - (planningRisk * 0.15)),
            extraversion: min(0.9, 0.65 + (volatilityFactor * 0.15)), // High extraversion can indicate impulsivity
            agreeableness: max(0.2, 0.50 - (relationshipRisk * 0.20)),
            neuroticism: min(0.9, 0.50 + (volatilityFactor * 0.25) + (financialRisk * 0.10)),
            confidence: max(0.2, 0.50 - (financialRisk * 0.15) - (volatilityFactor * 0.10))
        )
        
        let trustworthiness = TrustworthinessScore(
            score: max(0.1, 0.40 - (financialRisk * 0.20) - (volatilityFactor * 0.10)),
            factors: [
                "communication_style": max(0.1, 0.45 - (relationshipRisk * 0.15)),
                "financial_responsibility": max(0.1, 0.30 - (financialRisk * 0.20)),
                "relationship_stability": max(0.1, 0.40 - (relationshipRisk * 0.20)),
                "emotional_intelligence": max(0.1, 0.35 - (volatilityFactor * 0.15))
            ],
            explanation: "Analysis reveals significant risk indicators: financial irresponsibility (\(indicators.financialIrresponsibility) red flags), emotional volatility (\(indicators.emotionalVolatility) indicators), relationship strain (\(indicators.relationshipStrain) mentions), and poor planning (\(indicators.poorPlanning) instances). Low creditworthiness indicated."
        )
        
        return AnalysisResult(
            personalityTraits: traits,
            trustworthinessScore: trustworthiness,
            messageCount: messageCount,
            processingTime: 0.0 // Will be set by caller
        )
    }
    
    private func printAnalysisResults(_ result: AnalysisResult, userType: String) {
        print("\n📈 Analysis Results for \(userType.capitalized) User:")
        print("   💭 Personality Traits:")
        print("      Openness: \(String(format: "%.2f", result.personalityTraits.openness))")
        print("      Conscientiousness: \(String(format: "%.2f", result.personalityTraits.conscientiousness))")
        print("      Extraversion: \(String(format: "%.2f", result.personalityTraits.extraversion))")
        print("      Agreeableness: \(String(format: "%.2f", result.personalityTraits.agreeableness))")
        print("      Neuroticism: \(String(format: "%.2f", result.personalityTraits.neuroticism))")
        print("      Confidence: \(String(format: "%.2f", result.personalityTraits.confidence))")
        
        print("   🏦 Trustworthiness Score: \(String(format: "%.2f", result.trustworthinessScore.score))")
        print("   📊 Factor Breakdown:")
        for (factor, score) in result.trustworthinessScore.factors.sorted(by: { $0.key < $1.key }) {
            print("      \(factor.replacingOccurrences(of: "_", with: " ").capitalized): \(String(format: "%.2f", score))")
        }
        print("   ⏱  Processing Time: \(String(format: "%.2f", result.processingTime))s")
        print("   📝 Messages Analyzed: \(result.messageCount)")
    }
}

// MARK: - Supporting Types

private struct MessageIndicators {
    var financialResponsibility = 0
    var financialIrresponsibility = 0
    var emotionalStability = 0
    var emotionalVolatility = 0
    var positiveRelationships = 0
    var relationshipStrain = 0
    var goodPlanning = 0
    var poorPlanning = 0
}