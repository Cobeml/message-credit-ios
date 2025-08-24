import Foundation

// Simple test script to generate and analyze sample data
print("🎯 Privacy Credit Analyzer - Sample Data Analysis")
print(String(repeating: "=", count: 60))

// Mock analysis based on message content
func analyzeMessages(_ messages: [(content: String, isFromUser: Bool)], userType: String) -> (personality: [String: Double], trustworthiness: Double, factors: [String: Double]) {
    
    var indicators: [String: Int] = [
        "financial_positive": 0,
        "financial_negative": 0,
        "emotional_stable": 0,
        "emotional_volatile": 0,
        "relationship_positive": 0,
        "relationship_negative": 0,
        "planning_good": 0,
        "planning_poor": 0
    ]
    
    for message in messages where message.isFromUser {
        let content = message.content.lowercased()
        
        // Count indicators
        if content.contains("budget") || content.contains("save") || content.contains("plan") || content.contains("investment") {
            indicators["financial_positive"]! += 1
        }
        if content.contains("overdraft") || content.contains("maxed out") || content.contains("broke") || content.contains("lend me") {
            indicators["financial_negative"]! += 1
        }
        if content.contains("calm") || content.contains("stable") || content.contains("manage") || content.contains("balance") {
            indicators["emotional_stable"]! += 1
        }
        if content.contains("😭") || content.contains("hate") || content.contains("falling apart") || content.contains("everything is") {
            indicators["emotional_volatile"]! += 1
        }
        if content.contains("family") || content.contains("support") || content.contains("thank") || content.contains("appreciate") {
            indicators["relationship_positive"]! += 1
        }
        if content.contains("fight") || content.contains("judge") || content.contains("tired of") || content.contains("nobody understands") {
            indicators["relationship_negative"]! += 1
        }
        if content.contains("ahead") || content.contains("schedule") || content.contains("finish") || content.contains("deadline") {
            indicators["planning_good"]! += 1
        }
        if content.contains("forgot") || content.contains("rush") || content.contains("putting off") || content.contains("no idea where") {
            indicators["planning_poor"]! += 1
        }
    }
    
    // Calculate personality traits based on indicators
    let messageCount = Double(messages.filter { $0.isFromUser }.count)
    
    let openness = userType == "responsible" ? 
        min(1.0, 0.60 + (Double(indicators["planning_good"]!) / messageCount) * 0.3) :
        max(0.2, 0.45 - (Double(indicators["planning_poor"]!) / messageCount) * 0.2)
    
    let conscientiousness = userType == "responsible" ?
        min(1.0, 0.70 + (Double(indicators["financial_positive"]!) / messageCount) * 0.25) :
        max(0.1, 0.35 - (Double(indicators["financial_negative"]!) / messageCount) * 0.25)
    
    let extraversion = userType == "responsible" ? 0.55 : 0.72
    
    let agreeableness = userType == "responsible" ?
        min(1.0, 0.75 + (Double(indicators["relationship_positive"]!) / messageCount) * 0.2) :
        max(0.2, 0.40 - (Double(indicators["relationship_negative"]!) / messageCount) * 0.2)
    
    let neuroticism = userType == "responsible" ?
        max(0.1, 0.25 - (Double(indicators["emotional_stable"]!) / messageCount) * 0.15) :
        min(0.9, 0.65 + (Double(indicators["emotional_volatile"]!) / messageCount) * 0.25)
    
    let confidence = userType == "responsible" ? 0.82 : 0.28
    
    let personality = [
        "openness": openness,
        "conscientiousness": conscientiousness,
        "extraversion": extraversion,
        "agreeableness": agreeableness,
        "neuroticism": neuroticism,
        "confidence": confidence
    ]
    
    // Calculate trustworthiness
    let financialScore = userType == "responsible" ?
        min(1.0, 0.85 + (Double(indicators["financial_positive"]!) / messageCount) * 0.15) :
        max(0.1, 0.25 - (Double(indicators["financial_negative"]!) / messageCount) * 0.15)
    
    let communicationScore = agreeableness * 0.9
    let relationshipScore = userType == "responsible" ?
        min(1.0, 0.80 + (Double(indicators["relationship_positive"]!) / messageCount) * 0.15) :
        max(0.1, 0.35 - (Double(indicators["relationship_negative"]!) / messageCount) * 0.15)
    let emotionalScore = max(0.1, 1.0 - neuroticism)
    
    let trustworthiness = (financialScore + communicationScore + relationshipScore + emotionalScore) / 4.0
    
    let factors = [
        "financial_responsibility": financialScore,
        "communication_style": communicationScore,
        "relationship_stability": relationshipScore,
        "emotional_intelligence": emotionalScore
    ]
    
    return (personality, trustworthiness, factors)
}

// Sample messages for responsible user
let responsibleMessages = [
    ("Just finished updating my budget spreadsheet for this month. Staying on track with my savings goal!", true),
    ("I paid my credit card bill in full yesterday. Always do it a few days early to avoid any issues.", true),
    ("Looking at different investment options for my emergency fund. Want to make sure it's growing but still accessible.", true),
    ("Thanks for the dinner invitation! Let me check my budget first to see what I can afford this week.", true),
    ("I've been tracking my expenses for 6 months now. Really helps me understand my spending patterns.", true),
    ("Thank you for always being there for me. Your support means everything.", true),
    ("I know we disagreed yesterday, but I appreciate how we worked through it calmly. Communication is so important.", true),
    ("Family dinner this Sunday? I'll bring dessert. Looking forward to seeing everyone!", true),
    ("Finished the project report two days ahead of deadline. Always better to have extra time for review.", true),
    ("I've scheduled my annual check-ups and updated all my insurance policies. Good to stay on top of these things.", true),
    ("Met with my financial advisor today. We're adjusting my retirement contributions to maximize the company match.", true),
    ("I'm thinking of taking that online course next month. It fits well with my career development goals.", true),
    ("Work has been stressful, but I'm managing it well. Meditation and exercise really help me stay balanced.", true),
    ("I saw your post about the tough time you're going through. I'm here if you need to talk or want company.", true),
    ("Thanks for the advice on the mortgage application. Your experience really helped me prepare better.", true)
]

// Sample messages for irresponsible user
let irresponsibleMessages = [
    ("Ugh, got another overdraft fee. Third one this month. Banks are such a scam!", true),
    ("My credit card is maxed out again 😭 I have no idea where all my money goes", true),
    ("Just bought this amazing jacket on sale! Only $300. I deserve nice things even if I can't really afford it right now.", true),
    ("Can you lend me $200? I'll pay you back next week I promise. I'm just short on rent money.", true),
    ("I keep meaning to do a budget but it's so boring. I just try not to look at my bank account too much lol", true),
    ("We had another huge fight about money. I don't know why they're always on my case about spending.", true),
    ("I'm so tired of everyone judging my choices. Maybe I need new friends who understand me better.", true),
    ("Can't make it to dinner Sunday. Something came up (translation: I'm broke and embarrassed)", true),
    ("Totally forgot about the deadline until this morning. Going to have to rush through this project.", true),
    ("I keep putting off going to the dentist. I know I need to but appointments are such a hassle.", true),
    ("Why should I save for retirement? That's like 40 years away. I want to enjoy life now!", true),
    ("Saw this get-rich-quick opportunity online. Thinking of investing my last $500. Could turn into thousands!", true),
    ("Everything is falling apart!!! I hate my job, I'm broke, and nobody understands me 😭😭😭", true),
    ("Going out to party tonight even though I can't afford it. I need to blow off steam somehow.", true),
    ("I don't need anyone's help or advice. I can figure this out on my own eventually.", true)
]

// Run analysis
print("\n🔍 Analyzing responsible user messages...")
let responsibleResult = analyzeMessages(responsibleMessages, userType: "responsible")

print("\n🔍 Analyzing irresponsible user messages...")
let irresponsibleResult = analyzeMessages(irresponsibleMessages, userType: "irresponsible")

// Display results
print("\n" + String(repeating: "=", count: 60))
print("📊 ANALYSIS RESULTS COMPARISON")
print(String(repeating: "=", count: 60))

print("\n🏆 RESPONSIBLE USER RESULTS:")
print("💭 Personality Traits:")
for (trait, score) in responsibleResult.personality.sorted(by: { $0.key < $1.key }) {
    print("   \(trait.capitalized): \(String(format: "%.3f", score))")
}
print("🏦 Trustworthiness Score: \(String(format: "%.3f", responsibleResult.trustworthiness))")
print("📊 Factor Breakdown:")
for (factor, score) in responsibleResult.factors.sorted(by: { $0.key < $1.key }) {
    print("   \(factor.replacingOccurrences(of: "_", with: " ").capitalized): \(String(format: "%.3f", score))")
}

print("\n📉 IRRESPONSIBLE USER RESULTS:")
print("💭 Personality Traits:")
for (trait, score) in irresponsibleResult.personality.sorted(by: { $0.key < $1.key }) {
    print("   \(trait.capitalized): \(String(format: "%.3f", score))")
}
print("🏦 Trustworthiness Score: \(String(format: "%.3f", irresponsibleResult.trustworthiness))")
print("📊 Factor Breakdown:")
for (factor, score) in irresponsibleResult.factors.sorted(by: { $0.key < $1.key }) {
    print("   \(factor.replacingOccurrences(of: "_", with: " ").capitalized): \(String(format: "%.3f", score))")
}

print("\n📈 COMPARISON SUMMARY:")
print("Trustworthiness Gap: \(String(format: "+%.3f", responsibleResult.trustworthiness - irresponsibleResult.trustworthiness)) (\(Int((responsibleResult.trustworthiness - irresponsibleResult.trustworthiness) * 100))% difference)")

func getRiskLevel(_ score: Double) -> String {
    switch score {
    case 0.8...1.0: return "🟢 LOW RISK - Excellent creditworthiness"
    case 0.6..<0.8: return "🟡 MEDIUM RISK - Good creditworthiness"  
    case 0.4..<0.6: return "🟠 HIGH RISK - Poor creditworthiness"
    default: return "🔴 VERY HIGH RISK - Significant credit risk"
    }
}

print("\n⚠️ CREDIT RISK ASSESSMENT:")
print("Responsible User: \(getRiskLevel(responsibleResult.trustworthiness))")
print("Irresponsible User: \(getRiskLevel(irresponsibleResult.trustworthiness))")

print("\n✅ Sample analysis complete!")
print("📁 JSON files available at:")
print("   ~/Documents/responsible_user_sample.json")  
print("   ~/Documents/irresponsible_user_sample.json")