import SwiftUI
import PrivacyCreditAnalyzer

struct ContentView: View {
    @State private var inputText = ""
    @State private var analysisResult: AnalysisResult?
    @State private var isAnalyzing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Privacy Credit Analyzer")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Secure on-device credit analysis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Input Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Message Input")
                        .font(.headline)
                    
                    TextEditor(text: $inputText)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    
                    Text("Enter messages to analyze personality traits and trustworthiness")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Analyze Button
                Button(action: analyzeMessages) {
                    HStack {
                        if isAnalyzing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "brain.head.profile")
                        }
                        Text(isAnalyzing ? "Analyzing..." : "Analyze Messages")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(inputText.isEmpty ? Color(.systemGray4) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(inputText.isEmpty || isAnalyzing)
                .padding(.horizontal)
                
                // Results Section
                if let result = analysisResult {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Analysis Results")
                                .font(.headline)
                            
                            // Personality Traits
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Personality Traits")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                PersonalityTraitRow(name: "Openness", value: result.personalityTraits.openness)
                                PersonalityTraitRow(name: "Conscientiousness", value: result.personalityTraits.conscientiousness)
                                PersonalityTraitRow(name: "Extraversion", value: result.personalityTraits.extraversion)
                                PersonalityTraitRow(name: "Agreeableness", value: result.personalityTraits.agreeableness)
                                PersonalityTraitRow(name: "Neuroticism", value: result.personalityTraits.neuroticism)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                            // Trustworthiness Score
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Trustworthiness Score")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                HStack {
                                    Text("Score:")
                                    Spacer()
                                    Text("\(Int(result.trustworthinessScore.score * 100))%")
                                        .fontWeight(.bold)
                                        .foregroundColor(scoreColor(result.trustworthinessScore.score))
                                }
                                
                                Text(result.trustworthinessScore.explanation)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                            // Processing Info
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Processing Info")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text("Messages analyzed: \(result.messageCount)")
                                Text("Processing time: \(String(format: "%.2f", result.processingTime))s")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Privacy Credit Analyzer")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func analyzeMessages() {
        isAnalyzing = true
        
        // Simulate analysis with mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let mockTraits = PersonalityTraits(
                openness: Double.random(in: 0.3...0.9),
                conscientiousness: Double.random(in: 0.4...0.8),
                extraversion: Double.random(in: 0.2...0.9),
                agreeableness: Double.random(in: 0.5...0.9),
                neuroticism: Double.random(in: 0.1...0.6),
                confidence: Double.random(in: 0.6...0.9)
            )
            
            let mockTrustScore = TrustworthinessScore(
                score: Double.random(in: 0.4...0.9),
                factors: [
                    "communication_style": Double.random(in: 0.3...0.9),
                    "financial_responsibility": Double.random(in: 0.4...0.8),
                    "relationship_stability": Double.random(in: 0.5...0.9)
                ],
                explanation: "Analysis based on communication patterns, financial references, and relationship indicators in the provided messages."
            )
            
            analysisResult = AnalysisResult(
                personalityTraits: mockTraits,
                trustworthinessScore: mockTrustScore,
                messageCount: inputText.components(separatedBy: .newlines).filter { !$0.isEmpty }.count,
                processingTime: Double.random(in: 1.5...3.0)
            )
            
            isAnalyzing = false
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

struct PersonalityTraitRow: View {
    let name: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(name)
                .font(.caption)
            Spacer()
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * value, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(width: 80, height: 6)
            
            Text("\(Int(value * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 35, alignment: .trailing)
        }
    }
}

#Preview {
    ContentView()
}