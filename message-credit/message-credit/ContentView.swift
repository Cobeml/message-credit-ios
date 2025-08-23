//
//  ContentView.swift
//  message-credit
//
//  Created by Cobe Liu on 8/23/25.
//

import SwiftUI
import PrivacyCreditAnalyzer

struct ContentView: View {
    @State private var inputText = ""
    @State private var analysisResult: AnalysisResult?
    @State private var isAnalyzing = false
    @State private var showingFilePicker = false
    @State private var showingShortcutsHelp = false
    @State private var selectedFileInfo: FileInfo?
    @State private var fileParsingStatus: FileParsingStatus = .none
    @StateObject private var inferenceEngine = MLXInferenceEngine()
    
    @EnvironmentObject private var shortcutsManager: ShortcutsManager
    
    // MARK: - Section Builders
    private func headerSection() -> some View {
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
    }
    
    private func inputSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Message Input")
                .font(.headline)
            
            // Input method selector
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button(action: { showingShortcutsHelp = true }) {
                        HStack {
                            Image(systemName: "shortcuts")
                            Text("iOS Shortcuts")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(6)
                    }
                    
                    Button(action: { showingFilePicker = true }) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Import File")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                    }
                    
                    Text("or enter manually:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Shortcuts status
                if shortcutsManager.isProcessingShortcutData {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Processing Shortcut data...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let error = shortcutsManager.lastShortcutError {
                    HStack {
                        Image(systemName: error.contains("Sampled") ? "info.circle" : "exclamationmark.triangle")
                            .foregroundColor(error.contains("Sampled") ? .orange : .red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let validation = shortcutsManager.validationResult {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(validation.statusColor)
                        Text(validation.statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // File information display
            if let fileInfo = selectedFileInfo {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(fileInfo.name)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("\(ByteCountFormatter.string(fromByteCount: fileInfo.size, countStyle: .file)) • \(fileInfo.type)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Clear") {
                            clearFileSelection()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    
                    // Parsing status
                    if case .none = fileParsingStatus { } else {
                        HStack {
                            if case .parsing = fileParsingStatus {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: fileParsingStatus.color == .green ? "checkmark.circle" : "exclamationmark.triangle")
                                    .foregroundColor(fileParsingStatus.color)
                            }
                            Text(fileParsingStatus.displayText)
                                .font(.caption)
                                .foregroundColor(fileParsingStatus.color)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            TextEditor(text: $inputText)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            Text(selectedFileInfo != nil ? "File content loaded above. You can edit or add more messages." : "Enter messages to analyze personality traits and trustworthiness")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    private func analyzeButtonSection() -> some View {
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
    }
    
    private func resultsSection() -> some View {
        Group {
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
                            
                            HStack {
                                Text("Confidence")
                                    .font(.caption)
                                Spacer()
                                Text("\(Int(result.personalityTraits.confidence * 100))%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
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
                            
                            // Contributing factors
                            if !result.trustworthinessScore.factors.isEmpty {
                                Text("Contributing Factors:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.top, 4)
                                
                                ForEach(Array(result.trustworthinessScore.factors.keys.sorted()), id: \.self) { key in
                                    HStack {
                                        Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                                            .font(.caption)
                                        Spacer()
                                        Text("\(Int((result.trustworthinessScore.factors[key] ?? 0) * 100))%")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                }
                            }
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
                            Text("Analysis ID: \(result.id.uuidString.prefix(8))...")
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
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerSection()
                inputSection()
                analyzeButtonSection()
                resultsSection()
                
                Spacer()
            }
            .navigationTitle("Privacy Credit Analyzer")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json, .text],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $showingShortcutsHelp) {
            ShortcutInstallationGuide()
                .environmentObject(shortcutsManager)
        }
        .onChange(of: shortcutsManager.shortcutMessages) { oldValue, newValue in
            if !newValue.isEmpty {
                inputText = shortcutsManager.messagesToDisplayText(newValue)
                shortcutsManager.clearShortcutData()
            }
        }
        .onAppear {
            // Initialize the inference engine in the background
            Task {
                do {
                    try await inferenceEngine.initialize()
                } catch {
                    print("Failed to initialize inference engine: \(error)")
                    // Continue with mock functionality as fallback
                }
            }
        }
    }
    
    private func analyzeMessages() {
        isAnalyzing = true
        
        Task {
            do {
                // Parse manual input into messages
                let inputHandler = ManualInputHandler()
                let messages = try inputHandler.parseManualInput(inputText)
                
                // Filter messages to focus on relevant content
                let filterEngine = MessageFilterEngine()
                let filterResult = filterEngine.filterMessages(
                    messages, 
                    strategy: .combined(lovedOnes: true, financialKeywords: true)
                )
                
                // Use the filtered messages for analysis
                let messagesToAnalyze = filterResult.filteredMessages.isEmpty ? messages : filterResult.filteredMessages
                
                if inferenceEngine.isInitialized {
                    // Use real MLX inference for personality and trustworthiness analysis
                    let result = try await inferenceEngine.processInBackground(messages: messagesToAnalyze)
                    
                    await MainActor.run {
                        analysisResult = result
                        isAnalyzing = false
                    }
                } else {
                    // Fallback to enhanced mock analysis with real filtering data
                    await useMockAnalysis(messages: messages, filterResult: filterResult)
                }
                
            } catch {
                await MainActor.run {
                    // Enhanced error handling with real parsing attempt
                    let startTime = Date()
                    let mockTraits = PersonalityTraits(
                        openness: 0.5,
                        conscientiousness: 0.5,
                        extraversion: 0.5,
                        agreeableness: 0.5,
                        neuroticism: 0.5,
                        confidence: 0.3
                    )
                    
                    let mockTrustScore = TrustworthinessScore(
                        score: 0.4,
                        factors: [:],
                        explanation: "Analysis failed: \(error.localizedDescription). Using fallback analysis."
                    )
                    
                    analysisResult = AnalysisResult(
                        personalityTraits: mockTraits,
                        trustworthinessScore: mockTrustScore,
                        messageCount: 0,
                        processingTime: Date().timeIntervalSince(startTime)
                    )
                    
                    isAnalyzing = false
                }
            }
        }
    }
    
    private func useMockAnalysis(messages: [Message], filterResult: MessageFilterEngine.FilterResult) async {
        let startTime = Date()
        
        // Enhanced mock analysis using real filtering results
        let mockTraits = PersonalityTraits(
            openness: Double.random(in: 0.3...0.9),
            conscientiousness: Double.random(in: 0.4...0.8),
            extraversion: Double.random(in: 0.2...0.9),
            agreeableness: Double.random(in: 0.5...0.9),
            neuroticism: Double.random(in: 0.1...0.6),
            confidence: Double.random(in: 0.6...0.9)
        )
        
        // Create trustworthiness score based on real filtering results
        let relationshipScore = filterResult.filteringStats.relationshipScores.values.max() ?? 0.5
        let financialRatio = Double(filterResult.filteringStats.financialMessagesCount) / Double(max(messages.count, 1))
        
        let trustScore = TrustworthinessScore(
            score: (relationshipScore + financialRatio) / 2.0,
            factors: [
                "communication_style": relationshipScore,
                "financial_responsibility": financialRatio,
                "relationship_stability": relationshipScore * 0.8,
                "emotional_intelligence": relationshipScore * 0.9
            ],
            explanation: "Mock analysis based on \(filterResult.filteredMessages.count) relevant messages from \(messages.count) total messages. MLX inference not available - using enhanced filtering-based analysis."
        )
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        let result = AnalysisResult(
            personalityTraits: mockTraits,
            trustworthinessScore: trustScore,
            messageCount: messages.count,
            processingTime: processingTime
        )
        
        await MainActor.run {
            analysisResult = result
            isAnalyzing = false
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Extract file metadata and populate FileInfo
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = fileAttributes[.size] as? Int64 ?? 0
                let fileName = url.lastPathComponent
                let fileType = url.pathExtension.isEmpty ? "Unknown" : url.pathExtension.uppercased()
                
                let fileInfo = FileInfo(
                    name: fileName,
                    size: fileSize,
                    type: fileType,
                    url: url
                )
                
                selectedFileInfo = fileInfo
                fileParsingStatus = .parsing
                
            } catch {
                fileParsingStatus = .error("Unable to read file metadata: \(error.localizedDescription)")
                return
            }
            
            Task {
                do {
                    let parser = MessagesExportParser()
                    let messages = try await parser.parseMessagesExport(from: url)
                    
                    // Convert messages to display format
                    let messageTexts = messages.map { message in
                        let sender = message.isFromUser ? "Me" : message.sender
                        return "\(sender): \(message.content)"
                    }
                    
                    await MainActor.run {
                        inputText = messageTexts.joined(separator: "\n")
                        fileParsingStatus = .success(messageCount: messages.count)
                    }
                    
                } catch {
                    await MainActor.run {
                        fileParsingStatus = .error(error.localizedDescription)
                        // Still show the error in input text for debugging
                        inputText = "Error parsing file: \(error.localizedDescription)"
                    }
                }
            }
            
        case .failure(let error):
            fileParsingStatus = .error("File selection failed: \(error.localizedDescription)")
            print("File import failed: \(error.localizedDescription)")
        }
    }
    
    private func clearFileSelection() {
        selectedFileInfo = nil
        fileParsingStatus = .none
        // Clear the input text if it was populated from file
        inputText = ""
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

// MARK: - Supporting Types

struct FileInfo {
    let name: String
    let size: Int64
    let type: String
    let url: URL
}

enum FileParsingStatus {
    case none
    case parsing
    case success(messageCount: Int)
    case error(String)
    
    var displayText: String {
        switch self {
        case .none:
            return ""
        case .parsing:
            return "Parsing file..."
        case .success(let count):
            return "Successfully parsed \(count) messages"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    var color: Color {
        switch self {
        case .none:
            return .clear
        case .parsing:
            return .blue
        case .success:
            return .green
        case .error:
            return .red
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ShortcutsManager())
}
