//
//  ContentView.swift
//  message-credit
//
//  Created by Cobe Liu on 8/23/25.
//

import SwiftUI
import PrivacyCreditAnalyzer

struct ContentView: View {
    
    // MARK: - Device Compatibility Check
    
    /// Checks if device has sufficient memory for MLX operations
    private static var isDeviceSupported: Bool {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let requiredMemory: UInt64 = 6_000_000_000 // 6GB minimum
        
        print("🔍 Device Memory Check:")
        print("   Physical Memory: \(String(format: "%.1f", Double(physicalMemory) / 1_000_000_000))GB")
        print("   Required Memory: \(String(format: "%.1f", Double(requiredMemory) / 1_000_000_000))GB")
        print("   Device Supported: \(physicalMemory >= requiredMemory)")
        
        return physicalMemory >= requiredMemory
    }
    @State private var inputText = ""
    @State private var analysisResult: AnalysisResult?
    @State private var isAnalyzing = false
    @State private var showingFilePicker = false
    
    @State private var selectedFileInfo: FileInfo?
    @State private var fileParsingStatus: FileParsingStatus = .none
    @State private var inferenceEngine: MLXInferenceEngine? = Self.isDeviceSupported ? MLXInferenceEngine() : nil
    @StateObject private var presetManager = PresetDataManager()
    @State private var showingPresetMenu = false
    @State private var showingLoadingView = false
    @State private var showingAnalyticsView = false
    
    @EnvironmentObject private var shortcutsManager: ShortcutsManager
    
    // MARK: - Section Builders
    private func headerSection() -> some View {
        VStack(spacing: 12) {
            Text("Integrate your messages to get your score")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            if !Self.isDeviceSupported {
                // Show warning for low-memory devices but allow continued use
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                        Text("Limited Device Mode")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    
                    Text("Using mock analysis mode - your device has insufficient RAM for full MLX processing")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                )
            }
            
            Text("🔒 All analysis happens on your device - no data is sent off your local device")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top)
    }
    
    private func inputSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Message Input")
                .font(.headline)
            
            // Input method selector
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Button(action: { showingFilePicker = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                                .font(.caption)
                            Text("Import")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                    }
                    
                    Button(action: { showingPresetMenu = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "flask")
                                .font(.caption)
                            Text("Sample")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                    }
                    
                    Text("or enter manually:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.leading, 4)
                    
                    Spacer()
                }
            }
            
            // File information display
            if let fileInfo = selectedFileInfo {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.white)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(fileInfo.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            Text("\(ByteCountFormatter.string(fromByteCount: fileInfo.size, countStyle: .file)) • \(fileInfo.type)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                        Button("Clear") {
                            clearFileSelection()
                        }
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
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
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            
            TextEditor(text: $inputText)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .foregroundColor(.white)
                .colorScheme(.dark)
                .frame(maxHeight: .infinity, alignment: .top)
            
            
        }
        .padding(.horizontal)
        .frame(maxHeight: .infinity, alignment: .top)
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
            .background(
                inputText.isEmpty ? 
                LinearGradient(
                    colors: [Color.white.opacity(0.2), Color.white.opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
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
                            .foregroundColor(.white)
                        
                        // Personality Traits
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Personality Traits")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            PersonalityTraitRow(name: "Openness", value: result.personalityTraits.openness)
                            PersonalityTraitRow(name: "Conscientiousness", value: result.personalityTraits.conscientiousness)
                            PersonalityTraitRow(name: "Extraversion", value: result.personalityTraits.extraversion)
                            PersonalityTraitRow(name: "Agreeableness", value: result.personalityTraits.agreeableness)
                            PersonalityTraitRow(name: "Neuroticism", value: result.personalityTraits.neuroticism)
                            
                            HStack {
                                Text("Confidence")
                                    .font(.caption)
                                Spacer()
                                Text(result.personalityTraits.confidence.isNaN ? "N/A" : "\(Int(result.personalityTraits.confidence * 100))%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Trustworthiness Score
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Trustworthiness Score")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("Score:")
                                Spacer()
                                Text(result.trustworthinessScore.score.isNaN ? "N/A" : "\(Int(result.trustworthinessScore.score * 100))%")
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
                                        let factorValue = result.trustworthinessScore.factors[key] ?? 0
                                        Text(factorValue.isNaN ? "N/A" : "\(Int(factorValue * 100))%")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Processing Info
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Processing Info")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Messages analyzed: \(result.messageCount)")
                            Text("Processing time: \(String(format: "%.2f", result.processingTime))s")
                            Text("Analysis ID: \(result.id.uuidString.prefix(8))...")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Floating orbs background
                FloatingOrbsBackground()
                
                VStack(spacing: 20) {
                    headerSection()
                    inputSection()
                    analyzeButtonSection()
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json, .text],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .confirmationDialog("Load Sample Data", isPresented: $showingPresetMenu, titleVisibility: .visible) {
            createPresetButtons()
        } message: {
            Text("Choose a preset to test the analysis functionality")
        }
        .onAppear {
            // Safely initialize the inference engine in the background
            initializeInferenceEngine()
        }
        .sheet(isPresented: $showingLoadingView) {
            LoadingView()
        }
        .sheet(isPresented: $showingAnalyticsView) {
            if let result = analysisResult {
                AnalyticsDetailView(result: result) {
                    showingAnalyticsView = false
                }
            }
        }
    }
    
    private func analyzeMessages() {
        isAnalyzing = true
        showingLoadingView = true
        
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
                
                if let engine = inferenceEngine, engine.isInitialized {
                    // Use real MLX inference for personality and trustworthiness analysis
                    let result = try await engine.processInBackground(messages: messagesToAnalyze)
                    
                    await MainActor.run {
                        analysisResult = result
                        isAnalyzing = false
                        showingLoadingView = false
                        showingAnalyticsView = true
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
                    showingLoadingView = false
                    showingAnalyticsView = true
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
            showingLoadingView = false
            showingAnalyticsView = true
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
        if score.isNaN {
            return .gray
        }
        switch score {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
    
    // MARK: - Preset Data Methods
    
    @ViewBuilder
    private func createPresetButtons() -> some View {
        let presetInfo = presetManager.getPresetInfo()
        
        ForEach(presetInfo, id: \.type.rawValue) { preset in
            Button("\(preset.icon) \(preset.title)") {
                loadPresetData(preset.type)
            }
        }
        
        Button("Cancel", role: .cancel) { }
    }
    
    private func loadPresetData(_ type: PresetDataManager.PresetType) {
        // Clear any existing data
        clearFileSelection()
        
        // Load preset messages
        let messages = presetManager.loadPresetMessages(type: type)
        
        // Convert to display format
        inputText = presetManager.messagesToDisplayText(messages)
        
        // Show a brief status message
        let preset = presetManager.getPresetInfo().first { $0.type == type }!
        print("✅ Loaded \(preset.title): \(preset.messageCount) messages")
        print("📊 Expected trustworthiness: \(String(format: "%.1f%%", preset.expectedScore * 100)) (\(preset.riskLevel))")
    }
    
    private func initializeInferenceEngine() {
        // Check if running in simulator
        #if targetEnvironment(simulator)
        print("📱 Running in iOS Simulator - MLX not supported")
        print("✨ Using enhanced mock analysis for demonstration")
        inferenceEngine = nil
        return
        #endif
        
        Task {
            do {
                // Only attempt to create the inference engine if we don't have one
                if inferenceEngine == nil {
                    print("🔄 Attempting to initialize MLX inference engine...")
                    let engine = MLXInferenceEngine()
                    
                    // Try to initialize in a safe way
                    try await engine.initialize()
                    
                    await MainActor.run {
                        self.inferenceEngine = engine
                        print("✅ MLX inference engine initialized successfully")
                    }
                }
            } catch {
                await MainActor.run {
                    self.inferenceEngine = nil
                    print("⚠️ MLX initialization failed: \(error)")
                    print("📱 App will continue with enhanced mock analysis")
                    print("ℹ️ This is normal on devices without MLX support")
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct PersonalityTraitRow: View {
    let name: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(name)
                .font(.caption)
                .foregroundColor(.white)
            Spacer()
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * max(0, min(1, value.isNaN ? 0 : value)), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(width: 80, height: 6)
            
            Text(value.isNaN ? "N/A" : "\(Int(value * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
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


// MARK: - Analytics Detail View
struct AnalyticsDetailView: View {
    let result: AnalysisResult
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Floating orbs background
                FloatingOrbsBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 10) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                            
                            Text("Credit Analysis Report")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.top)
                        
                        // Credit Score Card
                        creditScoreCard()
                        
                        // Personality Analysis
                        personalityAnalysisCard()
                        
                        // Risk Factors
                        riskFactorsCard()
                        
                        // Processing Details
                        processingDetailsCard()
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Analysis Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func creditScoreCard() -> some View {
        VStack(spacing: 15) {
            Text("Credit Score")
                .font(.headline)
                .foregroundColor(.white)
            
            let creditScore = convertToCreditScore(result.trustworthinessScore.score)
            
            VStack(spacing: 5) {
                Text("\(creditScore)")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(creditScoreColor(creditScore))
                
                Text(creditScoreCategory(creditScore))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text(result.trustworthinessScore.explanation)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func personalityAnalysisCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personality Analysis")
                .font(.headline)
                .foregroundColor(.white)
            
            PersonalityTraitRow(name: "Openness", value: result.personalityTraits.openness)
            PersonalityTraitRow(name: "Conscientiousness", value: result.personalityTraits.conscientiousness)
            PersonalityTraitRow(name: "Extraversion", value: result.personalityTraits.extraversion)
            PersonalityTraitRow(name: "Agreeableness", value: result.personalityTraits.agreeableness)
            PersonalityTraitRow(name: "Neuroticism", value: result.personalityTraits.neuroticism)
            
            HStack {
                Text("Analysis Confidence:")
                    .font(.caption)
                    .foregroundColor(.white)
                Spacer()
                Text(result.personalityTraits.confidence.isNaN ? "N/A" : "\(Int(result.personalityTraits.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func riskFactorsCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Risk Assessment Factors")
                .font(.headline)
                .foregroundColor(.white)
            
            if !result.trustworthinessScore.factors.isEmpty {
                ForEach(Array(result.trustworthinessScore.factors.keys.sorted()), id: \.self) { key in
                    let factorValue = result.trustworthinessScore.factors[key] ?? 0
                    HStack {
                        Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .foregroundColor(.white)
                        Spacer()
                        Text(factorValue.isNaN ? "N/A" : "\(Int(factorValue * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(factorValue > 0.7 ? .green : factorValue > 0.4 ? .orange : .red)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func processingDetailsCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Analysis Details")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Text("Messages Analyzed:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("\(result.messageCount)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            HStack {
                Text("Processing Time:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("\(String(format: "%.2f", result.processingTime))s")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            HStack {
                Text("Analysis ID:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("\(result.id.uuidString.prefix(8))...")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
    
    // Helper functions for credit score conversion
    private func convertToCreditScore(_ trustworthinessScore: Double) -> Int {
        if trustworthinessScore.isNaN {
            return 500 // Default middle score for NaN
        }
        
        // Convert 0.0-1.0 trustworthiness to 300-850 credit score
        let minScore = 300.0
        let maxScore = 850.0
        let range = maxScore - minScore
        
        let creditScore = minScore + (trustworthinessScore * range)
        return Int(creditScore.rounded())
    }
    
    private func creditScoreColor(_ score: Int) -> Color {
        switch score {
        case 750...850:
            return .green
        case 670..<750:
            return .blue
        case 580..<670:
            return .orange
        case 300..<580:
            return .red
        default:
            return .gray
        }
    }
    
    private func creditScoreCategory(_ score: Int) -> String {
        switch score {
        case 800...850:
            return "Exceptional"
        case 740..<800:
            return "Very Good"
        case 670..<740:
            return "Good"
        case 580..<670:
            return "Fair"
        case 300..<580:
            return "Poor"
        default:
            return "Unknown"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ShortcutsManager())
}
