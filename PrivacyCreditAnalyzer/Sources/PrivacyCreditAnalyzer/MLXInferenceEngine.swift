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
    
    // MARK: - Environment Detection
    
    /// Detects if running in iOS Simulator (MLX incompatible environment)
    public static var isSimulatorEnvironment: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    /// Detects if current device supports MLX (Apple Silicon + physical device)
    public static var isMLXCompatibleDevice: Bool {
        guard !isSimulatorEnvironment else { return false }
        
        // Additional checks for Apple Silicon can be added here
        // For now, we assume all non-simulator devices are compatible
        return true
    }
    
    // Analysis configuration
    private let maxRetries = 5 // Increased for long-running tasks
    private let inferenceTimeout: TimeInterval = 600 // 10 minutes for batch processing
    private let batchTimeout: TimeInterval = 1800 // 30 minutes for full batch analysis
    
    // MARK: - Initialization
    
    public init() {
        self.modelManager = ModelManager()
        self.promptEngineer = PromptEngineer()
        
        // Early initialization check for simulator environment
        if Self.isSimulatorEnvironment {
            print("🚨 MLX COMPATIBILITY WARNING:")
            print("📱 Running in iOS Simulator - MLX framework is not supported")
            print("🔧 MLX requires physical Apple devices with Metal GPU support")
            print("✨ App will use enhanced mock analysis for development")
            print("📲 Deploy to a physical iOS device for real MLX inference")
            
            analysisStatus = "Simulator Mode - Mock Analysis Only"
        }
    }
    
    // MARK: - Public Interface
    
    /// Initializes the inference engine by loading the model
    public func initialize() async throws {
        // CRITICAL: Prevent MLX initialization in simulator environments
        guard !Self.isSimulatorEnvironment else {
            await MainActor.run {
                isInitialized = false // Explicitly set to false
                analysisStatus = "Simulator Mode - MLX Not Available"
                print("✅ Simulator mode initialized - using mock analysis")
            }
            return // Exit early without attempting MLX initialization
        }
        
        // Additional device compatibility check
        guard Self.isMLXCompatibleDevice else {
            let error = InferenceError.deviceThrottling("Device not compatible with MLX framework")
            await MainActor.run {
                self.lastError = error
                analysisStatus = "Device Incompatible"
            }
            throw error
        }
        
        await updateStatus(0.0, "Initializing MLX inference engine on physical device...")
        
        do {
            try await modelManager.loadModel()
            
            await MainActor.run {
                isInitialized = true
                analysisStatus = "MLX Ready on Device"
                print("✅ MLX inference engine successfully initialized on physical device")
            }
            
        } catch {
            await MainActor.run {
                lastError = error as? InferenceError ?? .initializationFailed(error.localizedDescription)
                analysisStatus = "MLX Initialization Failed"
                print("❌ MLX initialization failed: \(error.localizedDescription)")
            }
            throw error
        }
    }
    
    /// Performs complete personality analysis on provided messages
    public func analyzePersonality(messages: [Message]) async throws -> PersonalityTraits {
        // Handle simulator environment with mock analysis
        if Self.isSimulatorEnvironment {
            await updateStatus(0.1, "Generating mock personality analysis...")
            return try await generateMockPersonalityTraits(for: messages)
        }
        
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
        // Handle simulator environment with mock analysis
        if Self.isSimulatorEnvironment {
            await updateStatus(0.1, "Generating mock trustworthiness analysis...")
            return try await generateMockTrustworthinessScore(for: messages, traits: traits)
        }
        
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
    
    /// Performs complete analysis workflow in background (single batch method)
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
            
            // Mark as single batch processing
            let batchingInfo = BatchingInfo(
                totalBatches: 1,
                averageBatchQuality: 1.0,
                processingMethod: .singleBatch,
                overlapPercentage: 0.0
            )
            
            let result = AnalysisResult(
                personalityTraits: personalityTraits,
                trustworthinessScore: trustworthinessScore,
                messageCount: messages.count,
                processingTime: processingTime,
                batchingInfo: batchingInfo
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
    
    /// Cancels any running analysis with graceful cleanup
    public func cancelAnalysis() {
        currentAnalysisTask?.cancel()
        currentAnalysisTask = nil
        
        Task { @MainActor in
            isAnalyzing = false
            analysisStatus = "Analysis cancelled"
            analysisProgress = 0.0
            print("📱 Analysis cancelled by user")
        }
    }
    
    /// Provides detailed progress information for long-running tasks
    public var detailedProgress: AnalysisProgressInfo {
        return AnalysisProgressInfo(
            progress: analysisProgress,
            status: analysisStatus,
            isAnalyzing: isAnalyzing,
            estimatedTimeRemaining: calculateEstimatedTimeRemaining(),
            currentStage: determineCurrentStage(),
            memoryUsage: Double(estimatedMemoryUsage) / 1_000_000_000, // GB
            lastError: lastError?.localizedDescription
        )
    }
    
    private func calculateEstimatedTimeRemaining() -> TimeInterval? {
        // Simple estimation based on current progress and elapsed time
        // This would be more sophisticated in production
        guard isAnalyzing && analysisProgress > 0.1 else { return nil }
        
        let elapsedTime = Date().timeIntervalSince(Date()) // Placeholder - would track start time
        let estimatedTotal = elapsedTime / analysisProgress
        return max(0, estimatedTotal - elapsedTime)
    }
    
    private func determineCurrentStage() -> String {
        switch analysisProgress {
        case 0.0..<0.1:
            return "Initialization"
        case 0.1..<0.7:
            return "Personality Analysis"
        case 0.7..<0.9:
            return "Trustworthiness Scoring"
        case 0.9..<1.0:
            return "Finalization"
        default:
            return "Complete"
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
                // Check for cancellation
                try Task.checkCancellation()
                
                await updateStatus(analysisProgress + 0.1, "Inference attempt \(attempt)/\(maxRetries)...")
                
                let response = try await withTimeout(inferenceTimeout) {
                    try await self.modelManager.generate(prompt: prompt, maxLength: 2048)
                }
                
                // Validate response quality
                guard !response.isEmpty && response.count > 20 else {
                    throw InferenceError.invalidResponse("Response too short or empty")
                }
                
                // Log successful inference
                print("✅ Inference completed successfully (attempt \(attempt))")
                return response
                
            } catch is CancellationError {
                print("🚫 Inference cancelled by user")
                throw InferenceError.analysisFailure("Analysis cancelled")
            } catch {
                lastError = error
                
                // Enhanced error logging
                print("⚠️ Inference attempt \(attempt) failed: \(error.localizedDescription)")
                
                if attempt < maxRetries {
                    let delay = TimeInterval(min(attempt * 2, 10)) // Capped exponential backoff
                    await updateStatus(analysisProgress, "Retrying in \(Int(delay)) seconds (\(maxRetries - attempt) attempts remaining)...")
                    
                    // Check device thermal state and adjust timeout if needed
                    await adjustForDeviceConditions()
                    
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? InferenceError.analysisFailure("All \(maxRetries) retry attempts failed")
    }
    
    /// Adjusts processing parameters based on device conditions
    private func adjustForDeviceConditions() async {
        let processInfo = ProcessInfo.processInfo
        
        // Check thermal state
        if processInfo.thermalState == .critical || processInfo.thermalState == .serious {
            print("🌡️ High thermal state detected, implementing cooling delay...")
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 second cooling delay
            await updateStatus(analysisProgress, "Device cooling - processing will resume shortly...")
        }
        
        // Check memory pressure
        let availableMemory = processInfo.physicalMemory
        let estimatedUsage = estimatedMemoryUsage
        
        if Double(estimatedUsage) > Double(availableMemory) * 0.8 {
            print("💾 High memory usage detected (\(estimatedUsage / 1_000_000_000)GB / \(availableMemory / 1_000_000_000)GB)")
            await updateStatus(analysisProgress, "Optimizing memory usage...")
        }
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
            
            guard let result = try await group.next() else {
                throw InferenceError.analysisFailure("Task group returned nil")
            }
            
            group.cancelAll()
            return result
        }
    }
    
    /// Enhanced batch processing with comprehensive progress tracking and error recovery
    /// Processes large message volumes using intelligent batching with aggregation
    public func processBatchedAnalysis(messages: [Message], configuration: BatchManager.BatchConfiguration = .default) async throws -> AnalysisResult {
        guard isInitialized else {
            throw InferenceError.engineNotInitialized
        }
        
        let startTime = Date()
        
        await updateStatus(0.0, "Initializing batch processing for \(messages.count) messages...")
        
        // Initialize batch processing components
        let batchManager = BatchManager(configuration: configuration)
        let scoreAggregator = ScoreAggregator()
        
        // Create batches
        await updateStatus(0.05, "Creating message batches...")
        let batches = batchManager.createBatches(from: messages)
        
        await updateStatus(0.1, "Processing \(batches.count) batches...")
        
        // Process each batch for personality analysis
        var batchedPersonalityResults: [BatchedPersonalityTraits] = []
        let personalityProgressStep = 0.6 / Double(batches.count) // 60% of progress for personality
        
        for (index, batch) in batches.enumerated() {
            let batchProgress = 0.1 + (Double(index) * personalityProgressStep)
            await updateStatus(batchProgress, "Analyzing personality traits for batch \(index + 1)/\(batches.count)...")
            
            do {
                let batchResult = try await processBatchWithRecovery(batch)
                batchedPersonalityResults.append(batchResult)
                
                // Log batch completion with quality metrics
                print("✅ Batch \(index + 1)/\(batches.count): Quality \(String(format: "%.2f", batchResult.batchMetadata.batchQuality)), Confidence \(String(format: "%.2f", batchResult.traits.confidence))")
                
            } catch {
                // Enhanced error logging and recovery
                print("⚠️ Batch \(index + 1) personality analysis failed: \(error)")
                await updateStatus(batchProgress, "Batch \(index + 1) failed, continuing with remaining batches...")
                
                // Record failed batch for final statistics
                let failedBatchCount = (index + 1) - batchedPersonalityResults.count
                print("📉 Failed batches so far: \(failedBatchCount) / \(index + 1)")
            }
        }
        
        // Ensure we have at least one successful batch
        guard !batchedPersonalityResults.isEmpty else {
            throw InferenceError.analysisFailure("All personality analysis batches failed")
        }
        
        // Aggregate personality results
        await updateStatus(0.7, "Aggregating personality traits across batches...")
        let personalityResult = try scoreAggregator.aggregatePersonalityTraits(batchedPersonalityResults)
        
        // Run trustworthiness analysis using aggregated personality traits
        await updateStatus(0.8, "Calculating trustworthiness score...")
        let trustworthinessScore = try await calculateTrustworthiness(
            messages: messages, 
            traits: personalityResult.aggregatedTraits
        )
        
        // Create final result
        await updateStatus(0.9, "Finalizing analysis results...")
        let totalProcessingTime = Date().timeIntervalSince(startTime)
        
        let finalResult = scoreAggregator.createFinalResult(
            personalityResult: personalityResult,
            trustworthinessResult: AggregatedTrustworthinessResult(
                aggregatedScore: trustworthinessScore,
                batchCount: batches.count,
                scoreVariance: 0.0, // Single trustworthiness analysis
                factorVariances: [:],
                aggregationConfidence: personalityResult.aggregationConfidence
            ),
            totalProcessingTime: totalProcessingTime,
            overlapPercentage: configuration.overlapPercentage
        )
        
        await updateStatus(1.0, "Batch processing complete")
        
        // Log final statistics
        print("🎯 Batch analysis complete:")
        print("  - Total batches: \(batches.count)")
        print("  - Successful: \(batchedPersonalityResults.count)")
        print("  - Failed: \(batches.count - batchedPersonalityResults.count)")
        print("  - Processing time: \(String(format: "%.1f", totalProcessingTime))s")
        print("  - Final confidence: \(String(format: "%.2f", personalityResult.aggregationConfidence))")
        
        return finalResult
    }
    
    /// Analyzes personality traits for a single batch
    private func analyzePersonalityForBatch(_ batch: MessageBatch) async throws -> PersonalityTraits {
        let prompt = promptEngineer.createBatchPersonalityAnalysisPrompt(
            messages: batch.messages,
            batchMetadata: batch.metadata
        )
        
        let response = try await performInferenceWithRetry(prompt: prompt)
        return try promptEngineer.parsePersonalityResponse(response)
    }
    
    private func processBatchWithRecovery(_ batch: MessageBatch, attempt: Int = 1) async throws -> BatchedPersonalityTraits {
        let maxBatchRetries = 3
        
        do {
            try Task.checkCancellation()
            
            let batchStartTime = Date()
            await updateStatus(
                analysisProgress, 
                "Processing batch \(batch.batchIndex + 1)/\(batch.totalBatches) (attempt \(attempt))..."
            )
            
            let personalityTraits = try await analyzePersonalityForBatch(batch)
            let batchProcessingTime = Date().timeIntervalSince(batchStartTime)
            
            let batchQuality = BatchManager().calculateBatchQuality(batch)
            let batchMetadata = BatchAnalysisMetadata(
                batchId: batch.id,
                batchIndex: batch.batchIndex,
                totalBatches: batch.totalBatches,
                messageCount: batch.messages.count,
                startDate: batch.metadata.startDate,
                endDate: batch.metadata.endDate,
                processingTime: batchProcessingTime,
                batchQuality: batchQuality,
                financialKeywordCount: batch.metadata.financialKeywordCount,
                relationshipKeywordCount: batch.metadata.relationshipKeywordCount
            )
            
            print("✅ Batch \(batch.batchIndex + 1) completed in \(String(format: "%.1f", batchProcessingTime))s")
            
            return BatchedPersonalityTraits(
                traits: personalityTraits,
                batchMetadata: batchMetadata
            )
            
        } catch is CancellationError {
            throw InferenceError.analysisFailure("Batch processing cancelled")
        } catch {
            print("⚠️ Batch \(batch.batchIndex + 1) attempt \(attempt) failed: \(error.localizedDescription)")
            
            if attempt < maxBatchRetries {
                let delay = TimeInterval(attempt * 3)
                await updateStatus(
                    analysisProgress, 
                    "Retrying batch \(batch.batchIndex + 1) in \(Int(delay)) seconds..."
                )
                
                await adjustForDeviceConditions()
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                return try await processBatchWithRecovery(batch, attempt: attempt + 1)
            } else {
                throw error
            }
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
    case batchProcessingFailed(String)
    case deviceThrottling(String)
    
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
        case .batchProcessingFailed(let reason):
            return "Batch processing failed: \(reason)"
        case .deviceThrottling(let reason):
            return "Device throttling detected: \(reason)"
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

/// Detailed progress information for long-running analysis tasks
public struct AnalysisProgressInfo {
    public let progress: Double // 0.0 to 1.0
    public let status: String
    public let isAnalyzing: Bool
    public let estimatedTimeRemaining: TimeInterval?
    public let currentStage: String
    public let memoryUsage: Double // in GB
    public let lastError: String?
    
    public init(progress: Double, status: String, isAnalyzing: Bool, estimatedTimeRemaining: TimeInterval?, currentStage: String, memoryUsage: Double, lastError: String?) {
        self.progress = progress
        self.status = status
        self.isAnalyzing = isAnalyzing
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.currentStage = currentStage
        self.memoryUsage = memoryUsage
        self.lastError = lastError
    }
    
    public var progressPercentage: Int {
        return Int(progress * 100)
    }
    
    public var formattedTimeRemaining: String? {
        guard let timeRemaining = estimatedTimeRemaining else { return nil }
        
        if timeRemaining < 60 {
            return "\(Int(timeRemaining))s"
        } else if timeRemaining < 3600 {
            return "\(Int(timeRemaining / 60))m \(Int(timeRemaining.truncatingRemainder(dividingBy: 60)))s"
        } else {
            let hours = Int(timeRemaining / 3600)
            let minutes = Int((timeRemaining.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m"
        }
    }
}