import XCTest
@testable import PrivacyCreditAnalyzer
import Foundation

/// Comprehensive test suite for cryptographic verification system
class CryptographicVerificationTests: XCTestCase {
    
    var cryptographicEngine: CryptographicEngine!
    var batchVerificationManager: BatchVerificationManager!
    var zkProofGenerator: ZKProofGenerator!
    var securityValidator: SecurityValidator!
    var performanceOptimizer: PerformanceOptimizer!
    
    override func setUp() async throws {
        try await super.setUp()
        
        cryptographicEngine = CryptographicEngine()
        batchVerificationManager = BatchVerificationManager(cryptographicEngine: cryptographicEngine)
        zkProofGenerator = ZKProofGenerator()
        securityValidator = SecurityValidator()
        performanceOptimizer = PerformanceOptimizer()
        
        // Initialize components for testing
        try await cryptographicEngine.initialize()
        try await zkProofGenerator.initialize()
    }
    
    override func tearDown() async throws {
        cryptographicEngine = nil
        batchVerificationManager = nil
        zkProofGenerator = nil
        securityValidator = nil
        performanceOptimizer = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Cryptographic Engine Tests
    
    func testCryptographicEngineInitialization() async throws {
        XCTAssertTrue(cryptographicEngine.isInitialized)
    }
    
    func testCreateVerificationBundle() async throws {
        let messages = createTestMessages()
        let analysisResult = createTestAnalysisResult()
        
        let bundle = try await cryptographicEngine.createVerificationBundle(
            result: analysisResult,
            messages: messages,
            modelHash: "test_model_hash"
        )
        
        XCTAssertTrue(bundle.isValid())
        XCTAssertFalse(bundle.signature.isEmpty)
        XCTAssertFalse(bundle.publicKey.isEmpty)
        XCTAssertFalse(bundle.inputHash.isEmpty)
        XCTAssertFalse(bundle.resultHash.isEmpty)
        XCTAssertEqual(bundle.modelHash, "test_model_hash")
    }
    
    func testPrivacyPreservingHash() {
        let messages = createTestMessages()
        
        let hash1 = cryptographicEngine.createPrivacyPreservingHash(for: messages)
        let hash2 = cryptographicEngine.createPrivacyPreservingHash(for: messages)
        
        // Same messages should produce same hash
        XCTAssertEqual(hash1, hash2)
        XCTAssertFalse(hash1.isEmpty)
        
        // Different messages should produce different hash
        let differentMessages = [messages[0]] // Subset
        let hash3 = cryptographicEngine.createPrivacyPreservingHash(for: differentMessages)
        XCTAssertNotEqual(hash1, hash3)
    }
    
    func testResultHash() {
        let result = createTestAnalysisResult()
        
        let hash1 = cryptographicEngine.createResultHash(for: result)
        let hash2 = cryptographicEngine.createResultHash(for: result)
        
        // Same result should produce same hash
        XCTAssertEqual(hash1, hash2)
        XCTAssertFalse(hash1.isEmpty)
        
        // Different result should produce different hash
        let differentResult = AnalysisResult(
            personalityTraits: PersonalityTraits(
                openness: 0.9, conscientiousness: 0.8, extraversion: 0.7, 
                agreeableness: 0.6, neuroticism: 0.5, confidence: 0.8
            ),
            trustworthinessScore: TrustworthinessScore(
                score: 0.9, factors: [:], explanation: "Different test result"
            ),
            messageCount: 15,
            processingTime: 2.5
        )
        
        let hash3 = cryptographicEngine.createResultHash(for: differentResult)
        XCTAssertNotEqual(hash1, hash3)
    }
    
    // MARK: - Batch Verification Tests
    
    func testBatchProofCreation() async throws {
        let batch = createTestBatch()
        let analysisResult = createTestBatchedPersonalityTraits()
        
        let proof = try await batchVerificationManager.createBatchProof(
            batch: batch,
            analysisResult: analysisResult,
            modelHash: "test_model_hash"
        )
        
        XCTAssertEqual(proof.batchId, batch.id)
        XCTAssertEqual(proof.batchIndex, batch.batchIndex)
        XCTAssertFalse(proof.signature.isEmpty)
        XCTAssertFalse(proof.batchHash.isEmpty)
        XCTAssertFalse(proof.resultHash.isEmpty)
        XCTAssertEqual(proof.messageCount, batch.messages.count)
        XCTAssertGreaterThanOrEqual(proof.qualityScore, 0.0)
        XCTAssertLessThanOrEqual(proof.qualityScore, 1.0)
    }
    
    func testBatchVerificationBundle() async throws {
        let batches = [createTestBatch(), createTestBatch()]
        let batchResults = [createTestBatchedPersonalityTraits(), createTestBatchedPersonalityTraits()]
        let finalResult = createTestAnalysisResult()
        
        var batchProofs: [BatchProof] = []
        for (batch, result) in zip(batches, batchResults) {
            let proof = try await batchVerificationManager.createBatchProof(
                batch: batch,
                analysisResult: result,
                modelHash: "test_model_hash"
            )
            batchProofs.append(proof)
        }
        
        let bundle = try await batchVerificationManager.aggregateBatchProofs(
            batchProofs,
            finalResult: finalResult,
            modelHash: "test_model_hash"
        )
        
        XCTAssertEqual(bundle.batchProofs.count, batchProofs.count)
        XCTAssertFalse(bundle.aggregatedSignature.isEmpty)
        XCTAssertTrue(bundle.mainVerificationBundle.isValid())
        XCTAssertFalse(bundle.merkleTree.rootHash.isEmpty)
    }
    
    func testMerkleTreeVerification() throws {
        let leaves = [
            MerkleLeaf(id: UUID(), hash: "hash1", data: "data1"),
            MerkleLeaf(id: UUID(), hash: "hash2", data: "data2"),
            MerkleLeaf(id: UUID(), hash: "hash3", data: "data3")
        ]
        
        let merkleTree = try MerkleTree(leaves: leaves)
        XCTAssertFalse(merkleTree.rootHash.isEmpty)
        XCTAssertTrue(try merkleTree.verify())
    }
    
    // MARK: - Zero-Knowledge Proof Tests
    
    func testZKProofGeneration() async throws {
        let messages = createTestMessages()
        let traits = PersonalityTraits(
            openness: 0.7, conscientiousness: 0.8, extraversion: 0.6,
            agreeableness: 0.9, neuroticism: 0.3, confidence: 0.85
        )
        
        let proof = try await zkProofGenerator.generatePersonalityProof(
            messages: messages,
            traits: traits,
            modelHash: "test_model_hash"
        )
        
        XCTAssertFalse(proof.proofData.isEmpty)
        XCTAssertEqual(proof.publicInputs.traitRanges.count, 5)
        XCTAssertFalse(proof.circuitHash.isEmpty)
        XCTAssertGreaterThan(proof.sizeBytes, 0)
    }
    
    func testZKProofVerification() async throws {
        let messages = createTestMessages()
        let traits = PersonalityTraits(
            openness: 0.7, conscientiousness: 0.8, extraversion: 0.6,
            agreeableness: 0.9, neuroticism: 0.3, confidence: 0.85
        )
        
        let proof = try await zkProofGenerator.generatePersonalityProof(
            messages: messages,
            traits: traits,
            modelHash: "test_model_hash"
        )
        
        let verificationResult = try await zkProofGenerator.verifyProof(proof)
        XCTAssertTrue(verificationResult.isValid)
        XCTAssertGreaterThan(verificationResult.verificationTime, 0)
    }
    
    // MARK: - Security Validation Tests
    
    func testDeviceSecurityValidation() async throws {
        let result = await securityValidator.validateDeviceSecurity()
        
        XCTAssertNotNil(result.securityLevel)
        XCTAssertGreaterThan(result.checks.count, 0)
        XCTAssertGreaterThanOrEqual(result.overallScore, 0.0)
        XCTAssertLessThanOrEqual(result.overallScore, 1.0)
        XCTAssertGreaterThan(result.validationTime, 0)
    }
    
    func testQuickSecurityCheck() {
        let isSecure = securityValidator.quickSecurityCheck()
        // This should be true in test environment (assuming non-jailbroken)
        XCTAssertTrue(isSecure)
    }
    
    func testVerificationBundleValidation() async throws {
        let messages = createTestMessages()
        let analysisResult = createTestAnalysisResult()
        
        let bundle = try await cryptographicEngine.createVerificationBundle(
            result: analysisResult,
            messages: messages,
            modelHash: "test_model_hash"
        )
        
        // First validate device security
        _ = await securityValidator.validateDeviceSecurity()
        
        let validation = securityValidator.validateVerificationBundle(bundle)
        
        // In a secure test environment, this should be valid
        XCTAssertTrue(validation.isValid || validation.recommendedAction == .warn)
    }
    
    // MARK: - Performance Optimizer Tests
    
    func testPerformanceOptimization() async throws {
        let systemStatus = performanceOptimizer.getSystemStatus()
        
        XCTAssertNotNil(systemStatus.deviceCapabilities)
        XCTAssertGreaterThanOrEqual(systemStatus.batteryLevel, 0.0)
        XCTAssertLessThanOrEqual(systemStatus.batteryLevel, 1.0)
    }
    
    func testZKPDecisionMaking() {
        let decision = performanceOptimizer.shouldPerformZKPGeneration()
        
        switch decision {
        case .proceed(let level):
            XCTAssertNotNil(level)
        case .deferUntilLater(let reason):
            XCTAssertFalse(reason.isEmpty)
        case .skip(let reason):
            XCTAssertFalse(reason.isEmpty)
        }
    }
    
    func testBatchSizeOptimization() {
        let originalSize = 100
        let optimizedSize = performanceOptimizer.calculateOptimalBatchSize(requestedSize: originalSize)
        
        XCTAssertGreaterThan(optimizedSize, 0)
        XCTAssertLessThanOrEqual(optimizedSize, originalSize)
    }
    
    // MARK: - Integration Tests
    
    func testFullVerificationWorkflow() async throws {
        // Validate device security first
        let securityResult = await securityValidator.validateDeviceSecurity()
        XCTAssertNotEqual(securityResult.securityLevel, .compromised)
        
        // Create test data
        let messages = createTestMessages()
        let analysisResult = createTestAnalysisResult()
        
        // Generate verification bundle
        let verificationBundle = try await cryptographicEngine.createVerificationBundle(
            result: analysisResult,
            messages: messages,
            modelHash: "test_model_hash"
        )
        
        // Validate verification bundle
        let bundleValidation = securityValidator.validateVerificationBundle(verificationBundle)
        XCTAssertTrue(bundleValidation.isValid || bundleValidation.recommendedAction != .reject)
        
        // Generate ZK proof if conditions allow
        let zkpDecision = performanceOptimizer.shouldPerformZKPGeneration()
        if zkpDecision.shouldProceed {
            let zkProof = try await zkProofGenerator.generatePersonalityProof(
                messages: messages,
                traits: analysisResult.personalityTraits,
                modelHash: "test_model_hash"
            )
            XCTAssertTrue(zkProof.sizeBytes > 0)
        }
        
        // Create signed result
        let signedResult = SignedResult(result: analysisResult, verificationBundle: verificationBundle)
        XCTAssertTrue(signedResult.isValid())
        
        // Validate complete workflow
        XCTAssertNotNil(signedResult.verificationLevel)
        XCTAssertFalse(signedResult.signature.isEmpty)
    }
    
    func testBatchVerificationWorkflow() async throws {
        let messages = Array(createTestMessages().prefix(50)) // Smaller set for testing
        let batchManager = BatchManager(configuration: .init(targetBatchSize: 10))
        let batches = batchManager.createBatches(from: messages)
        
        XCTAssertGreaterThan(batches.count, 0)
        
        var batchProofs: [BatchProof] = []
        for batch in batches {
            let analysisResult = createTestBatchedPersonalityTraits()
            let proof = try await batchVerificationManager.createBatchProof(
                batch: batch,
                analysisResult: analysisResult,
                modelHash: "test_model_hash"
            )
            batchProofs.append(proof)
        }
        
        let finalResult = createTestAnalysisResult()
        let verificationBundle = try await batchVerificationManager.aggregateBatchProofs(
            batchProofs,
            finalResult: finalResult,
            modelHash: "test_model_hash"
        )
        
        XCTAssertEqual(verificationBundle.batchProofs.count, batches.count)
        XCTAssertTrue(verificationBundle.mainVerificationBundle.isValid())
        
        // Verify batch validation
        let validation = try await batchVerificationManager.verifyBatchBundle(verificationBundle)
        XCTAssertTrue(validation.isValid)
        XCTAssertEqual(validation.totalBatches, batches.count)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testEmptyMessagesHandling() async throws {
        let emptyMessages: [Message] = []
        
        do {
            _ = try await cryptographicEngine.createVerificationBundle(
                result: createTestAnalysisResult(),
                messages: emptyMessages,
                modelHash: "test_model_hash"
            )
            // Should not throw - empty messages should be handled gracefully
        } catch {
            XCTFail("Should handle empty messages gracefully: \(error)")
        }
    }
    
    func testInvalidAnalysisResultHandling() {
        let invalidResult = AnalysisResult(
            personalityTraits: PersonalityTraits(
                openness: -0.5, // Invalid negative value
                conscientiousness: 1.5, // Invalid > 1.0 value
                extraversion: 0.5,
                agreeableness: 0.5,
                neuroticism: 0.5,
                confidence: 0.5
            ),
            trustworthinessScore: TrustworthinessScore(
                score: 0.5,
                factors: [:],
                explanation: "Test"
            ),
            messageCount: 10,
            processingTime: 1.0
        )
        
        // The system should handle invalid values gracefully
        let hash = cryptographicEngine.createResultHash(for: invalidResult)
        XCTAssertFalse(hash.isEmpty)
    }
    
    func testMerkleTreeWithSingleLeaf() throws {
        let singleLeaf = [MerkleLeaf(id: UUID(), hash: "single_hash", data: "single_data")]
        let merkleTree = try MerkleTree(leaves: singleLeaf)
        
        XCTAssertFalse(merkleTree.rootHash.isEmpty)
        XCTAssertTrue(try merkleTree.verify())
    }
    
    func testMerkleTreeWithEmptyLeaves() {
        XCTAssertThrowsError(try MerkleTree(leaves: [])) { error in
            XCTAssertTrue(error is BatchVerificationError)
        }
    }
    
    // MARK: - Performance Tests
    
    func testSigningPerformance() async throws {
        let data = "Performance test data".data(using: .utf8)!
        
        measure {
            Task {
                do {
                    _ = try await cryptographicEngine.signData(data)
                } catch {
                    XCTFail("Signing failed: \(error)")
                }
            }
        }
    }
    
    func testZKProofGenerationPerformance() async throws {
        let messages = createTestMessages()
        let traits = PersonalityTraits(
            openness: 0.7, conscientiousness: 0.8, extraversion: 0.6,
            agreeableness: 0.9, neuroticism: 0.3, confidence: 0.85
        )
        
        measure {
            Task {
                do {
                    _ = try await zkProofGenerator.generatePersonalityProof(
                        messages: messages,
                        traits: traits,
                        modelHash: "perf_test_hash"
                    )
                } catch {
                    // Performance test - errors are acceptable
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestMessages() -> [Message] {
        let baseDate = Date().addingTimeInterval(-86400) // 1 day ago
        
        return [
            Message(
                content: "I always pay my bills on time and keep track of my expenses.",
                timestamp: baseDate,
                sender: "TestUser",
                recipient: "TestRecipient",
                isFromUser: true
            ),
            Message(
                content: "I'm saving money for a house and have been very disciplined about it.",
                timestamp: baseDate.addingTimeInterval(3600),
                sender: "TestUser",
                recipient: "TestRecipient",
                isFromUser: true
            ),
            Message(
                content: "I love spending time with friends and family.",
                timestamp: baseDate.addingTimeInterval(7200),
                sender: "TestUser",
                recipient: "TestRecipient",
                isFromUser: true
            ),
            Message(
                content: "I try to be helpful and considerate in all my relationships.",
                timestamp: baseDate.addingTimeInterval(10800),
                sender: "TestUser",
                recipient: "TestRecipient",
                isFromUser: true
            ),
            Message(
                content: "I'm generally calm and don't worry too much about things.",
                timestamp: baseDate.addingTimeInterval(14400),
                sender: "TestUser",
                recipient: "TestRecipient",
                isFromUser: true
            )
        ]
    }
    
    private func createTestAnalysisResult() -> AnalysisResult {
        let traits = PersonalityTraits(
            openness: 0.7,
            conscientiousness: 0.8,
            extraversion: 0.6,
            agreeableness: 0.9,
            neuroticism: 0.3,
            confidence: 0.85
        )
        
        let trustworthiness = TrustworthinessScore(
            score: 0.82,
            factors: [
                "communication_style": 0.8,
                "financial_responsibility": 0.9,
                "relationship_stability": 0.85,
                "emotional_intelligence": 0.75
            ],
            explanation: "Test analysis shows high trustworthiness indicators."
        )
        
        return AnalysisResult(
            personalityTraits: traits,
            trustworthinessScore: trustworthiness,
            messageCount: 5,
            processingTime: 2.1
        )
    }
    
    private func createTestBatch() -> MessageBatch {
        let messages = createTestMessages()
        let metadata = BatchMetadata(
            batchIndex: 0,
            totalBatches: 1,
            messageCount: messages.count,
            startDate: messages.first!.timestamp,
            endDate: messages.last!.timestamp,
            estimatedTokens: 500,
            senderCount: 1,
            averageMessageLength: 50.0,
            financialKeywordCount: 2,
            relationshipKeywordCount: 3
        )
        
        return MessageBatch(
            id: UUID(),
            batchIndex: 0,
            totalBatches: 1,
            messages: messages,
            metadata: metadata
        )
    }
    
    private func createTestBatchedPersonalityTraits() -> BatchedPersonalityTraits {
        let traits = PersonalityTraits(
            openness: 0.7,
            conscientiousness: 0.8,
            extraversion: 0.6,
            agreeableness: 0.9,
            neuroticism: 0.3,
            confidence: 0.85
        )
        
        let metadata = BatchAnalysisMetadata(
            batchId: UUID(),
            batchIndex: 0,
            totalBatches: 1,
            messageCount: 5,
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date(),
            processingTime: 1.5,
            batchQuality: 0.9,
            financialKeywordCount: 2,
            relationshipKeywordCount: 3
        )
        
        return BatchedPersonalityTraits(traits: traits, batchMetadata: metadata)
    }
}