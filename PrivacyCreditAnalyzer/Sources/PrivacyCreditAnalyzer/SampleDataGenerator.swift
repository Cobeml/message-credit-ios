import Foundation

/// Generates sample message data for testing personality analysis and trustworthiness scoring
public class SampleDataGenerator {
    
    public init() {}
    
    // MARK: - Sample Data Generation
    
    /// Generates messages for a financially responsible user
    public static func generateResponsibleUserMessages() -> [Message] {
        let baseDate = Date().addingTimeInterval(-86400 * 30) // 30 days ago
        
        return [
            // Financial responsibility indicators
            Message(
                content: "Just finished updating my budget spreadsheet for this month. Staying on track with my savings goal!",
                timestamp: baseDate.addingTimeInterval(0),
                sender: "User",
                recipient: "Sarah",
                isFromUser: true
            ),
            Message(
                content: "I paid my credit card bill in full yesterday. Always do it a few days early to avoid any issues.",
                timestamp: baseDate.addingTimeInterval(3600),
                sender: "User",
                recipient: "Mike",
                isFromUser: true
            ),
            Message(
                content: "Looking at different investment options for my emergency fund. Want to make sure it's growing but still accessible.",
                timestamp: baseDate.addingTimeInterval(7200),
                sender: "User",
                recipient: "Dad",
                isFromUser: true
            ),
            Message(
                content: "Thanks for the dinner invitation! Let me check my budget first to see what I can afford this week.",
                timestamp: baseDate.addingTimeInterval(10800),
                sender: "User",
                recipient: "Emma",
                isFromUser: true
            ),
            Message(
                content: "I've been tracking my expenses for 6 months now. Really helps me understand my spending patterns.",
                timestamp: baseDate.addingTimeInterval(14400),
                sender: "User",
                recipient: "Mom",
                isFromUser: true
            ),
            
            // Relationship stability indicators
            Message(
                content: "Thank you for always being there for me. Your support means everything.",
                timestamp: baseDate.addingTimeInterval(18000),
                sender: "User",
                recipient: "Partner",
                isFromUser: true
            ),
            Message(
                content: "I know we disagreed yesterday, but I appreciate how we worked through it calmly. Communication is so important.",
                timestamp: baseDate.addingTimeInterval(21600),
                sender: "User",
                recipient: "Partner",
                isFromUser: true
            ),
            Message(
                content: "Family dinner this Sunday? I'll bring dessert. Looking forward to seeing everyone!",
                timestamp: baseDate.addingTimeInterval(25200),
                sender: "User",
                recipient: "Sister",
                isFromUser: true
            ),
            
            // Conscientiousness indicators
            Message(
                content: "Finished the project report two days ahead of deadline. Always better to have extra time for review.",
                timestamp: baseDate.addingTimeInterval(28800),
                sender: "User",
                recipient: "Colleague",
                isFromUser: true
            ),
            Message(
                content: "I've scheduled my annual check-ups and updated all my insurance policies. Good to stay on top of these things.",
                timestamp: baseDate.addingTimeInterval(32400),
                sender: "User",
                recipient: "Mom",
                isFromUser: true
            ),
            
            // Long-term planning and goals
            Message(
                content: "Met with my financial advisor today. We're adjusting my retirement contributions to maximize the company match.",
                timestamp: baseDate.addingTimeInterval(36000),
                sender: "User",
                recipient: "Partner",
                isFromUser: true
            ),
            Message(
                content: "I'm thinking of taking that online course next month. It fits well with my career development goals.",
                timestamp: baseDate.addingTimeInterval(39600),
                sender: "User",
                recipient: "Friend",
                isFromUser: true
            ),
            
            // Emotional stability and support
            Message(
                content: "Work has been stressful, but I'm managing it well. Meditation and exercise really help me stay balanced.",
                timestamp: baseDate.addingTimeInterval(43200),
                sender: "User",
                recipient: "Best Friend",
                isFromUser: true
            ),
            Message(
                content: "I saw your post about the tough time you're going through. I'm here if you need to talk or want company.",
                timestamp: baseDate.addingTimeInterval(46800),
                sender: "User",
                recipient: "Colleague",
                isFromUser: true
            ),
            Message(
                content: "Thanks for the advice on the mortgage application. Your experience really helped me prepare better.",
                timestamp: baseDate.addingTimeInterval(50400),
                sender: "User",
                recipient: "Uncle",
                isFromUser: true
            )
        ]
    }
    
    /// Generates messages for a financially irresponsible user
    public static func generateIrresponsibleUserMessages() -> [Message] {
        let baseDate = Date().addingTimeInterval(-86400 * 30) // 30 days ago
        
        return [
            // Financial irresponsibility indicators
            Message(
                content: "Ugh, got another overdraft fee. Third one this month. Banks are such a scam!",
                timestamp: baseDate.addingTimeInterval(0),
                sender: "User",
                recipient: "Jake",
                isFromUser: true
            ),
            Message(
                content: "My credit card is maxed out again 😭 I have no idea where all my money goes",
                timestamp: baseDate.addingTimeInterval(3600),
                sender: "User",
                recipient: "Lisa",
                isFromUser: true
            ),
            Message(
                content: "Just bought this amazing jacket on sale! Only $300. I deserve nice things even if I can't really afford it right now.",
                timestamp: baseDate.addingTimeInterval(7200),
                sender: "User",
                recipient: "Mom",
                isFromUser: true
            ),
            Message(
                content: "Can you lend me $200? I'll pay you back next week I promise. I'm just short on rent money.",
                timestamp: baseDate.addingTimeInterval(10800),
                sender: "User",
                recipient: "Brother",
                isFromUser: true
            ),
            Message(
                content: "I keep meaning to do a budget but it's so boring. I just try not to look at my bank account too much lol",
                timestamp: baseDate.addingTimeInterval(14400),
                sender: "User",
                recipient: "Friend",
                isFromUser: true
            ),
            
            // Relationship instability indicators  
            Message(
                content: "We had another huge fight about money. I don't know why they're always on my case about spending.",
                timestamp: baseDate.addingTimeInterval(18000),
                sender: "User",
                recipient: "Bestie",
                isFromUser: true
            ),
            Message(
                content: "I'm so tired of everyone judging my choices. Maybe I need new friends who understand me better.",
                timestamp: baseDate.addingTimeInterval(21600),
                sender: "User",
                recipient: "Cousin",
                isFromUser: true
            ),
            Message(
                content: "Can't make it to dinner Sunday. Something came up (translation: I'm broke and embarrassed)",
                timestamp: baseDate.addingTimeInterval(25200),
                sender: "User",
                recipient: "Sister",
                isFromUser: true
            ),
            
            // Poor planning and impulsiveness
            Message(
                content: "Totally forgot about the deadline until this morning. Going to have to rush through this project.",
                timestamp: baseDate.addingTimeInterval(28800),
                sender: "User",
                recipient: "Coworker",
                isFromUser: true
            ),
            Message(
                content: "I keep putting off going to the dentist. I know I need to but appointments are such a hassle.",
                timestamp: baseDate.addingTimeInterval(32400),
                sender: "User",
                recipient: "Mom",
                isFromUser: true
            ),
            
            // Short-term thinking
            Message(
                content: "Why should I save for retirement? That's like 40 years away. I want to enjoy life now!",
                timestamp: baseDate.addingTimeInterval(36000),
                sender: "User",
                recipient: "Dad",
                isFromUser: true
            ),
            Message(
                content: "Saw this get-rich-quick opportunity online. Thinking of investing my last $500. Could turn into thousands!",
                timestamp: baseDate.addingTimeInterval(39600),
                sender: "User",
                recipient: "Friend",
                isFromUser: true
            ),
            
            // Emotional volatility and poor coping
            Message(
                content: "Everything is falling apart!!! I hate my job, I'm broke, and nobody understands me 😭😭😭",
                timestamp: baseDate.addingTimeInterval(43200),
                sender: "User",
                recipient: "Journal App",
                isFromUser: true
            ),
            Message(
                content: "Going out to party tonight even though I can't afford it. I need to blow off steam somehow.",
                timestamp: baseDate.addingTimeInterval(46800),
                sender: "User",
                recipient: "Party Friend",
                isFromUser: true
            ),
            Message(
                content: "I don't need anyone's help or advice. I can figure this out on my own eventually.",
                timestamp: baseDate.addingTimeInterval(50400),
                sender: "User",
                recipient: "Mom",
                isFromUser: true
            )
        ]
    }
    
    // MARK: - JSON Export Functions
    
    /// Exports responsible user messages as JSON string
    public static func responsibleUserJSON() -> String {
        let messages = generateResponsibleUserMessages()
        return exportMessagesToJSON(messages, title: "Responsible User Sample")
    }
    
    /// Exports irresponsible user messages as JSON string  
    public static func irresponsibleUserJSON() -> String {
        let messages = generateIrresponsibleUserMessages()
        return exportMessagesToJSON(messages, title: "Irresponsible User Sample")
    }
    
    private static func exportMessagesToJSON(_ messages: [Message], title: String) -> String {
        let exportData: [String: Any] = [
            "export_info": [
                "title": title,
                "created_date": ISO8601DateFormatter().string(from: Date()),
                "message_count": messages.count,
                "date_range": [
                    "start": ISO8601DateFormatter().string(from: messages.first?.timestamp ?? Date()),
                    "end": ISO8601DateFormatter().string(from: messages.last?.timestamp ?? Date())
                ]
            ],
            "messages": messages.map { message in
                [
                    "id": message.id.uuidString,
                    "content": message.content,
                    "timestamp": ISO8601DateFormatter().string(from: message.timestamp),
                    "sender": message.sender,
                    "recipient": message.recipient,
                    "isFromUser": message.isFromUser
                ]
            }
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
            return String(data: jsonData, encoding: .utf8) ?? "{\"error\": \"Failed to encode JSON\"}"
        } catch {
            return "{\"error\": \"JSON serialization failed: \(error.localizedDescription)\"}"
        }
    }
    
    // MARK: - Analysis Results Storage
    
    /// Stores analysis results for easy frontend loading
    public static func storeAnalysisResults(_ responsibleResult: AnalysisResult, _ irresponsibleResult: AnalysisResult) {
        UserDefaults.standard.set(try? JSONEncoder().encode(responsibleResult), forKey: "sample_responsible_result")
        UserDefaults.standard.set(try? JSONEncoder().encode(irresponsibleResult), forKey: "sample_irresponsible_result")
    }
    
    /// Retrieves stored analysis results
    public static func getStoredResults() -> (responsible: AnalysisResult?, irresponsible: AnalysisResult?) {
        let responsibleData = UserDefaults.standard.data(forKey: "sample_responsible_result")
        let irresponsibleData = UserDefaults.standard.data(forKey: "sample_irresponsible_result")
        
        let responsible = responsibleData.flatMap { try? JSONDecoder().decode(AnalysisResult.self, from: $0) }
        let irresponsible = irresponsibleData.flatMap { try? JSONDecoder().decode(AnalysisResult.self, from: $0) }
        
        return (responsible, irresponsible)
    }
}

// MARK: - Sample Analysis Results

extension SampleDataGenerator {
    
    /// Expected analysis result for responsible user
    public static func expectedResponsibleResult() -> AnalysisResult {
        let traits = PersonalityTraits(
            openness: 0.65,           // Moderate-high (learning, planning, growth mindset)
            conscientiousness: 0.88,  // Very high (budgeting, planning, early payments)  
            extraversion: 0.55,       // Moderate (social but balanced)
            agreeableness: 0.82,      // High (supportive, collaborative, family-oriented)
            neuroticism: 0.22,        // Low (stable, manages stress well)
            confidence: 0.85          // High confidence based on consistent patterns
        )
        
        let trustworthiness = TrustworthinessScore(
            score: 0.84, // High trustworthiness
            factors: [
                "communication_style": 0.80,      // Clear, honest, consistent communication
                "financial_responsibility": 0.92, // Excellent budgeting, planning, payment history
                "relationship_stability": 0.85,   // Strong family bonds, conflict resolution
                "emotional_intelligence": 0.78    // Good self-awareness, supports others
            ],
            explanation: "Analysis indicates high creditworthiness based on consistent financial planning, early bill payments, active budgeting, and strong relationship stability. User demonstrates excellent self-control, long-term thinking, and reliable communication patterns. Low risk indicators with strong positive financial behaviors."
        )
        
        return AnalysisResult(
            personalityTraits: traits,
            trustworthinessScore: trustworthiness,
            messageCount: 15,
            processingTime: 2.3
        )
    }
    
    /// Expected analysis result for irresponsible user
    public static func expectedIrresponsibleResult() -> AnalysisResult {
        let traits = PersonalityTraits(
            openness: 0.45,           // Below average (impulsive choices, get-rich-quick thinking)
            conscientiousness: 0.18,  // Very low (poor planning, missed deadlines, avoidance)
            extraversion: 0.72,       // High (social, outgoing, party-focused)
            agreeableness: 0.35,      // Below average (defensive, blames others)
            neuroticism: 0.78,        // High (emotional volatility, stress reactions)
            confidence: 0.32          // Low confidence due to inconsistent patterns
        )
        
        let trustworthiness = TrustworthinessScore(
            score: 0.23, // Low trustworthiness
            factors: [
                "communication_style": 0.28,      // Defensive, blaming, inconsistent
                "financial_responsibility": 0.12, // Overdrafts, maxed cards, borrowing, poor planning
                "relationship_stability": 0.31,   // Conflict, avoidance, isolation patterns  
                "emotional_intelligence": 0.22    // Poor self-awareness, impulsive reactions
            ],
            explanation: "Analysis indicates significant credit risk based on poor financial management, frequent overdrafts, maxed credit cards, and impulsive spending behaviors. User shows low conscientiousness, high emotional volatility, and strained relationships. Multiple red flags including borrowing from family, avoidance of responsibilities, and short-term thinking patterns."
        )
        
        return AnalysisResult(
            personalityTraits: traits,
            trustworthinessScore: trustworthiness,
            messageCount: 15,
            processingTime: 2.1
        )
    }
}