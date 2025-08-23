import Foundation
import MLX
import MLXNN

/// Main inference engine that coordinates model loading, prompt engineering, and analysis
public class MLXInferenceEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var isInitialized: Bool = false
    @Published public var isAnalyzing: Bool = false
    @Published public var analysisProgress: Double = 0.0
    @Published public var analysisStatus: String = "Ready"
    @Published public var lastError: InferenceError?
    
    // MARK: - Private Properties
    
    private let modelManager: ModelManager
    private let promptEngineer: PromptEngineer
    private var currentAnalysisTask: Task<Void, Never>?
    
    // Analysis configuration
    private let maxRetries = 3
    private let inferenceTimeout: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    
    public init() {
        self.modelManager = ModelManager()
        self.promptEngineer = PromptEngineer()
    }
    
    // MARK: - Public Interface
    
    /// Initializes the inference engine by loading the model
    public func initialize() async throws {
        await updateStatus(0.0, "Initializing MLX inference engine...")
        
        do {
            try await modelManager.loadModel()
            
            await MainActor.run {
                isInitialized = true
                analysisStatus = "Ready for analysis"
            }
            
        } catch {
            await MainActor.run {
                lastError = error as? InferenceError ?? .initializationFailed(error.localizedDescription)
                analysisStatus = "Initialization failed"
            }
            throw error
        }
    }
    
    /// Performs complete personality analysis on provided messages
    public func analyzePersonality(messages: [Message]) async throws -> PersonalityTraits {
        guard isInitialized else {
            throw InferenceError.engineNotInitialized
        }
        
        await updateStatus(0.1, "Preparing personality analysis...")
        
        let prompt = promptEngineer.createPersonalityAnalysisPrompt(messages: messages)
        
        await updateStatus(0.3, "Running personality inference...")
        
        let response = try await performInferenceWithRetry(prompt: prompt)
        
        await updateStatus(0.8, "Parsing personality results...")
        
        do {
            let personalityTraits = try promptEngineer.parsePersonalityResponse(response)
            await updateStatus(1.0, "Personality analysis complete")
            return personalityTraits
        } catch {
            throw InferenceError.responseParsingFailed("Personality parsing failed: \(error.localizedDescription)")
        }
    }
    
    /// Calculates trustworthiness score based on messages and personality traits
    public func calculateTrustworthiness(messages: [Message], traits: PersonalityTraits) async throws -> TrustworthinessScore {
        guard isInitialized else {
            throw InferenceError.engineNotInitialized
        }
        
        await updateStatus(0.1, "Preparing trustworthiness analysis...")
        
        let prompt = promptEngineer.createTrustworthinessPrompt(messages: messages, personalityTraits: traits)
        
        await updateStatus(0.3, "Running trustworthiness inference...")
        
        let response = try await performInferenceWithRetry(prompt: prompt)
        
        await updateStatus(0.8, "Parsing trustworthiness results...")
        
        do {
            let trustworthinessScore = try promptEngineer.parseTrustworthinessResponse(response)
            await updateStatus(1.0, "Trustworthiness analysis complete")
            return trustworthinessScore
        } catch {
            throw InferenceError.responseParsingFailed("Trustworthiness parsing failed: \(error.localizedDescription)")
        }
    }
    
    /// Performs complete analysis workflow in background
    public func processInBackground(messages: [Message]) async throws -> AnalysisResult {
        guard isInitialized else {
            throw InferenceError.engineNotInitialized
        }
        
        await MainActor.run {
            isAnalyzing = true
            analysisProgress = 0.0
            lastError = nil
        }
        
        let startTime = Date()
        
        do {
            // Step 1: Personality Analysis
            await updateStatus(0.1, "Analyzing personality traits...")
            let personalityTraits = try await analyzePersonality(messages: messages)
            
            // Step 2: Trustworthiness Analysis
            await updateStatus(0.6, "Calculating trustworthiness score...")
            let trustworthinessScore = try await calculateTrustworthiness(messages: messages, traits: personalityTraits)
            
            // Step 3: Create final result
            await updateStatus(0.9, "Finalizing analysis results...")
            
            let processingTime = Date().timeIntervalSince(startTime)
            let result = AnalysisResult(
                personalityTraits: personalityTraits,
                trustworthinessScore: trustworthinessScore,
                messageCount: messages.count,
                processingTime: processingTime
            )
            
            await updateStatus(1.0, "Analysis complete")
            
            await MainActor.run {
                isAnalyzing = false
            }
            
            return result
            
        } catch {
            await MainActor.run {
                lastError = error as? InferenceError ?? .analysisFailure(error.localizedDescription)
                isAnalyzing = false
                analysisStatus = "Analysis failed"
            }
            throw error
        }
    }
    
    /// Cancels any running analysis
    public func cancelAnalysis() {
        currentAnalysisTask?.cancel()
        currentAnalysisTask = nil
        
        Task { @MainActor in
            isAnalyzing = false
            analysisStatus = "Analysis cancelled"
            analysisProgress = 0.0
        }
    }
    
    /// Returns model hash for cryptographic verification
    public var modelHash: String? {
        return modelManager.modelHash
    }
    
    /// Estimates memory usage for the inference engine
    public var estimatedMemoryUsage: Int64 {
        return modelManager.estimatedMemoryUsage
    }
}

// MARK: - Private Methods

extension MLXInferenceEngine {
    
    private func updateStatus(_ progress: Double, _ status: String) async {
        await MainActor.run {
            analysisProgress = progress
            analysisStatus = status
        }
    }
    
    private func performInferenceWithRetry(prompt: String) async throws -> String {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                await updateStatus(analysisProgress + 0.1, "Inference attempt \(attempt)/\(maxRetries)...")
                
                let response = try await withTimeout(inferenceTimeout) {
                    try await self.modelManager.generate(prompt: prompt, maxLength: 2048)
                }
                
                // Validate response quality
                guard !response.isEmpty && response.count > 20 else {
                    throw InferenceError.invalidResponse("Response too short or empty")
                }
                
                return response
                
            } catch {
                lastError = error
                
                if attempt < maxRetries {
                    let delay = TimeInterval(attempt * 2) // Exponential backoff
                    await updateStatus(analysisProgress, "Retrying in \(Int(delay)) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? InferenceError.analysisFailure("All retry attempts failed")
    }
    
    private func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                return try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw InferenceError.inferenceTimeout
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    /// Validates message quality for analysis
    private func validateMessages(_ messages: [Message]) throws {
        guard !messages.isEmpty else {
            throw InferenceError.invalidInput("No messages provided")
        }
        
        guard messages.count >= 5 else {
            throw InferenceError.invalidInput("Minimum 5 messages required for reliable analysis")
        }
        
        let totalContent = messages.map(\.content).joined()
        guard totalContent.count >= 100 else {
            throw InferenceError.invalidInput("Insufficient content for analysis (minimum 100 characters)")
        }
        
        // Check for reasonable content distribution
        let averageMessageLength = totalContent.count / messages.count
        guard averageMessageLength >= 5 else {
            throw InferenceError.invalidInput("Messages too short for meaningful analysis")
        }
    }
    
    /// Performs quality checks on analysis results
    private func validateAnalysisResult(_ result: AnalysisResult) throws {
        // Validate personality trait ranges
        let traits = result.personalityTraits
        guard traits.openness >= 0.0 && traits.openness <= 1.0,
              traits.conscientiousness >= 0.0 && traits.conscientiousness <= 1.0,
              traits.extraversion >= 0.0 && traits.extraversion <= 1.0,
              traits.agreeableness >= 0.0 && traits.agreeableness <= 1.0,
              traits.neuroticism >= 0.0 && traits.neuroticism <= 1.0 else {
            throw InferenceError.invalidResponse("Personality traits out of valid range")
        }
        
        // Validate trustworthiness score
        guard result.trustworthinessScore.score >= 0.0 && result.trustworthinessScore.score <= 1.0 else {
            throw InferenceError.invalidResponse("Trustworthiness score out of valid range")
        }
        
        // Validate confidence scores
        guard traits.confidence >= 0.0 && traits.confidence <= 1.0 else {
            throw InferenceError.invalidResponse("Confidence score out of valid range")
        }
    }
}

// MARK: - Batch Processing Support

extension MLXInferenceEngine {
    
    /// Processes large message volumes with intelligent batching
    public func processLargeDataset(messages: [Message], batchSize: Int = 1000) async throws -> AnalysisResult {
        guard isInitialized else {
            throw InferenceError.engineNotInitialized
        }
        
        await updateStatus(0.0, "Preparing batch processing for \(messages.count) messages...")
        
        // For very large datasets, sample intelligently
        let processedMessages: [Message]
        if messages.count > 5000 {
            await updateStatus(0.1, "Applying intelligent sampling...")
            processedMessages = await applySampling(messages: messages, targetCount: 5000)
        } else {
            processedMessages = messages
        }
        
        await updateStatus(0.2, "Processing \(processedMessages.count) selected messages...")
        
        // Use the regular processing pipeline with sampled data
        return try await processInBackground(messages: processedMessages)
    }
    
    private func applySampling(messages: [Message], targetCount: Int) async -> [Message] {
        // Implement intelligent sampling strategy:
        // 1. Prioritize recent messages (40%)
        // 2. Include financial keyword messages (30%)
        // 3. Sample across different time periods (20%)
        // 4. Include longest messages for context (10%)
        
        let sortedByDate = messages.sorted { $0.timestamp > $1.timestamp }
        let recentMessages = Array(sortedByDate.prefix(targetCount * 40 / 100))
        
        let financialMessages = messages.filter { message in
            let content = message.content.lowercased()
            return ["money", "payment", "bank", "credit", "loan", "financial", "budget"].contains { keyword in
                content.contains(keyword)
            }
        }.prefix(targetCount * 30 / 100)
        
        let longMessages = messages.sorted { $0.content.count > $1.content.count }.prefix(targetCount * 10 / 100)
        
        // Temporal sampling for remaining 20%
        let remainingCount = targetCount * 20 / 100
        let timeInterval = messages.count / remainingCount
        let temporalMessages = stride(from: 0, to: messages.count, by: max(1, timeInterval)).compactMap { index in
            messages.indices.contains(index) ? messages[index] : nil
        }
        
        // Combine and deduplicate
        var combinedMessages = Set<UUID>()
        var result: [Message] = []
        
        for messageArray in [recentMessages, Array(financialMessages), Array(longMessages), temporalMessages] {
            for message in messageArray {
                if !combinedMessages.contains(message.id) && result.count < targetCount {
                    combinedMessages.insert(message.id)
                    result.append(message)
                }
            }
        }
        
        return Array(result.prefix(targetCount))
    }
}

// MARK: - Error Types

public enum InferenceError: Error, LocalizedError {
    case engineNotInitialized
    case initializationFailed(String)
    case invalidInput(String)
    case inferenceTimeout
    case analysisFailure(String)
    case responseParsingFailed(String)
    case invalidResponse(String)
    case memoryPressure(String)
    
    public var errorDescription: String? {
        switch self {
        case .engineNotInitialized:
            return "Inference engine not initialized. Call initialize() first."
        case .initializationFailed(let reason):
            return "Failed to initialize inference engine: \(reason)"
        case .invalidInput(let reason):
            return "Invalid input provided: \(reason)"
        case .inferenceTimeout:
            return "Inference timed out. Try with fewer messages or shorter content."
        case .analysisFailure(let reason):
            return "Analysis failed: \(reason)"
        case .responseParsingFailed(let reason):
            return "Failed to parse model response: \(reason)"
        case .invalidResponse(let reason):
            return "Invalid model response: \(reason)"
        case .memoryPressure(let reason):
            return "Memory pressure detected: \(reason)"
        }
    }
}

// MARK: - Performance Monitoring

extension MLXInferenceEngine {
    
    /// Returns performance statistics for the current session
    public var performanceStats: InferencePerformanceStats {
        return InferencePerformanceStats(
            memoryUsage: estimatedMemoryUsage,
            isInitialized: isInitialized,
            modelHash: modelHash
        )
    }
}

public struct InferencePerformanceStats {
    public let memoryUsage: Int64
    public let isInitialized: Bool
    public let modelHash: String?
    
    public var memoryUsageMB: Double {
        return Double(memoryUsage) / (1024 * 1024)
    }
}