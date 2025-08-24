import Foundation

/// Manages prompt engineering for Big Five personality analysis and trustworthiness scoring
/// Uses latest 2025 research on LLM personality trait extraction
public class PromptEngineer {
    
    // MARK: - Configuration
    
    private let promptVersion = "2025.1"
    private let maxContextLength = 4000 // Tokens for context window
    
    public init() {}
    
    // MARK: - Big Five Personality Analysis Prompts
    
    /// Generates a comprehensive prompt for Big Five personality trait analysis
    public func createPersonalityAnalysisPrompt(messages: [Message]) -> String {
        let messageContext = formatMessagesForAnalysis(messages)
        let messageCount = messages.count
        
        return """
        You are an expert psychologist specializing in personality assessment using the Big Five (OCEAN) model. Analyze the following \(messageCount) messages to assess personality traits.
        
        INSTRUCTIONS:
        - Analyze communication patterns, word choice, emotional expression, and social behavior
        - Provide scores from 0.0 to 1.0 for each trait (0.0 = very low, 1.0 = very high)
        - Base your analysis on established psychological research
        - Consider cultural and contextual factors
        - Provide confidence score based on message volume and content quality
        
        PERSONALITY TRAITS TO ASSESS:
        
        1. OPENNESS (Intellectual curiosity, creativity, appreciation for variety)
        - Look for: creative language, diverse topics, abstract thinking, cultural references
        - Indicators: artistic interests, philosophical discussions, novel ideas, imagination
        
        2. CONSCIENTIOUSNESS (Organization, responsibility, self-discipline)
        - Look for: planning behavior, time management, goal-oriented language, reliability
        - Indicators: structured communication, follow-through, attention to detail, punctuality
        
        3. EXTRAVERSION (Energy, positive emotions, social engagement)
        - Look for: social enthusiasm, assertiveness, activity level, positive affect
        - Indicators: frequent social interactions, energy in communication, leadership, optimism
        
        4. AGREEABLENESS (Cooperation, empathy, trust, altruism)
        - Look for: cooperative language, empathy expressions, conflict avoidance, helping behavior
        - Indicators: supportive messages, consideration for others, collaborative approach, kindness
        
        5. NEUROTICISM (Emotional instability, anxiety, mood swings)
        - Look for: stress indicators, emotional volatility, worry, negative affect
        - Indicators: anxiety expressions, mood fluctuations, stress responses, emotional reactivity
        
        MESSAGE CONTEXT:
        \(messageContext)
        
        OUTPUT FORMAT (JSON only):
        {
          "openness": 0.X,
          "conscientiousness": 0.X,
          "extraversion": 0.X,
          "agreeableness": 0.X,
          "neuroticism": 0.X,
          "confidence": 0.X,
          "analysis_notes": "Brief explanation of key patterns observed"
        }
        """
    }
    
    /// Generates a batch-aware prompt for Big Five personality trait analysis
    public func createBatchPersonalityAnalysisPrompt(messages: [Message], batchMetadata: BatchMetadata) -> String {
        let messageContext = formatBatchMessagesForAnalysis(messages, metadata: batchMetadata)
        let timeSpanDescription = formatTimeSpan(batchMetadata.timeSpanHours)
        
        return """
        You are an expert psychologist specializing in personality assessment using the Big Five (OCEAN) model. 
        
        BATCH CONTEXT:
        - This is batch \(batchMetadata.batchIndex + 1) of \(batchMetadata.totalBatches) from a larger conversation history
        - Time period: \(DateFormatter.batchDateFormatter.string(from: batchMetadata.startDate)) to \(DateFormatter.batchDateFormatter.string(from: batchMetadata.endDate)) (\(timeSpanDescription))
        - Message count: \(batchMetadata.messageCount) messages
        - Estimated quality: \(String(format: "%.1f%%", batchMetadata.keywordDensity))
        - Financial/relationship keywords: \(batchMetadata.financialKeywordCount + batchMetadata.relationshipKeywordCount) instances
        
        BATCH-SPECIFIC INSTRUCTIONS:
        - Treat this as a temporal snapshot of longer-term behavioral patterns
        - Focus on intra-batch consistency while considering this represents part of a broader personality
        - Weight your confidence based on batch size and content diversity
        - Look for temporal patterns within this specific time window
        - Consider that personality traits should be relatively stable across batches
        
        PERSONALITY TRAITS TO ASSESS:
        
        1. OPENNESS (Intellectual curiosity, creativity, appreciation for variety)
        - Look for: creative language, diverse topics, abstract thinking, cultural references
        - Batch focus: Variety in conversation topics, intellectual engagement patterns
        
        2. CONSCIENTIOUSNESS (Organization, responsibility, self-discipline)
        - Look for: planning behavior, time management, goal-oriented language, reliability
        - Batch focus: Consistency in communication timing, follow-through on commitments mentioned
        
        3. EXTRAVERSION (Energy, positive emotions, social engagement)
        - Look for: social enthusiasm, assertiveness, activity level, positive affect
        - Batch focus: Communication frequency, energy levels, social initiative
        
        4. AGREEABLENESS (Cooperation, empathy, trust, altruism)
        - Look for: cooperative language, empathy expressions, conflict avoidance, helping behavior
        - Batch focus: Interpersonal warmth, conflict resolution, supportive responses
        
        5. NEUROTICISM (Emotional instability, anxiety, mood swings)
        - Look for: stress indicators, emotional volatility, worry, negative affect
        - Batch focus: Emotional volatility within the time period, stress responses, mood consistency
        
        MESSAGE CONTEXT:
        \(messageContext)
        
        OUTPUT FORMAT (JSON only):
        {
          "openness": 0.X,
          "conscientiousness": 0.X,
          "extraversion": 0.X,
          "agreeableness": 0.X,
          "neuroticism": 0.X,
          "confidence": 0.X,
          "analysis_notes": "Key patterns observed in this batch with temporal context"
        }
        """
    }
    
    // MARK: - Trustworthiness Scoring Prompts
    
    /// Generates a prompt for trustworthiness assessment based on communication patterns
    public func createTrustworthinessPrompt(messages: [Message], personalityTraits: PersonalityTraits) -> String {
        let messageContext = formatMessagesForAnalysis(messages)
        let traitContext = formatPersonalityContext(personalityTraits)
        
        return """
        You are a financial analyst specializing in creditworthiness assessment. Analyze communication patterns to evaluate trustworthiness for credit scoring purposes.
        
        ANALYSIS FRAMEWORK:
        - Communication consistency and reliability
        - Financial responsibility indicators
        - Relationship stability patterns
        - Emotional intelligence and self-control
        - Integrity and honesty markers
        
        TRUSTWORTHINESS FACTORS TO EVALUATE:
        
        1. COMMUNICATION_STYLE (0.0-1.0)
        - Consistency in communication patterns
        - Clarity and directness in expression
        - Follow-through on commitments mentioned
        - Professional tone maintenance
        
        2. FINANCIAL_RESPONSIBILITY (0.0-1.0)
        - References to budgeting, saving, planning
        - Attitudes toward money and spending
        - Discussion of financial goals and constraints
        - Evidence of financial discipline
        
        3. RELATIONSHIP_STABILITY (0.0-1.0)
        - Long-term relationship indicators
        - Conflict resolution approaches
        - Loyalty and commitment patterns
        - Social support network strength
        
        4. EMOTIONAL_INTELLIGENCE (0.0-1.0)
        - Self-awareness in communication
        - Empathy toward others
        - Emotional regulation evidence
        - Appropriate social responses
        
        PERSONALITY CONTEXT:
        \(traitContext)
        
        MESSAGE CONTEXT:
        \(messageContext)
        
        OUTPUT FORMAT (JSON only):
        {
          "overall_score": 0.X,
          "factors": {
            "communication_style": 0.X,
            "financial_responsibility": 0.X,
            "relationship_stability": 0.X,
            "emotional_intelligence": 0.X
          },
          "explanation": "Detailed explanation of trustworthiness assessment including key evidence and reasoning",
          "risk_indicators": ["List of any concerning patterns"],
          "positive_indicators": ["List of trustworthiness strengths"]
        }
        """
    }
    
    /// Enhanced trustworthiness prompt that incorporates aggregated personality data and batch summaries
    public func createAggregatedTrustworthinessPrompt(
        messages: [Message], 
        aggregatedTraits: PersonalityTraits, 
        varianceMetrics: PersonalityTraitsVariance?,
        batchSummaries: [BatchSummary]
    ) -> String {
        let messageContext = formatMessagesForAnalysis(messages)
        let traitContext = formatAggregatedPersonalityContext(aggregatedTraits, variance: varianceMetrics)
        let batchContext = formatBatchSummaries(batchSummaries)
        
        return """
        You are a senior financial analyst specializing in comprehensive creditworthiness assessment. You have access to aggregated personality analysis from multiple conversation segments and cross-temporal behavioral patterns.
        
        ENHANCED ANALYSIS FRAMEWORK:
        - Multi-temporal consistency patterns across conversation segments
        - Aggregated personality trait stability and variance
        - Financial and relationship behavioral trends over time
        - Long-term communication reliability indicators
        - Cross-batch pattern recognition for deeper insights
        
        AGGREGATED PERSONALITY INSIGHTS:
        \(traitContext)
        
        TEMPORAL BATCH ANALYSIS:
        \(batchContext)
        
        COMPREHENSIVE TRUSTWORTHINESS EVALUATION:
        
        1. COMMUNICATION_CONSISTENCY (0.0-1.0)
        - Stability of communication patterns across time periods
        - Reliability in maintaining conversational commitments
        - Consistency in tone and engagement levels
        - Long-term relationship maintenance evidence
        
        2. FINANCIAL_BEHAVIORAL_PATTERNS (0.0-1.0)
        - Temporal trends in financial discussions and attitudes
        - Consistency in money-related decision making approaches
        - Evidence of financial planning and goal achievement
        - Budgeting discipline and spending consciousness patterns
        
        3. RELATIONSHIP_STABILITY_TRENDS (0.0-1.0)
        - Long-term relationship commitment indicators
        - Conflict resolution consistency across time periods
        - Social support network maintenance and growth
        - Emotional availability and empathy consistency
        
        4. EMOTIONAL_REGULATION_STABILITY (0.0-1.0)
        - Consistency in emotional responses across different contexts
        - Stress management effectiveness over time
        - Self-awareness and personal growth indicators
        - Adaptability while maintaining core personality stability
        
        5. CROSS_TEMPORAL_INTEGRITY (0.0-1.0)
        - Consistency in values and principles across time periods
        - Reliability in follow-through on stated commitments
        - Honesty and transparency in communication patterns
        - Personal accountability and responsibility indicators
        
        ENHANCED MESSAGE CONTEXT:
        \(messageContext)
        
        OUTPUT FORMAT (JSON only):
        {
          "overall_score": 0.X,
          "factors": {
            "communication_consistency": 0.X,
            "financial_behavioral_patterns": 0.X,
            "relationship_stability_trends": 0.X,
            "emotional_regulation_stability": 0.X,
            "cross_temporal_integrity": 0.X
          },
          "explanation": "Comprehensive explanation incorporating temporal patterns, personality stability, and cross-batch insights",
          "risk_indicators": ["List of concerning patterns with temporal context"],
          "positive_indicators": ["List of trustworthiness strengths with consistency evidence"],
          "stability_assessment": "Analysis of behavioral consistency and variance across time periods"
        }
        """
    }
    
    // MARK: - Specialized Analysis Prompts
    
    /// Creates a prompt for financial behavior pattern analysis
    public func createFinancialBehaviorPrompt(messages: [Message]) -> String {
        let financialMessages = filterFinancialMessages(messages)
        let messageContext = formatMessagesForAnalysis(financialMessages)
        
        return """
        Analyze the following messages for financial behavior patterns relevant to credit assessment:
        
        FOCUS AREAS:
        - Spending discipline and budgeting awareness
        - Financial planning and goal-setting
        - Debt management attitudes
        - Investment and savings behavior
        - Financial stress indicators
        - Money-related decision making
        
        MESSAGE CONTEXT:
        \(messageContext)
        
        Provide a detailed analysis of financial behavioral patterns, responsibility indicators, and any risk factors observed.
        """
    }
    
    /// Creates a prompt for relationship stability assessment
    public func createRelationshipAnalysisPrompt(messages: [Message]) -> String {
        let relationshipMessages = filterRelationshipMessages(messages)
        let messageContext = formatMessagesForAnalysis(relationshipMessages)
        
        return """
        Analyze communication patterns to assess relationship stability and social support:
        
        ASSESSMENT CRITERIA:
        - Communication frequency and consistency with key contacts
        - Conflict resolution and emotional maturity
        - Long-term relationship commitment indicators
        - Social support network breadth and depth
        - Trust and reliability in relationships
        - Emotional availability and empathy
        
        MESSAGE CONTEXT:
        \(messageContext)
        
        Evaluate relationship stability patterns that correlate with creditworthiness and financial responsibility.
        """
    }
    
    // MARK: - Helper Methods
    
    private func formatMessagesForAnalysis(_ messages: [Message]) -> String {
        let sortedMessages = messages.sorted { $0.timestamp < $1.timestamp }
        let formattedMessages = sortedMessages.prefix(100).map { message in
            let sender = message.isFromUser ? "User" : message.sender
            let timestamp = formatTimestamp(message.timestamp)
            return "[\(timestamp)] \(sender): \(message.content)"
        }
        
        return formattedMessages.joined(separator: "\n")
    }
    
    /// Formats messages for batch analysis with enhanced context preservation
    private func formatBatchMessagesForAnalysis(_ messages: [Message], metadata: BatchMetadata) -> String {
        let sortedMessages = messages.sorted { $0.timestamp < $1.timestamp }
        
        // Smart message selection for batch context
        let selectedMessages: [Message]
        if messages.count <= 100 {
            selectedMessages = sortedMessages
        } else {
            // Priority selection: financial keywords > relationship keywords > longest messages > temporal distribution
            selectedMessages = selectMessagesForBatch(sortedMessages, targetCount: 100)
        }
        
        let formattedMessages = selectedMessages.map { message in
            let sender = message.isFromUser ? "User" : message.sender
            let timestamp = formatTimestamp(message.timestamp)
            let content = truncateMessageWithKeywordPreservation(message.content, maxLength: 500)
            return "[\(timestamp)] \(sender): \(content)"
        }
        
        var contextInfo = "BATCH SUMMARY: \(metadata.messageCount) messages, \(metadata.senderCount) senders, "
        contextInfo += "\(String(format: "%.1f", metadata.timeSpanHours)) hours span\n\n"
        
        return contextInfo + formattedMessages.joined(separator: "\n")
    }
    
    private func formatPersonalityContext(_ traits: PersonalityTraits) -> String {
        return """
        Personality Profile:
        - Openness: \(String(format: "%.2f", traits.openness)) (intellectual curiosity: \(interpretScore(traits.openness)))
        - Conscientiousness: \(String(format: "%.2f", traits.conscientiousness)) (self-discipline: \(interpretScore(traits.conscientiousness)))
        - Extraversion: \(String(format: "%.2f", traits.extraversion)) (social energy: \(interpretScore(traits.extraversion)))
        - Agreeableness: \(String(format: "%.2f", traits.agreeableness)) (cooperation: \(interpretScore(traits.agreeableness)))
        - Neuroticism: \(String(format: "%.2f", traits.neuroticism)) (emotional stability: \(interpretScore(1.0 - traits.neuroticism)))
        - Confidence: \(String(format: "%.2f", traits.confidence))
        """
    }
    
    /// Formats aggregated personality context with variance information
    private func formatAggregatedPersonalityContext(_ traits: PersonalityTraits, variance: PersonalityTraitsVariance?) -> String {
        var context = """
        AGGREGATED PERSONALITY PROFILE:
        - Openness: \(String(format: "%.2f", traits.openness)) (\(interpretScore(traits.openness)))
        - Conscientiousness: \(String(format: "%.2f", traits.conscientiousness)) (\(interpretScore(traits.conscientiousness)))
        - Extraversion: \(String(format: "%.2f", traits.extraversion)) (\(interpretScore(traits.extraversion)))
        - Agreeableness: \(String(format: "%.2f", traits.agreeableness)) (\(interpretScore(traits.agreeableness)))
        - Neuroticism: \(String(format: "%.2f", traits.neuroticism)) (\(interpretScore(1.0 - traits.neuroticism)))
        - Overall Confidence: \(String(format: "%.2f", traits.confidence))
        """
        
        if let variance = variance {
            context += """
            
            PERSONALITY STABILITY ANALYSIS:
            - Overall Stability Score: \(String(format: "%.2f", variance.stabilityScore)) (\(interpretStability(variance.stabilityScore)))
            - Average Variance: \(String(format: "%.3f", variance.averageVariance))
            - Trait Consistency: High stability indicates reliable personality assessment across time periods
            """
        }
        
        return context
    }
    
    /// Formats batch summaries for enhanced trustworthiness analysis
    private func formatBatchSummaries(_ summaries: [BatchSummary]) -> String {
        guard !summaries.isEmpty else {
            return "No batch summaries available."
        }
        
        let batchCount = summaries.count
        let totalMessages = summaries.reduce(0) { $0 + $1.messageCount }
        let averageQuality = summaries.reduce(0.0) { $0 + $1.quality } / Double(summaries.count)
        
        var context = """
        TEMPORAL ANALYSIS SUMMARY:
        - Total Batches Processed: \(batchCount)
        - Total Messages Analyzed: \(totalMessages)
        - Average Batch Quality: \(String(format: "%.2f", averageQuality))
        
        BATCH-BY-BATCH INSIGHTS:
        """
        
        for (index, summary) in summaries.enumerated() {
            context += """
            
            Batch \(index + 1): \(summary.messageCount) messages (\(summary.dateRange))
            - Quality: \(String(format: "%.2f", summary.quality))
            - Financial Keywords: \(summary.financialKeywords)
            - Relationship Keywords: \(summary.relationshipKeywords)
            - Key Patterns: \(summary.keyPatterns)
            """
        }
        
        return context
    }
    
    private func interpretScore(_ score: Double) -> String {
        switch score {
        case 0.8...1.0: return "very high"
        case 0.6..<0.8: return "high"
        case 0.4..<0.6: return "moderate"
        case 0.2..<0.4: return "low"
        default: return "very low"
        }
    }
    
    private func interpretStability(_ stability: Double) -> String {
        switch stability {
        case 0.8...1.0: return "very stable"
        case 0.6..<0.8: return "stable"
        case 0.4..<0.6: return "moderately stable"
        case 0.2..<0.4: return "unstable"
        default: return "very unstable"
        }
    }
    
    private func formatTimeSpan(_ hours: Double) -> String {
        if hours < 1 {
            let minutes = Int(hours * 60)
            return "\(minutes) minutes"
        } else if hours < 24 {
            return String(format: "%.1f hours", hours)
        } else {
            let days = hours / 24
            return String(format: "%.1f days", days)
        }
    }
    
    private func filterFinancialMessages(_ messages: [Message]) -> [Message] {
        let financialKeywords = [
            "money", "payment", "pay", "bill", "cost", "price", "expensive", "cheap", "afford",
            "budget", "save", "saving", "spend", "spending", "loan", "debt", "credit", "bank",
            "account", "balance", "cash", "investment", "invest", "financial", "rent", "mortgage",
            "insurance", "tax", "salary", "income", "bonus", "raise", "profit", "loss"
        ]
        
        return messages.filter { message in
            let content = message.content.lowercased()
            return financialKeywords.contains { keyword in
                content.contains(keyword)
            }
        }
    }
    
    private func filterRelationshipMessages(_ messages: [Message]) -> [Message] {
        // Focus on messages with emotional content, relationship references, or interpersonal communication
        let relationshipIndicators = [
            "love", "care", "miss", "relationship", "together", "family", "friend", "support",
            "help", "sorry", "thank", "appreciate", "trust", "honest", "commitment", "promise",
            "understand", "feel", "emotion", "heart", "close", "bond", "connection", "loyalty"
        ]
        
        return messages.filter { message in
            let content = message.content.lowercased()
            return relationshipIndicators.contains { indicator in
                content.contains(indicator)
            } || message.content.count > 50 // Longer messages often contain more personal content
        }
    }
    
    private func formatTimestamp(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: timestamp)
    }
    
    /// Truncates message context to fit within model's context window
    private func truncateContextIfNeeded(_ context: String, maxTokens: Int = 3000) -> String {
        // Simple character-based truncation (roughly 4 characters per token)
        let maxChars = maxTokens * 4
        if context.count > maxChars {
            let truncated = String(context.prefix(maxChars))
            return truncated + "\n\n[MESSAGE CONTEXT TRUNCATED - ANALYSIS BASED ON MOST RECENT MESSAGES]"
        }
        return context
    }
    
    /// Intelligently selects messages for batch analysis
    private func selectMessagesForBatch(_ messages: [Message], targetCount: Int) -> [Message] {
        guard messages.count > targetCount else { return messages }
        
        var selectedMessages: [Message] = []
        let financialMessages = filterFinancialMessages(messages)
        let relationshipMessages = filterRelationshipMessages(messages)
        
        // Add financial messages (up to 30% of target)
        let financialLimit = min(financialMessages.count, targetCount * 30 / 100)
        selectedMessages.append(contentsOf: Array(financialMessages.prefix(financialLimit)))
        
        // Add relationship messages (up to 30% of target)
        let relationshipLimit = min(relationshipMessages.count, targetCount * 30 / 100)
        let uniqueRelationshipMessages = relationshipMessages.filter { !selectedMessages.contains($0) }
        selectedMessages.append(contentsOf: Array(uniqueRelationshipMessages.prefix(relationshipLimit)))
        
        // Add longest messages for context (up to 20% of target)
        let longMessages = messages.sorted { $0.content.count > $1.content.count }
        let longMessageLimit = min(longMessages.count, targetCount * 20 / 100)
        let uniqueLongMessages = longMessages.filter { !selectedMessages.contains($0) }
        selectedMessages.append(contentsOf: Array(uniqueLongMessages.prefix(longMessageLimit)))
        
        // Fill remaining slots with temporal distribution
        let remaining = targetCount - selectedMessages.count
        if remaining > 0 {
            let unusedMessages = messages.filter { !selectedMessages.contains($0) }
            let step = max(1, unusedMessages.count / remaining)
            for i in stride(from: 0, to: unusedMessages.count, by: step) {
                if selectedMessages.count < targetCount {
                    selectedMessages.append(unusedMessages[i])
                }
            }
        }
        
        return Array(selectedMessages.prefix(targetCount))
    }
    
    /// Truncates message content while preserving important keywords
    private func truncateMessageWithKeywordPreservation(_ content: String, maxLength: Int) -> String {
        guard content.count > maxLength else { return content }
        
        let financialKeywords = ["money", "payment", "bill", "budget", "save", "loan", "debt", "credit", "bank", "financial"]
        let relationshipKeywords = ["love", "care", "relationship", "family", "friend", "support", "trust", "commitment"]
        let allKeywords = financialKeywords + relationshipKeywords
        
        let lowercaseContent = content.lowercased()
        let hasKeywords = allKeywords.contains { lowercaseContent.contains($0) }
        
        if hasKeywords {
            // Try to preserve sentences with keywords
            let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            var result = ""
            
            for sentence in sentences {
                let trimmedSentence = sentence.trimmingCharacters(in: .whitespaces)
                if !trimmedSentence.isEmpty {
                    let potentialResult = result.isEmpty ? trimmedSentence : result + ". " + trimmedSentence
                    if potentialResult.count <= maxLength {
                        result = potentialResult
                    } else {
                        break
                    }
                }
            }
            
            return result.isEmpty ? String(content.prefix(maxLength)) + "..." : result + "..."
        } else {
            return String(content.prefix(maxLength)) + "..."
        }
    }
}

// MARK: - Response Parsing

extension PromptEngineer {
    
    /// Parses personality analysis response from LLM output
    public func parsePersonalityResponse(_ response: String) throws -> PersonalityTraits {
        guard let jsonStart = response.range(of: "{"),
              let jsonEnd = response.range(of: "}", options: .backwards) else {
            throw PromptError.invalidResponse("No JSON found in response")
        }
        
        let jsonString = String(response[jsonStart.lowerBound...jsonEnd.upperBound])
        
        guard let data = jsonString.data(using: .utf8) else {
            throw PromptError.invalidResponse("Cannot convert response to data")
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let json = json else {
                throw PromptError.invalidResponse("Invalid JSON structure")
            }
            
            return PersonalityTraits(
                openness: json["openness"] as? Double ?? 0.5,
                conscientiousness: json["conscientiousness"] as? Double ?? 0.5,
                extraversion: json["extraversion"] as? Double ?? 0.5,
                agreeableness: json["agreeableness"] as? Double ?? 0.5,
                neuroticism: json["neuroticism"] as? Double ?? 0.5,
                confidence: json["confidence"] as? Double ?? 0.5
            )
            
        } catch {
            throw PromptError.parsingError("JSON parsing failed: \(error.localizedDescription)")
        }
    }
    
    /// Parses trustworthiness analysis response from LLM output
    public func parseTrustworthinessResponse(_ response: String) throws -> TrustworthinessScore {
        guard let jsonStart = response.range(of: "{"),
              let jsonEnd = response.range(of: "}", options: .backwards) else {
            throw PromptError.invalidResponse("No JSON found in response")
        }
        
        let jsonString = String(response[jsonStart.lowerBound...jsonEnd.upperBound])
        
        guard let data = jsonString.data(using: .utf8) else {
            throw PromptError.invalidResponse("Cannot convert response to data")
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let json = json else {
                throw PromptError.invalidResponse("Invalid JSON structure")
            }
            
            let overallScore = json["overall_score"] as? Double ?? 0.5
            let factorsDict = json["factors"] as? [String: Double] ?? [:]
            let explanation = json["explanation"] as? String ?? "Analysis completed"
            
            return TrustworthinessScore(
                score: overallScore,
                factors: factorsDict,
                explanation: explanation
            )
            
        } catch {
            throw PromptError.parsingError("JSON parsing failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types

/// Summary of key patterns and insights from a single batch
public struct BatchSummary {
    public let batchIndex: Int
    public let messageCount: Int
    public let dateRange: String
    public let quality: Double
    public let financialKeywords: Int
    public let relationshipKeywords: Int
    public let keyPatterns: String
    
    public init(batchIndex: Int, messageCount: Int, dateRange: String, quality: Double, financialKeywords: Int, relationshipKeywords: Int, keyPatterns: String) {
        self.batchIndex = batchIndex
        self.messageCount = messageCount
        self.dateRange = dateRange
        self.quality = quality
        self.financialKeywords = financialKeywords
        self.relationshipKeywords = relationshipKeywords
        self.keyPatterns = keyPatterns
    }
}

// MARK: - Extensions

private extension DateFormatter {
    static let batchDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, HH:mm"
        return formatter
    }()
}

// MARK: - Error Handling

public enum PromptError: Error, LocalizedError {
    case invalidResponse(String)
    case parsingError(String)
    case contextTooLong(String)
    case batchProcessingError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse(let reason):
            return "Invalid LLM response: \(reason)"
        case .parsingError(let reason):
            return "Failed to parse response: \(reason)"
        case .contextTooLong(let reason):
            return "Context too long: \(reason)"
        case .batchProcessingError(let reason):
            return "Batch processing error: \(reason)"
        }
    }
}