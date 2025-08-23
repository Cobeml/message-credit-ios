import SwiftUI
import PlaygroundSupport

// Import your models (you'd need to copy them here for playground)
struct PersonalityTraits {
    let openness: Double
    let conscientiousness: Double
    let extraversion: Double
    let agreeableness: Double
    let neuroticism: Double
    let confidence: Double
}

struct TrustworthinessScore {
    let score: Double
    let factors: [String: Double]
    let explanation: String
}

struct AnalysisResult {
    let personalityTraits: PersonalityTraits
    let trustworthinessScore: TrustworthinessScore
    let messageCount: Int
    let processingTime: TimeInterval
}

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
                    
                    Text("Enter messages to analyze")
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
                
                Spacer()
            }
            .navigationTitle("Privacy Credit Analyzer")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func analyzeMessages() {
        isAnalyzing = true
        
        // Simulate analysis
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Mock analysis result
            isAnalyzing = false
        }
    }
}

// Set up the playground
PlaygroundPage.current.setLiveView(ContentView())