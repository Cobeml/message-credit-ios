import Foundation

/// Command-line utility to run sample analysis and display results
public struct RunSampleAnalysis {
    
    public static func main() async {
        print("🎯 Privacy Credit Analyzer - Sample Data Analysis")
        print("=" * 60)
        
        let runner = SampleAnalysisRunner()
        
        do {
            // Generate JSON files
            print("\n📄 Generating sample JSON files...")
            try runner.generateSampleJSONFiles()
            
            // Run analysis on both datasets
            print("\n🔍 Running analysis on sample datasets...")
            let results = try await runner.runSampleAnalysis()
            
            print("\n" + "=" * 60)
            print("📊 ANALYSIS COMPARISON SUMMARY")
            print("=" * 60)
            
            compareResults(responsible: results.responsible, irresponsible: results.irresponsible)
            
            print("\n✅ Sample analysis complete!")
            print("💾 Results stored for frontend testing")
            print("📁 JSON files available at:")
            print("   ~/Documents/responsible_user_sample.json")
            print("   ~/Documents/irresponsible_user_sample.json")
            
        } catch {
            print("❌ Analysis failed: \(error)")
        }
    }
    
    private static func compareResults(responsible: AnalysisResult, irresponsible: AnalysisResult) {
        print("\n🏆 RESPONSIBLE USER vs 📉 IRRESPONSIBLE USER")
        print("-" * 60)
        
        // Personality comparison
        print("\n💭 PERSONALITY TRAITS COMPARISON:")
        printTraitComparison("Openness", responsible.personalityTraits.openness, irresponsible.personalityTraits.openness)
        printTraitComparison("Conscientiousness", responsible.personalityTraits.conscientiousness, irresponsible.personalityTraits.conscientiousness)
        printTraitComparison("Extraversion", responsible.personalityTraits.extraversion, irresponsible.personalityTraits.extraversion)
        printTraitComparison("Agreeableness", responsible.personalityTraits.agreeableness, irresponsible.personalityTraits.agreeableness)
        printTraitComparison("Neuroticism", responsible.personalityTraits.neuroticism, irresponsible.personalityTraits.neuroticism)
        printTraitComparison("Confidence", responsible.personalityTraits.confidence, irresponsible.personalityTraits.confidence)
        
        // Trustworthiness comparison
        print("\n🏦 TRUSTWORTHINESS COMPARISON:")
        print("Overall Score:")
        printScoreComparison(responsible.trustworthinessScore.score, irresponsible.trustworthinessScore.score)
        
        print("\nFactor Breakdown:")
        for factor in ["communication_style", "financial_responsibility", "relationship_stability", "emotional_intelligence"] {
            let respScore = responsible.trustworthinessScore.factors[factor] ?? 0.0
            let irrespScore = irresponsible.trustworthinessScore.factors[factor] ?? 0.0
            printTraitComparison(factor.replacingOccurrences(of: "_", with: " ").capitalized, respScore, irrespScore)
        }
        
        // Risk assessment
        print("\n⚠️  CREDIT RISK ASSESSMENT:")
        let responsibleRisk = getRiskLevel(responsible.trustworthinessScore.score)
        let irresponsibleRisk = getRiskLevel(irresponsible.trustworthinessScore.score)
        
        print("Responsible User: \(responsibleRisk.emoji) \(responsibleRisk.level)")
        print("Irresponsible User: \(irresponsibleRisk.emoji) \(irresponsibleRisk.level)")
        
        print("\n📈 SCORE DIFFERENTIAL:")
        let scoreDiff = responsible.trustworthinessScore.score - irresponsible.trustworthinessScore.score
        print("Trustworthiness Gap: \(String(format: "+%.2f", scoreDiff)) (\(Int(scoreDiff * 100))% better)")
    }
    
    private static func printTraitComparison(_ trait: String, _ responsible: Double, _ irresponsible: Double) {
        let diff = responsible - irresponsible
        let arrow = diff > 0 ? "↗️" : diff < 0 ? "↘️" : "→"
        let diffStr = String(format: "%+.2f", diff)
        
        print(String(format: "  %-20s %s %.2f vs %.2f (%s)", trait + ":", arrow, responsible, irresponsible, diffStr))
    }
    
    private static func printScoreComparison(_ responsible: Double, _ irresponsible: Double) {
        let responsiblePercent = Int(responsible * 100)
        let irresponsiblePercent = Int(irresponsible * 100)
        let diff = responsiblePercent - irresponsiblePercent
        
        print("  🏆 Responsible: \(responsiblePercent)%  vs  📉 Irresponsible: \(irresponsiblePercent)%  (Δ +\(diff)%)")
    }
    
    private static func getRiskLevel(_ score: Double) -> (level: String, emoji: String) {
        switch score {
        case 0.8...1.0:
            return ("LOW RISK - Excellent creditworthiness", "🟢")
        case 0.6..<0.8:
            return ("MEDIUM RISK - Good creditworthiness", "🟡")
        case 0.4..<0.6:
            return ("HIGH RISK - Poor creditworthiness", "🟠")
        default:
            return ("VERY HIGH RISK - Significant credit risk", "🔴")
        }
    }
}

// String repetition extension
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// Simple async main runner for command-line execution  
// Note: @main removed to avoid conflicts in test environment
// To run as standalone: swift run RunSampleAnalysis
struct SampleAnalysisMain {
    static func main() async {
        await RunSampleAnalysis.main()
    }
}