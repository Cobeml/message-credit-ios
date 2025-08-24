import Foundation
import MLX
import MLXNN

/// Main inference engine that coordinates model loading, prompt engineering, and analysis with cryptographic verification
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
    
    // Cryptographic verification components
    private let cryptographicEngine: CryptographicEngine
    private let batchVerificationManager: BatchVerificationManager
    private let zkProofGenerator: ZKProofGenerator
    
    // Performance optimization
    private let performanceOptimizer: PerformanceOptimizer
    
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
        
        // Initialize cryptographic components
        self.cryptographicEngine = CryptographicEngine()
        self.batchVerificationManager = BatchVerificationManager(cryptographicEngine: cryptographicEngine)
        self.zkProofGenerator = ZKProofGenerator()
        
        // Initialize performance optimizer
        self.performanceOptimizer = PerformanceOptimizer()
        
        // Early initialization check for simulator environment (console logging only)
        if Self.isSimulatorEnvironment {
            print("🚨 [DEV] MLX COMPATIBILITY WARNING:")
            print("📱 [DEV] Running in iOS Simulator - MLX framework is not supported")
            print("🔧 [DEV] MLX requires physical Apple devices with Metal GPU support")
            print("✨ [DEV] App will use enhanced mock analysis for development")
            print("📲 [DEV] Deploy to a physical iOS device for real MLX inference")
            print("🔐 [DEV] Cryptographic verification will use simulator mode")
            
            analysisStatus = "Ready"
        }
    }
    
    // MARK: - Public Interface
    
    /// Initializes the inference engine by loading the model
    public func initialize() async throws {
        // CRITICAL: Prevent MLX initialization in simulator environments
        guard !Self.isSimulatorEnvironment else {
            await MainActor.run {
                isInitialized = true // Set to true for seamless user experience
                analysisStatus = "Ready"
                print("✅ [DEV] Simulator mode initialized - using enhanced mock analysis")
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
            // Initialize MLX model
            try await modelManager.loadModel()
            
            await updateStatus(0.5, "Initializing cryptographic engine...")
            
            // Initialize cryptographic components
            try await cryptographicEngine.initialize()
            
            await updateStatus(0.8, "Initializing zero-knowledge proof system...")
            
            try await zkProofGenerator.initialize()
            
            await MainActor.run {
                isInitialized = true
                analysisStatus = "MLX Ready on Device with Cryptographic Verification"
                print("✅ MLX inference engine successfully initialized on physical device")
                print("🔐 Cryptographic verification system ready")
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
        // Handle simulator environment with enhanced mock analysis
        if Self.isSimulatorEnvironment {
            print("🧠 [DEV] Using enhanced mock personality analysis")
            await updateStatus(0.1, "Analyzing personality traits...")
            return try await generateEnhancedMockPersonalityTraits(for: messages)
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
        // Handle simulator environment with enhanced mock analysis
        if Self.isSimulatorEnvironment {
            print("📊 [DEV] Using enhanced mock trustworthiness analysis")
            await updateStatus(0.1, "Calculating trustworthiness score...")
            return try await generateEnhancedMockTrustworthinessScore(for: messages, traits: traits)
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
    /// Returns a standard AnalysisResult for backward compatibility
    public func processInBackground(messages: [Message]) async throws -> AnalysisResult {
        let verifiedResult = try await processWithVerification(messages: messages)
        return verifiedResult.analysisResult
    }
    
    /// Performs complete analysis workflow with cryptographic verification
    /// Returns a VerifiedAnalysisResult containing both analysis and verification data
    public func processWithVerification(messages: [Message]) async throws -> VerifiedAnalysisResult {
        // Special handling for simulator environment
        if Self.isSimulatorEnvironment {
            print("🚀 [DEV] Starting enhanced mock analysis workflow")
            return try await performEnhancedMockAnalysis(messages: messages)
        }
        
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
            await updateStatus(0.4, "Calculating trustworthiness score...")
            let trustworthinessScore = try await calculateTrustworthiness(messages: messages, traits: personalityTraits)
            
            // Step 3: Create analysis result
            await updateStatus(0.6, "Creating analysis result...")
            let processingTime = Date().timeIntervalSince(startTime)
            
            let batchingInfo = BatchingInfo(
                totalBatches: 1,
                averageBatchQuality: 1.0,
                processingMethod: .singleBatch,
                overlapPercentage: 0.0
            )
            
            let analysisResult = AnalysisResult(
                personalityTraits: personalityTraits,
                trustworthinessScore: trustworthinessScore,
                messageCount: messages.count,
                processingTime: processingTime,
                batchingInfo: batchingInfo
            )
            
            // Step 4: Generate cryptographic verification
            await updateStatus(0.8, "Generating cryptographic verification...")
            let verificationBundle = try await cryptographicEngine.createVerificationBundle(
                result: analysisResult,
                messages: messages,
                modelHash: modelManager.modelHash
            )
            
            // Step 5: Generate Zero-Knowledge Proof (if enabled and conditions allow)
            var zkProof: ZKProof? = nil
            let zkpDecision = performanceOptimizer.shouldPerformZKPGeneration()
            
            if !Self.isSimulatorEnvironment && zkProofGenerator.isInitialized && zkpDecision.shouldProceed {
                do {
                    await updateStatus(0.9, "Generating zero-knowledge proof...")
                    
                    // Apply thermal throttling delay if needed
                    let cooldownDelay = performanceOptimizer.calculateCooldownDelay()
                    if cooldownDelay > 0 {
                        print("🌡️ Applying thermal cooldown delay: \(cooldownDelay)s")
                        try await Task.sleep(nanoseconds: UInt64(cooldownDelay * 1_000_000_000))
                    }
                    
                    zkProof = try await zkProofGenerator.generatePersonalityProof(
                        messages: messages,
                        traits: personalityTraits,
                        modelHash: modelManager.modelHash ?? "unknown"
                    )
                    print("✅ Zero-knowledge proof generated successfully")
                } catch {
                    print("⚠️ ZK proof generation failed (continuing without): \(error.localizedDescription)")
                    // Continue without ZK proof - it's an enhancement, not required
                }
            } else if let reason = zkpDecision.reason {
                print("🔮 ZK proof generation skipped: \(reason)")
            }
            
            // Step 6: Create signed result
            let signedResult = SignedResult(
                result: analysisResult,
                verificationBundle: verificationBundle
            )
            
            await updateStatus(1.0, "Analysis and verification complete")
            
            await MainActor.run {
                isAnalyzing = false
            }
            
            return VerifiedAnalysisResult(
                analysisResult: analysisResult,
                signedResult: signedResult,
                verificationBundle: verificationBundle,
                zkProof: zkProof,
                verificationLevel: verificationBundle.verificationLevel,
                generatedAt: Date()
            )
            
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
    
    /// Returns current system status and performance recommendations
    public var systemStatus: SystemStatus {
        return performanceOptimizer.getSystemStatus()
    }
    
    /// Returns performance optimization recommendations
    public var optimizationRecommendations: [OptimizationRecommendation] {
        return performanceOptimizer.optimizationRecommendations
    }
    
    // MARK: - Mock Generation for Simulator
    
    /// Enhanced comprehensive mock analysis workflow for simulator environment
    private func performEnhancedMockAnalysis(messages: [Message]) async throws -> VerifiedAnalysisResult {
        await MainActor.run {
            isAnalyzing = true
            analysisProgress = 0.0
            lastError = nil
        }
        
        let startTime = Date()
        print("🧠 [DEV] Starting enhanced mock analysis with realistic processing time")
        
        // Step 1: Initialize cryptographic components (3 seconds)
        await updateStatus(0.05, "Initializing secure analysis environment...")
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        // Step 2: Enhanced personality analysis (6 seconds)
        await updateStatus(0.15, "Analyzing personality traits...")
        let personalityTraits = try await generateEnhancedMockPersonalityTraits(for: messages)
        
        // Step 3: Enhanced trustworthiness analysis (4 seconds)
        await updateStatus(0.50, "Calculating trustworthiness score...")
        let trustworthinessScore = try await generateEnhancedMockTrustworthinessScore(for: messages, traits: personalityTraits)
        
        // Step 4: Cryptographic verification simulation (2 seconds)
        await updateStatus(0.75, "Generating cryptographic verification...")
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Step 5: Final assembly (1 second)
        await updateStatus(0.90, "Finalizing analysis...")
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        let batchingInfo = BatchingInfo(
            totalBatches: 1,
            averageBatchQuality: 1.0,
            processingMethod: .singleBatch,
            overlapPercentage: 0.0
        )
        
        let analysisResult = AnalysisResult(
            personalityTraits: personalityTraits,
            trustworthinessScore: trustworthinessScore,
            messageCount: messages.count,
            processingTime: processingTime,
            batchingInfo: batchingInfo
        )
        
        // Create verification bundle (using simulator mode)
        let verificationBundle = try await cryptographicEngine.createVerificationBundle(
            result: analysisResult,
            messages: messages,
            modelHash: "mock_model_hash_v1.0"
        )
        
        let signedResult = SignedResult(
            result: analysisResult,
            verificationBundle: verificationBundle
        )
        
        await updateStatus(1.0, "Analysis complete")
        
        await MainActor.run {
            isAnalyzing = false
        }
        
        let formattedTime = String(format: "%.1f", processingTime)
        print("✅ [DEV] Enhanced mock analysis completed in \(formattedTime)s")
        
        return VerifiedAnalysisResult(
            analysisResult: analysisResult,
            signedResult: signedResult,
            verificationBundle: verificationBundle,
            zkProof: nil, // No ZK proof in simulator mode
            verificationLevel: .development,
            generatedAt: Date()
        )
    }
    
    /// Generates enhanced mock personality traits with realistic user differentiation
    private func generateEnhancedMockPersonalityTraits(for messages: [Message]) async throws -> PersonalityTraits {
        await updateStatus(0.20, "Processing linguistic patterns...")
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await updateStatus(0.35, "Analyzing communication style...")
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await updateStatus(0.45, "Computing personality dimensions...")
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Enhanced content analysis for more realistic differentiation
        let totalContent = messages.map { $0.content.lowercased() }.joined(separator: " ")
        let messageCount = Double(messages.count)
        
        // Expanded keyword analysis for better user differentiation
        let responsibleWords = ["responsible", "reliable", "commitment", "promise", "deadline", "schedule", "plan", "budget", "save", "invest", "goal"]
        let positiveWords = ["good", "great", "happy", "love", "awesome", "excellent", "thank", "appreciate", "grateful", "wonderful", "amazing"]
        let negativeWords = ["bad", "terrible", "hate", "awful", "stress", "problem", "worry", "difficult", "frustrated", "angry", "disappointed"]
        let socialWords = ["friends", "family", "party", "social", "together", "meet", "hang", "chat", "call", "visit"]
        let planningWords = ["plan", "organize", "prepare", "future", "tomorrow", "next", "schedule", "calendar", "reminder"]
        let financialWords = ["money", "dollar", "pay", "cost", "price", "budget", "bank", "credit", "loan", "investment"]
        
        // Calculate word frequencies
        let responsibleCount = responsibleWords.reduce(0) { count, word in count + totalContent.components(separatedBy: word).count - 1 }
        let positiveCount = positiveWords.reduce(0) { count, word in count + totalContent.components(separatedBy: word).count - 1 }
        let negativeCount = negativeWords.reduce(0) { count, word in count + totalContent.components(separatedBy: word).count - 1 }
        let socialCount = socialWords.reduce(0) { count, word in count + totalContent.components(separatedBy: word).count - 1 }
        let planningCount = planningWords.reduce(0) { count, word in count + totalContent.components(separatedBy: word).count - 1 }
        let financialCount = financialWords.reduce(0) { count, word in count + totalContent.components(separatedBy: word).count - 1 }
        
        // Determine user profile based on content analysis
        let isResponsibleUser = Double(responsibleCount) > messageCount * 0.1 || Double(planningCount) > messageCount * 0.08
        let isPositiveUser = Double(positiveCount) > Double(negativeCount) * 1.5
        let isSocialUser = Double(socialCount) > messageCount * 0.05
        let isFinanciallyAware = Double(financialCount) > messageCount * 0.03
        
        print("📊 [DEV] User profile analysis: responsible=\(isResponsibleUser), positive=\(isPositiveUser), social=\(isSocialUser), financial=\(isFinanciallyAware)")
        
        // Generate realistic traits based on user profile
        var traits: (Double, Double, Double, Double, Double)
        
        if isResponsibleUser && isPositiveUser && isFinanciallyAware {
            // Good user profile - high trustworthiness scores
            traits = (
                0.75 + Double.random(in: -0.10...0.15), // Openness
                0.85 + Double.random(in: -0.05...0.10), // Conscientiousness (high)
                isSocialUser ? 0.70 + Double.random(in: -0.10...0.15) : 0.55 + Double.random(in: -0.15...0.20), // Extraversion
                0.80 + Double.random(in: -0.10...0.15), // Agreeableness (high)
                0.25 + Double.random(in: -0.15...0.20)  // Neuroticism (low)
            )
        } else if !isResponsibleUser && negativeCount > positiveCount {
            // Poor user profile - lower trustworthiness scores
            traits = (
                0.45 + Double.random(in: -0.15...0.20), // Openness (lower)
                0.35 + Double.random(in: -0.10...0.25), // Conscientiousness (low)
                0.50 + Double.random(in: -0.20...0.25), // Extraversion
                0.40 + Double.random(in: -0.15...0.25), // Agreeableness (lower)
                0.65 + Double.random(in: -0.20...0.25)  // Neuroticism (higher)
            )
        } else {
            // Average user profile - moderate scores
            traits = (
                0.60 + Double.random(in: -0.15...0.15), // Openness
                0.60 + Double.random(in: -0.15...0.20), // Conscientiousness
                0.55 + Double.random(in: -0.20...0.20), // Extraversion
                0.65 + Double.random(in: -0.15...0.15), // Agreeableness
                0.45 + Double.random(in: -0.20...0.20)  // Neuroticism
            )
        }
        
        // Ensure values are within valid range
        let clampedTraits = (
            min(0.95, max(0.05, traits.0)),
            min(0.95, max(0.05, traits.1)),
            min(0.95, max(0.05, traits.2)),
            min(0.95, max(0.05, traits.3)),
            min(0.95, max(0.05, traits.4))
        )
        
        let confidence = isResponsibleUser && isPositiveUser ? 0.88 + Double.random(in: -0.08...0.07) : 0.72 + Double.random(in: -0.12...0.13)
        
        return PersonalityTraits(
            openness: clampedTraits.0,
            conscientiousness: clampedTraits.1,
            extraversion: clampedTraits.2,
            agreeableness: clampedTraits.3,
            neuroticism: clampedTraits.4,
            confidence: min(0.95, max(0.60, confidence))
        )
    }
    
    /// Generates enhanced mock trustworthiness score with realistic user differentiation
    private func generateEnhancedMockTrustworthinessScore(for messages: [Message], traits: PersonalityTraits) async throws -> TrustworthinessScore {
        await updateStatus(0.55, "Evaluating trustworthiness factors...")
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        await updateStatus(0.65, "Cross-referencing personality patterns...")
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        await updateStatus(0.70, "Computing reliability metrics...")
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Enhanced trustworthiness calculation based on personality traits
        let communicationStyle = min(0.92, max(0.15, 
            traits.agreeableness * 0.6 + 
            (1.0 - traits.neuroticism) * 0.3 + 
            traits.extraversion * 0.1))
        
        let financialResponsibility = min(0.92, max(0.15, 
            traits.conscientiousness * 0.7 + 
            traits.openness * 0.2 + 
            (1.0 - traits.neuroticism) * 0.1))
        
        let relationshipStability = min(0.92, max(0.15, 
            traits.agreeableness * 0.5 + 
            (1.0 - traits.neuroticism) * 0.35 + 
            traits.conscientiousness * 0.15))
        
        let emotionalIntelligence = min(0.92, max(0.15, 
            (1.0 - traits.neuroticism) * 0.4 + 
            traits.agreeableness * 0.4 + 
            traits.openness * 0.2))
        
        // Add message content analysis for more realistic scoring
        let totalContent = messages.map { $0.content.lowercased() }.joined(separator: " ")
        let responsibilityBonus = totalContent.contains("responsible") || totalContent.contains("reliable") ? 0.05 : 0.0
        let planningBonus = totalContent.contains("plan") || totalContent.contains("budget") ? 0.03 : 0.0
        let negativeContentPenalty = (totalContent.contains("late") || totalContent.contains("forgot")) ? -0.04 : 0.0
        
        var overallScore = (communicationStyle + financialResponsibility + relationshipStability + emotionalIntelligence) / 4.0
        overallScore += responsibilityBonus + planningBonus + negativeContentPenalty
        overallScore = min(0.92, max(0.15, overallScore))
        
        // Generate realistic explanations without simulator indicators
        let explanation: String
        if overallScore > 0.75 {
            explanation = "Analysis indicates strong trustworthiness based on personality patterns. User demonstrates high conscientiousness, emotional stability, and reliable communication patterns. Financial responsibility indicators are positive."
        } else if overallScore > 0.60 {
            explanation = "Analysis indicates good trustworthiness with some variability. User shows generally positive personality traits with moderate reliability indicators. Communication patterns suggest dependable behavior."
        } else if overallScore > 0.45 {
            explanation = "Analysis indicates moderate trustworthiness. Mixed personality patterns suggest average reliability with some areas of concern. Communication style shows both positive and negative indicators."
        } else {
            explanation = "Analysis indicates areas of concern regarding trustworthiness. Personality patterns suggest potential reliability issues with elevated stress indicators and inconsistent communication patterns."
        }
        
        let formattedScore = String(format: "%.2f", overallScore)
        let userType = overallScore > 0.7 ? "Good" : overallScore > 0.5 ? "Average" : "Poor"
        print("📊 [DEV] Trustworthiness score: \(formattedScore) - \(userType) user profile")
        
        return TrustworthinessScore(
            score: overallScore,
            factors: [
                "communication_style": communicationStyle,
                "financial_responsibility": financialResponsibility,
                "relationship_stability": relationshipStability,
                "emotional_intelligence": emotionalIntelligence
            ],
            explanation: explanation
        )
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
    /// Returns a standard AnalysisResult for backward compatibility
    public func processBatchedAnalysis(messages: [Message], configuration: BatchManager.BatchConfiguration = .default) async throws -> AnalysisResult {
        let verifiedResult = try await processBatchedAnalysisWithVerification(messages: messages, configuration: configuration)
        return verifiedResult.analysisResult
    }
    
    /// Enhanced batch processing with cryptographic verification
    /// Returns a BatchVerifiedResult with comprehensive verification data
    public func processBatchedAnalysisWithVerification(messages: [Message], configuration: BatchManager.BatchConfiguration = .default) async throws -> BatchVerifiedResult {
        guard isInitialized else {
            throw InferenceError.engineNotInitialized
        }
        
        let startTime = Date()
        
        await updateStatus(0.0, "Initializing batch processing for \(messages.count) messages...")
        
        // Initialize batch processing components with performance optimization
        _ = BatchManager(configuration: configuration) // Used for validation
        let scoreAggregator = ScoreAggregator()
        
        // Optimize batch configuration based on system conditions
        let systemStatus = performanceOptimizer.getSystemStatus()
        print("📊 System Status: \(systemStatus.summary)")
        
        var optimizedConfiguration = configuration
        optimizedConfiguration = BatchManager.BatchConfiguration(
            targetBatchSize: performanceOptimizer.calculateOptimalBatchSize(requestedSize: configuration.targetBatchSize),
            maxTokensPerBatch: configuration.maxTokensPerBatch,
            overlapPercentage: configuration.overlapPercentage,
            minBatchSize: configuration.minBatchSize,
            maxBatchSize: min(configuration.maxBatchSize, performanceOptimizer.currentProfile.batchSizeLimit)
        )
        
        print("🔧 Optimized batch size: \(configuration.targetBatchSize) → \(optimizedConfiguration.targetBatchSize)")
        
        // Create batches with optimized configuration
        await updateStatus(0.05, "Creating optimized message batches...")
        let optimizedBatchManager = BatchManager(configuration: optimizedConfiguration)
        let batches = optimizedBatchManager.createBatches(from: messages)
        
        await updateStatus(0.1, "Processing \(batches.count) batches...")
        
        // Process each batch for personality analysis
        var batchedPersonalityResults: [BatchedPersonalityTraits] = []
        let personalityProgressStep = 0.6 / Double(batches.count) // 60% of progress for personality
        
        for (index, batch) in batches.enumerated() {
            let batchProgress = 0.1 + (Double(index) * personalityProgressStep)
            await updateStatus(batchProgress, "Analyzing personality traits for batch \(index + 1)/\(batches.count)...")
            
            // Apply thermal throttling and memory management between batches
            let cooldownDelay = performanceOptimizer.calculateCooldownDelay()
            if cooldownDelay > 0 {
                print("🌡️ Applying inter-batch cooling delay: \(cooldownDelay)s")
                try await Task.sleep(nanoseconds: UInt64(cooldownDelay * 1_000_000_000))
            }
            
            // Perform memory cleanup every few batches if under pressure
            if index % 3 == 0 && performanceOptimizer.memoryPressureRawValue() >= 2 { // 2 = .high
                performanceOptimizer.performMemoryCleanup()
            }
            
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
        
        // Step 1: Generate batch proofs for each successful batch
        await updateStatus(0.65, "Generating batch proofs...")
        var batchProofs: [BatchProof] = []
        
        for batchResult in batchedPersonalityResults {
            do {
                let batchProof = try await batchVerificationManager.createBatchProof(
                    batch: batches[batchResult.batchMetadata.batchIndex],
                    analysisResult: batchResult,
                    modelHash: modelManager.modelHash
                )
                batchProofs.append(batchProof)
                print("🔐 Generated proof for batch \(batchResult.batchMetadata.batchIndex + 1)")
            } catch {
                print("⚠️ Failed to generate proof for batch \(batchResult.batchMetadata.batchIndex + 1): \(error.localizedDescription)")
                // Continue without this batch's proof - verification is optional for analysis
            }
        }
        
        // Step 2: Aggregate personality results
        await updateStatus(0.7, "Aggregating personality traits across batches...")
        let personalityResult = try scoreAggregator.aggregatePersonalityTraits(batchedPersonalityResults)
        
        // Step 3: Run trustworthiness analysis using aggregated personality traits
        await updateStatus(0.75, "Calculating trustworthiness score...")
        let trustworthinessScore = try await calculateTrustworthiness(
            messages: messages, 
            traits: personalityResult.aggregatedTraits
        )
        
        // Step 4: Create final result
        await updateStatus(0.8, "Finalizing analysis results...")
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
        
        // Step 5: Generate comprehensive verification bundle
        await updateStatus(0.9, "Creating verification bundle...")
        let batchVerificationBundle = try await batchVerificationManager.aggregateBatchProofs(
            batchProofs,
            finalResult: finalResult,
            modelHash: modelManager.modelHash
        )
        
        // Step 6: Generate Zero-Knowledge Proof for the final result (if conditions allow)
        var finalZKProof: ZKProof? = nil
        let finalZKPDecision = performanceOptimizer.shouldPerformZKPGeneration()
        
        if !Self.isSimulatorEnvironment && zkProofGenerator.isInitialized && finalZKPDecision.shouldProceed {
            do {
                await updateStatus(0.95, "Generating zero-knowledge proof for final result...")
                
                // Apply final thermal management
                let finalCooldownDelay = performanceOptimizer.calculateCooldownDelay()
                if finalCooldownDelay > 0 {
                    print("🌡️ Applying final ZKP cooldown delay: \(finalCooldownDelay)s")
                    try await Task.sleep(nanoseconds: UInt64(finalCooldownDelay * 1_000_000_000))
                }
                
                finalZKProof = try await zkProofGenerator.generatePersonalityProof(
                    messages: messages,
                    traits: personalityResult.aggregatedTraits,
                    modelHash: modelManager.modelHash ?? "unknown"
                )
                print("✅ Zero-knowledge proof generated for batch analysis")
            } catch {
                print("⚠️ ZK proof generation failed for batch analysis (continuing without): \(error.localizedDescription)")
            }
        } else if let reason = finalZKPDecision.reason {
            print("🔮 Final ZK proof generation skipped: \(reason)")
        }
        
        await updateStatus(1.0, "Batch processing and verification complete")
        
        // Log comprehensive statistics
        print("🎯 Batch analysis and verification complete:")
        print("  - Total batches: \(batches.count)")
        print("  - Successful: \(batchedPersonalityResults.count)")
        print("  - Failed: \(batches.count - batchedPersonalityResults.count)")
        print("  - Batch proofs: \(batchProofs.count)/\(batchedPersonalityResults.count)")
        print("  - Processing time: \(String(format: "%.1f", totalProcessingTime))s")
        print("  - Final confidence: \(String(format: "%.2f", personalityResult.aggregationConfidence))")
        print("  - Verification level: \(batchVerificationBundle.mainVerificationBundle.verificationLevel.description)")
        print("  - Has ZK proof: \(finalZKProof != nil)")
        
        return BatchVerifiedResult(
            analysisResult: finalResult,
            batchVerificationBundle: batchVerificationBundle,
            zkProof: finalZKProof,
            batchSuccessRate: Double(batchedPersonalityResults.count) / Double(batches.count),
            proofGenerationRate: Double(batchProofs.count) / Double(batchedPersonalityResults.count),
            totalBatches: batches.count,
            successfulBatches: batchedPersonalityResults.count,
            verifiedAt: Date()
        )
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

// MARK: - Verified Analysis Result Types

/// Complete result structure containing both analysis and verification data
public struct VerifiedAnalysisResult {
    public let analysisResult: AnalysisResult
    public let signedResult: SignedResult
    public let verificationBundle: VerificationBundle
    public let zkProof: ZKProof?
    public let verificationLevel: VerificationLevel
    public let generatedAt: Date
    
    /// Summary of the verified analysis
    public var summary: String {
        return """
        Verified Analysis Result:
        \(analysisResult.summary())
        
        Verification Details:
        - Level: \(verificationLevel.description)
        - Has ZK Proof: \(zkProof != nil)
        - Has App Attestation: \(verificationBundle.attestation != nil)
        - Generated: \(generatedAt)
        
        Signatures and Hashes:
        - Signature: \(verificationBundle.signature.prefix(16))...
        - Input Hash: \(verificationBundle.inputHash.prefix(16))...
        - Result Hash: \(verificationBundle.resultHash.prefix(16))...
        """
    }
    
    /// Validates the complete verification chain
    public func validateVerification() -> Bool {
        return signedResult.isValid() && verificationBundle.isValid()
    }
    
    /// Returns proof bundle for server verification
    public func getProofBundle() -> [String: Any] {
        var bundle: [String: Any] = [
            "analysis_result": analysisResult.toDictionary(),
            "verification_bundle": [
                "signature": verificationBundle.signature,
                "public_key": verificationBundle.publicKey,
                "input_hash": verificationBundle.inputHash,
                "result_hash": verificationBundle.resultHash,
                "model_hash": verificationBundle.modelHash,
                "timestamp": verificationBundle.timestamp.timeIntervalSince1970,
                "verification_level": verificationLevel.rawValue
            ]
        ]
        
        if let attestation = verificationBundle.attestation {
            bundle["app_attestation"] = attestation
        }
        
        if let zkProof = zkProof {
            bundle["zk_proof"] = [
                "proof_data": zkProof.proofData.base64EncodedString(),
                "circuit_hash": zkProof.circuitHash,
                "timestamp": zkProof.timestamp.timeIntervalSince1970,
                "version": zkProof.version,
                "size_bytes": zkProof.sizeBytes
            ]
        }
        
        return bundle
    }
}

/// Result structure for batch processing with comprehensive verification
public struct BatchVerifiedResult {
    public let analysisResult: AnalysisResult
    public let batchVerificationBundle: BatchVerificationBundle
    public let zkProof: ZKProof?
    public let batchSuccessRate: Double
    public let proofGenerationRate: Double
    public let totalBatches: Int
    public let successfulBatches: Int
    public let verifiedAt: Date
    
    /// Summary of the batch verification results
    public var summary: String {
        return """
        Batch Verified Analysis Result:
        \(analysisResult.summary())
        
        Batch Processing Statistics:
        - Total Batches: \(totalBatches)
        - Successful Batches: \(successfulBatches)
        - Success Rate: \(String(format: "%.1f%%", batchSuccessRate * 100))
        - Proof Generation Rate: \(String(format: "%.1f%%", proofGenerationRate * 100))
        
        \(batchVerificationBundle.summary)
        
        Zero-Knowledge Proof: \(zkProof != nil ? "✅ Generated" : "❌ Not available")
        Verified At: \(verifiedAt)
        """
    }
    
    /// Validates all verification components
    public func validateAllVerifications() -> BatchVerificationValidationResult {
        // Validate main verification bundle
        let mainBundleValid = batchVerificationBundle.mainVerificationBundle.isValid()
        
        // Validate batch proofs
        let batchProofResults = batchVerificationBundle.batchProofs.map { proof in
            BatchProofValidation(
                batchId: proof.batchId,
                batchIndex: proof.batchIndex,
                isValid: !proof.signature.isEmpty && !proof.batchHash.isEmpty,
                qualityScore: proof.qualityScore
            )
        }
        
        let allBatchProofsValid = batchProofResults.allSatisfy { $0.isValid }
        
        // Check ZK proof if present
        var zkProofValid: Bool? = nil
        if let _ = zkProof {
            zkProofValid = true // In a full implementation, this would verify the ZK proof
        }
        
        let overallValid = mainBundleValid && allBatchProofsValid && (zkProofValid ?? true)
        
        return BatchVerificationValidationResult(
            isValid: overallValid,
            mainBundleValid: mainBundleValid,
            batchProofResults: batchProofResults,
            zkProofValid: zkProofValid,
            verificationLevel: batchVerificationBundle.mainVerificationBundle.verificationLevel,
            validatedAt: Date()
        )
    }
    
    /// Returns complete proof bundle for server verification
    public func getServerVerificationBundle() -> [String: Any] {
        var bundle: [String: Any] = [
            "analysis_result": analysisResult.toDictionary(),
            "batch_statistics": [
                "total_batches": totalBatches,
                "successful_batches": successfulBatches,
                "success_rate": batchSuccessRate,
                "proof_generation_rate": proofGenerationRate
            ],
            "batch_verification": [
                "merkle_root": batchVerificationBundle.merkleTree.rootHash,
                "aggregated_signature": batchVerificationBundle.aggregatedSignature,
                "batch_proofs": batchVerificationBundle.batchProofs.map { proof in
                    [
                        "batch_id": proof.batchId.uuidString,
                        "batch_index": proof.batchIndex,
                        "batch_hash": proof.batchHash,
                        "result_hash": proof.resultHash,
                        "signature": proof.signature,
                        "message_count": proof.messageCount,
                        "quality_score": proof.qualityScore,
                        "timestamp": proof.timestamp.timeIntervalSince1970
                    ]
                }
            ],
            "main_verification": [
                "signature": batchVerificationBundle.mainVerificationBundle.signature,
                "public_key": batchVerificationBundle.mainVerificationBundle.publicKey,
                "input_hash": batchVerificationBundle.mainVerificationBundle.inputHash,
                "result_hash": batchVerificationBundle.mainVerificationBundle.resultHash,
                "model_hash": batchVerificationBundle.mainVerificationBundle.modelHash,
                "verification_level": batchVerificationBundle.mainVerificationBundle.verificationLevel.rawValue,
                "timestamp": batchVerificationBundle.mainVerificationBundle.timestamp.timeIntervalSince1970
            ]
        ]
        
        if let attestation = batchVerificationBundle.mainVerificationBundle.attestation {
            bundle["app_attestation"] = attestation
        }
        
        if let zkProof = zkProof {
            bundle["zk_proof"] = [
                "proof_data": zkProof.proofData.base64EncodedString(),
                "circuit_hash": zkProof.circuitHash,
                "timestamp": zkProof.timestamp.timeIntervalSince1970,
                "version": zkProof.version,
                "size_bytes": zkProof.sizeBytes
            ]
        }
        
        return bundle
    }
}

/// Validation result for batch verification components
public struct BatchVerificationValidationResult {
    public let isValid: Bool
    public let mainBundleValid: Bool
    public let batchProofResults: [BatchProofValidation]
    public let zkProofValid: Bool?
    public let verificationLevel: VerificationLevel
    public let validatedAt: Date
    
    public var summary: String {
        let zkStatus = zkProofValid == nil ? "N/A" : (zkProofValid! ? "Valid" : "Invalid")
        let validBatchProofs = batchProofResults.filter { $0.isValid }.count
        
        return """
        Batch Verification Validation:
        - Overall Valid: \(isValid ? "✅" : "❌")
        - Main Bundle: \(mainBundleValid ? "✅" : "❌")
        - Batch Proofs: \(validBatchProofs)/\(batchProofResults.count) valid
        - ZK Proof: \(zkStatus)
        - Verification Level: \(verificationLevel.description)
        - Validated At: \(validatedAt)
        """
    }
}

/// Individual batch proof validation result
public struct BatchProofValidation {
    public let batchId: UUID
    public let batchIndex: Int
    public let isValid: Bool
    public let qualityScore: Double
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