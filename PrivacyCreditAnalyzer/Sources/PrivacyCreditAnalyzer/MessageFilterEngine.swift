import Foundation

/// Engine for filtering messages based on various strategies
public class MessageFilterEngine {
    
    public init() {}
    
    /// Filtering strategies available
    public enum FilterStrategy {
        case all
        case lovedOnes
        case financialKeywords
        case combined(lovedOnes: Bool, financialKeywords: Bool)
    }
    
    /// Configuration for filtering behavior
    public struct FilterConfiguration {
        public let minMessageFrequency: Int
        public let relationshipScoreThreshold: Double
        public let financialKeywordWeight: Double
        public let emotionalContentWeight: Double
        
        public init(
            minMessageFrequency: Int = 10,
            relationshipScoreThreshold: Double = 0.6,
            financialKeywordWeight: Double = 1.0,
            emotionalContentWeight: Double = 0.8
        ) {
            self.minMessageFrequency = minMessageFrequency
            self.relationshipScoreThreshold = relationshipScoreThreshold
            self.financialKeywordWeight = financialKeywordWeight
            self.emotionalContentWeight = emotionalContentWeight
        }
    }
    
    /// Result of filtering operation
    public struct FilterResult {
        public let filteredMessages: [Message]
        public let totalOriginalCount: Int
        public let filteringStats: FilteringStats
        
        public init(filteredMessages: [Message], totalOriginalCount: Int, filteringStats: FilteringStats) {
            self.filteredMessages = filteredMessages
            self.totalOriginalCount = totalOriginalCount
            self.filteringStats = filteringStats
        }
    }
    
    /// Statistics about the filtering operation
    public struct FilteringStats {
        public let lovedOnesCount: Int
        public let financialMessagesCount: Int
        public let relationshipScores: [String: Double]
        public let topFinancialKeywords: [String: Int]
        
        public init(
            lovedOnesCount: Int,
            financialMessagesCount: Int,
            relationshipScores: [String: Double],
            topFinancialKeywords: [String: Int]
        ) {
            self.lovedOnesCount = lovedOnesCount
            self.financialMessagesCount = financialMessagesCount
            self.relationshipScores = relationshipScores
            self.topFinancialKeywords = topFinancialKeywords
        }
    }
    
    /// Filters messages based on the specified strategy
    /// - Parameters:
    ///   - messages: Array of messages to filter
    ///   - strategy: Filtering strategy to apply
    ///   - configuration: Configuration for filtering behavior
    /// - Returns: FilterResult containing filtered messages and statistics
    public func filterMessages(
        _ messages: [Message],
        strategy: FilterStrategy,
        configuration: FilterConfiguration = FilterConfiguration()
    ) -> FilterResult {
        
        let originalCount = messages.count
        var filteredMessages: [Message] = []
        
        // Calculate relationship scores for all contacts
        let relationshipScores = calculateRelationshipScores(messages, configuration: configuration)
        
        // Identify financial messages
        let financialMessages = identifyFinancialMessages(messages)
        let financialKeywordStats = calculateFinancialKeywordStats(messages)
        
        // Apply filtering strategy
        switch strategy {
        case .all:
            filteredMessages = messages
            
        case .lovedOnes:
            filteredMessages = filterByLovedOnes(messages, relationshipScores: relationshipScores, configuration: configuration)
            
        case .financialKeywords:
            filteredMessages = Array(financialMessages)
            
        case .combined(let includeLovedOnes, let includeFinancial):
            var combinedSet = Set<Message>()
            
            if includeLovedOnes {
                let lovedOnesMessages = filterByLovedOnes(messages, relationshipScores: relationshipScores, configuration: configuration)
                combinedSet.formUnion(lovedOnesMessages)
            }
            
            if includeFinancial {
                combinedSet.formUnion(financialMessages)
            }
            
            filteredMessages = Array(combinedSet).sorted { $0.timestamp < $1.timestamp }
        }
        
        let stats = FilteringStats(
            lovedOnesCount: filterByLovedOnes(messages, relationshipScores: relationshipScores, configuration: configuration).count,
            financialMessagesCount: financialMessages.count,
            relationshipScores: relationshipScores,
            topFinancialKeywords: financialKeywordStats
        )
        
        return FilterResult(
            filteredMessages: filteredMessages,
            totalOriginalCount: originalCount,
            filteringStats: stats
        )
    }
    
    /// Calculates relationship scores for all contacts based on message frequency and content
    private func calculateRelationshipScores(_ messages: [Message], configuration: FilterConfiguration) -> [String: Double] {
        var contactStats: [String: ContactStats] = [:]
        
        // Collect statistics for each contact
        for message in messages {
            let contact = message.isFromUser ? message.recipient : message.sender
            
            if contactStats[contact] == nil {
                contactStats[contact] = ContactStats()
            }
            
            contactStats[contact]!.messageCount += 1
            contactStats[contact]!.totalContentLength += message.content.count
            
            // Check for emotional indicators
            if containsEmotionalContent(message.content) {
                contactStats[contact]!.emotionalMessageCount += 1
            }
            
            // Check for personal indicators
            if containsPersonalContent(message.content) {
                contactStats[contact]!.personalMessageCount += 1
            }
            
            // Track conversation patterns
            contactStats[contact]!.lastMessageDate = max(contactStats[contact]!.lastMessageDate ?? Date.distantPast, message.timestamp)
        }
        
        // Calculate relationship scores
        var relationshipScores: [String: Double] = [:]
        let maxMessageCount = contactStats.values.map { $0.messageCount }.max() ?? 1
        
        for (contact, stats) in contactStats {
            guard stats.messageCount >= configuration.minMessageFrequency else {
                relationshipScores[contact] = 0.0
                continue
            }
            
            // Frequency score (0.0 to 1.0)
            let frequencyScore = Double(stats.messageCount) / Double(maxMessageCount)
            
            // Emotional content score (0.0 to 1.0)
            let emotionalScore = Double(stats.emotionalMessageCount) / Double(stats.messageCount)
            
            // Personal content score (0.0 to 1.0)
            let personalScore = Double(stats.personalMessageCount) / Double(stats.messageCount)
            
            // Recency score (0.0 to 1.0) - more recent conversations score higher
            let daysSinceLastMessage = Date().timeIntervalSince(stats.lastMessageDate ?? Date.distantPast) / (24 * 60 * 60)
            let recencyScore = max(0.0, 1.0 - (daysSinceLastMessage / 365.0)) // Decay over a year
            
            // Combined relationship score
            let relationshipScore = (
                frequencyScore * 0.4 +
                emotionalScore * configuration.emotionalContentWeight * 0.3 +
                personalScore * 0.2 +
                recencyScore * 0.1
            )
            
            relationshipScores[contact] = min(1.0, relationshipScore)
        }
        
        return relationshipScores
    }
    
    /// Filters messages to include only those from loved ones
    private func filterByLovedOnes(_ messages: [Message], relationshipScores: [String: Double], configuration: FilterConfiguration) -> [Message] {
        return messages.filter { message in
            let contact = message.isFromUser ? message.recipient : message.sender
            let score = relationshipScores[contact] ?? 0.0
            return score >= configuration.relationshipScoreThreshold
        }
    }
    
    /// Identifies messages containing financial keywords or content
    private func identifyFinancialMessages(_ messages: [Message]) -> Set<Message> {
        let financialKeywords = getFinancialKeywords()
        var financialMessages = Set<Message>()
        
        for message in messages {
            let content = message.content.lowercased()
            
            // Check for direct financial keywords
            for keyword in financialKeywords {
                if content.contains(keyword.lowercased()) {
                    financialMessages.insert(message)
                    break
                }
            }
            
            // Check for currency patterns
            if containsCurrencyPatterns(content) {
                financialMessages.insert(message)
            }
            
            // Check for financial context patterns
            if containsFinancialContext(content) {
                financialMessages.insert(message)
            }
        }
        
        return financialMessages
    }
    
    /// Calculates statistics about financial keywords usage
    private func calculateFinancialKeywordStats(_ messages: [Message]) -> [String: Int] {
        let financialKeywords = getFinancialKeywords()
        var keywordCounts: [String: Int] = [:]
        
        for message in messages {
            let content = message.content.lowercased()
            
            for keyword in financialKeywords {
                if content.contains(keyword.lowercased()) {
                    keywordCounts[keyword, default: 0] += 1
                }
            }
        }
        
        // Return top 10 most frequent keywords
        let topKeywords = keywordCounts.sorted { $0.value > $1.value }.prefix(10)
        return Dictionary(uniqueKeysWithValues: topKeywords.map { ($0.key, $0.value) })
    }
    
    /// Returns list of financial keywords to search for
    private func getFinancialKeywords() -> [String] {
        return [
            // Money terms
            "money", "cash", "dollar", "dollars", "$", "cent", "cents",
            "payment", "pay", "paid", "paying", "cost", "costs", "price", "expensive", "cheap",
            
            // Banking terms
            "bank", "account", "deposit", "withdraw", "transfer", "atm",
            "credit", "debit", "card", "balance", "statement",
            
            // Lending terms
            "loan", "lend", "borrow", "borrowed", "lending", "debt", "owe", "owed", "owes",
            "mortgage", "interest", "rate", "finance", "financing",
            
            // Investment terms
            "invest", "investment", "stock", "stocks", "bond", "bonds", "portfolio",
            "401k", "retirement", "savings", "save", "saved",
            
            // Bills and expenses
            "bill", "bills", "rent", "utilities", "electric", "gas", "water",
            "insurance", "tax", "taxes", "fee", "fees", "charge", "charges",
            
            // Income terms
            "salary", "wage", "wages", "income", "paycheck", "bonus", "raise",
            "job", "work", "employment", "unemployed",
            
            // Shopping terms
            "buy", "bought", "purchase", "purchased", "shopping", "store", "mall",
            "sale", "discount", "coupon", "deal", "bargain",
            
            // Emergency financial terms
            "emergency", "urgent", "help", "need", "broke", "short", "tight",
            "crisis", "problem", "trouble", "desperate"
        ]
    }
    
    /// Checks if content contains currency patterns like $100, €50, etc.
    private func containsCurrencyPatterns(_ content: String) -> Bool {
        let currencyPatterns = [
            "\\$\\d+",           // $100
            "€\\d+",             // €100
            "£\\d+",             // £100
            "¥\\d+",             // ¥100
            "\\d+\\s*dollars?",  // 100 dollars
            "\\d+\\s*euros?",    // 100 euros
            "\\d+\\s*pounds?",   // 100 pounds
            "\\d+\\s*cents?",    // 50 cents
            "\\d+\\.\\d{2}",     // 100.50 (decimal currency)
        ]
        
        for pattern in currencyPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: content.count)
                if regex.firstMatch(in: content, options: [], range: range) != nil {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Checks if content contains financial context patterns
    private func containsFinancialContext(_ content: String) -> Bool {
        let contextPatterns = [
            "can you lend",
            "need to borrow",
            "pay you back",
            "short on cash",
            "tight on money",
            "financial help",
            "money problems",
            "can't afford",
            "need money",
            "help with rent",
            "cover the cost",
            "split the bill",
            "venmo me",
            "paypal me",
            "zelle me",
            "cash app"
        ]
        
        let lowercaseContent = content.lowercased()
        
        for pattern in contextPatterns {
            if lowercaseContent.contains(pattern) {
                return true
            }
        }
        
        return false
    }
    
    /// Checks if content contains emotional indicators
    private func containsEmotionalContent(_ content: String) -> Bool {
        let emotionalIndicators = [
            // Positive emotions
            "love", "loved", "loving", "heart", "❤️", "💕", "💖", "😍", "🥰",
            "happy", "joy", "excited", "amazing", "wonderful", "great", "awesome",
            "thank", "thanks", "grateful", "appreciate", "blessed",
            
            // Negative emotions
            "sad", "upset", "angry", "frustrated", "worried", "stress", "stressed",
            "anxious", "depressed", "hurt", "pain", "crying", "😢", "😭", "😔",
            "sorry", "apologize", "regret", "mistake", "wrong",
            
            // Support and care
            "care", "caring", "support", "help", "there for you", "thinking of you",
            "miss", "missed", "missing", "hug", "hugs", "🤗", "comfort",
            
            // Family and relationship terms
            "family", "mom", "dad", "mother", "father", "sister", "brother",
            "daughter", "son", "wife", "husband", "girlfriend", "boyfriend",
            "best friend", "close friend", "dear", "honey", "sweetie", "babe"
        ]
        
        let lowercaseContent = content.lowercased()
        
        for indicator in emotionalIndicators {
            if lowercaseContent.contains(indicator) {
                return true
            }
        }
        
        return false
    }
    
    /// Checks if content contains personal indicators
    private func containsPersonalContent(_ content: String) -> Bool {
        let personalIndicators = [
            // Personal sharing
            "tell you", "share with you", "between us", "personal", "private",
            "secret", "confidential", "just between", "don't tell",
            
            // Life events
            "birthday", "anniversary", "wedding", "graduation", "promotion",
            "vacation", "trip", "holiday", "celebration", "party",
            "hospital", "doctor", "sick", "health", "medical",
            
            // Personal problems
            "problem", "issue", "trouble", "difficult", "hard time",
            "going through", "dealing with", "struggling", "challenge",
            
            // Personal achievements
            "proud", "accomplished", "achieved", "success", "won", "got the job",
            "passed", "finished", "completed", "milestone",
            
            // Personal plans
            "planning", "thinking about", "considering", "might", "probably",
            "future", "next year", "someday", "hope", "dream", "goal"
        ]
        
        let lowercaseContent = content.lowercased()
        
        for indicator in personalIndicators {
            if lowercaseContent.contains(indicator) {
                return true
            }
        }
        
        return false
    }
    
    /// Gets the top contacts by relationship score
    public func getTopContacts(_ messages: [Message], limit: Int = 10, configuration: FilterConfiguration = FilterConfiguration()) -> [(contact: String, score: Double)] {
        let relationshipScores = calculateRelationshipScores(messages, configuration: configuration)
        
        return relationshipScores
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (contact: $0.key, score: $0.value) }
    }
    
    /// Gets financial message statistics
    public func getFinancialStats(_ messages: [Message]) -> (totalFinancial: Int, topKeywords: [String: Int], averageLength: Double) {
        let financialMessages = identifyFinancialMessages(messages)
        let keywordStats = calculateFinancialKeywordStats(messages)
        
        let averageLength = financialMessages.isEmpty ? 0.0 : 
            Double(financialMessages.map { $0.content.count }.reduce(0, +)) / Double(financialMessages.count)
        
        return (
            totalFinancial: financialMessages.count,
            topKeywords: keywordStats,
            averageLength: averageLength
        )
    }
}

/// Helper struct for tracking contact statistics
private struct ContactStats {
    var messageCount: Int = 0
    var totalContentLength: Int = 0
    var emotionalMessageCount: Int = 0
    var personalMessageCount: Int = 0
    var lastMessageDate: Date?
}