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
    
    private func interpretScore(_ score: Double) -> String {
        switch score {
        case 0.8...1.0: return "very high"
        case 0.6..<0.8: return "high"
        case 0.4..<0.6: return "moderate"
        case 0.2..<0.4: return "low"
        default: return "very low"
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

// MARK: - Error Handling

public enum PromptError: Error, LocalizedError {
    case invalidResponse(String)
    case parsingError(String)
    case contextTooLong(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse(let reason):
            return "Invalid LLM response: \(reason)"
        case .parsingError(let reason):
            return "Failed to parse response: \(reason)"
        case .contextTooLong(let reason):
            return "Context too long: \(reason)"
        }
    }
}