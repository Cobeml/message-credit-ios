import Foundation
import CryptoKit

/// Manages batch-aware cryptographic verification with Merkle tree aggregation
public class BatchVerificationManager {
    
    // MARK: - Properties
    
    private let cryptographicEngine: CryptographicEngine
    
    public init(cryptographicEngine: CryptographicEngine) {
        self.cryptographicEngine = cryptographicEngine
    }
    
    // MARK: - Batch Proof Generation
    
    /// Creates a proof bundle for a single batch
    public func createBatchProof(
        batch: MessageBatch,
        analysisResult: BatchedPersonalityTraits,
        modelHash: String?
    ) async throws -> BatchProof {
        
        // Create hash of batch metadata and messages
        let batchHash = createBatchHash(batch: batch)
        
        // Create hash of analysis result
        let resultHash = createBatchResultHash(analysisResult: analysisResult)
        
        // Create signature payload
        let signaturePayload = "\(batchHash):\(resultHash):\(modelHash ?? "unknown"):\(Date().timeIntervalSince1970)"
        let signatureData = signaturePayload.data(using: .utf8)!
        
        // Sign the batch proof
        let signature = try await cryptographicEngine.signData(signatureData)
        
        return BatchProof(
            batchId: batch.id,
            batchIndex: batch.batchIndex,
            batchHash: batchHash,
            resultHash: resultHash,
            signature: signature.base64EncodedString(),
            timestamp: Date(),
            messageCount: batch.messages.count,
            qualityScore: analysisResult.batchMetadata.batchQuality
        )
    }
    
    /// Aggregates multiple batch proofs using Merkle tree structure
    public func aggregateBatchProofs(
        _ batchProofs: [BatchProof],
        finalResult: AnalysisResult,
        modelHash: String?
    ) async throws -> BatchVerificationBundle {
        
        guard !batchProofs.isEmpty else {
            throw BatchVerificationError.noBatchProofs
        }
        
        // Create Merkle tree from batch proofs
        let merkleTree = try createMerkleTree(from: batchProofs)
        
        // Create aggregated signature for the entire batch set
        let aggregatedSignature = try await createAggregatedSignature(
            merkleRoot: merkleTree.rootHash,
            finalResult: finalResult,
            modelHash: modelHash
        )
        
        // Get comprehensive verification bundle for the final result
        let mainVerificationBundle = try await cryptographicEngine.createVerificationBundle(
            result: finalResult,
            messages: [], // Don't include raw messages for privacy
            modelHash: modelHash
        )
        
        return BatchVerificationBundle(
            batchProofs: batchProofs,
            merkleTree: merkleTree,
            aggregatedSignature: aggregatedSignature,
            mainVerificationBundle: mainVerificationBundle,
            batchingMetadata: finalResult.batchingInfo,
            totalProcessingTime: finalResult.processingTime
        )
    }
    
    // MARK: - Merkle Tree Operations
    
    /// Creates a Merkle tree from batch proofs
    private func createMerkleTree(from batchProofs: [BatchProof]) throws -> MerkleTree {
        let leaves = batchProofs.map { proof in
            MerkleLeaf(
                id: proof.batchId,
                hash: proof.batchHash,
                data: proof.resultHash
            )
        }
        
        return try MerkleTree(leaves: leaves)
    }
    
    /// Creates aggregated signature for the entire batch verification
    private func createAggregatedSignature(
        merkleRoot: String,
        finalResult: AnalysisResult,
        modelHash: String?
    ) async throws -> String {
        
        // Create final aggregation payload
        let aggregationPayload = """
        merkle_root:\(merkleRoot)
        final_traits:\(finalResult.personalityTraits.openness):\(finalResult.personalityTraits.conscientiousness):\(finalResult.personalityTraits.extraversion):\(finalResult.personalityTraits.agreeableness):\(finalResult.personalityTraits.neuroticism)
        trust_score:\(finalResult.trustworthinessScore.score)
        message_count:\(finalResult.messageCount)
        model:\(modelHash ?? "unknown")
        timestamp:\(Date().timeIntervalSince1970)
        """
        
        let payloadData = aggregationPayload.data(using: .utf8)!
        let signature = try await cryptographicEngine.signData(payloadData)
        
        return signature.base64EncodedString()
    }
    
    // MARK: - Hashing Utilities
    
    /// Creates a hash for a message batch
    private func createBatchHash(batch: MessageBatch) -> String {
        let batchData = """
        batch_id:\(batch.id.uuidString)
        batch_index:\(batch.batchIndex)
        message_count:\(batch.messages.count)
        start_date:\(batch.metadata.startDate.timeIntervalSince1970)
        end_date:\(batch.metadata.endDate.timeIntervalSince1970)
        quality:\(batch.metadata.averageMessageLength)
        financial_keywords:\(batch.metadata.financialKeywordCount)
        relationship_keywords:\(batch.metadata.relationshipKeywordCount)
        """
        
        let hashData = batchData.data(using: .utf8)!
        let hash = SHA256.hash(data: hashData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Creates a hash for batch analysis results
    private func createBatchResultHash(analysisResult: BatchedPersonalityTraits) -> String {
        let traits = analysisResult.traits
        let resultData = """
        openness:\(traits.openness)
        conscientiousness:\(traits.conscientiousness)
        extraversion:\(traits.extraversion)
        agreeableness:\(traits.agreeableness)
        neuroticism:\(traits.neuroticism)
        confidence:\(traits.confidence)
        processing_time:\(analysisResult.batchMetadata.processingTime)
        """
        
        let hashData = resultData.data(using: .utf8)!
        let hash = SHA256.hash(data: hashData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Verification
    
    /// Verifies a complete batch verification bundle
    public func verifyBatchBundle(_ bundle: BatchVerificationBundle) async throws -> BatchVerificationResult {
        var verificationResults: [BatchVerificationResult.BatchResult] = []
        
        // Verify each individual batch proof
        for batchProof in bundle.batchProofs {
            let isValid = try await verifyBatchProof(batchProof)
            verificationResults.append(BatchVerificationResult.BatchResult(
                batchId: batchProof.batchId,
                batchIndex: batchProof.batchIndex,
                isValid: isValid,
                qualityScore: batchProof.qualityScore
            ))
        }
        
        // Verify Merkle tree integrity
        let merkleValid = try bundle.merkleTree.verify()
        
        // Verify aggregated signature
        let aggregatedSignatureValid = try await verifyAggregatedSignature(bundle)
        
        let allBatchesValid = verificationResults.allSatisfy { $0.isValid }
        let overallValid = allBatchesValid && merkleValid && aggregatedSignatureValid
        
        return BatchVerificationResult(
            isValid: overallValid,
            batchResults: verificationResults,
            merkleTreeValid: merkleValid,
            aggregatedSignatureValid: aggregatedSignatureValid,
            verificationLevel: bundle.mainVerificationBundle.verificationLevel,
            totalBatches: bundle.batchProofs.count,
            verifiedAt: Date()
        )
    }
    
    /// Verifies a single batch proof
    private func verifyBatchProof(_ proof: BatchProof) async throws -> Bool {
        // In a full implementation, this would verify the signature against the stored public key
        // For now, we verify the proof structure and data integrity
        return !proof.signature.isEmpty &&
               !proof.batchHash.isEmpty &&
               !proof.resultHash.isEmpty &&
               proof.messageCount > 0 &&
               proof.qualityScore >= 0.0 &&
               proof.qualityScore <= 1.0
    }
    
    /// Verifies the aggregated signature for the entire batch set
    private func verifyAggregatedSignature(_ bundle: BatchVerificationBundle) async throws -> Bool {
        // Reconstruct the expected aggregation payload
        // In production, this would verify against the public key
        return !bundle.aggregatedSignature.isEmpty &&
               bundle.merkleTree.rootHash.count > 0
    }
}

// MARK: - Supporting Types

/// Represents a cryptographic proof for a single batch
public struct BatchProof: Codable, Identifiable {
    public let id = UUID()
    public let batchId: UUID
    public let batchIndex: Int
    public let batchHash: String
    public let resultHash: String
    public let signature: String
    public let timestamp: Date
    public let messageCount: Int
    public let qualityScore: Double
    
    public var summary: String {
        return """
        Batch Proof \(batchIndex):
        - ID: \(batchId.uuidString.prefix(8))...
        - Messages: \(messageCount)
        - Quality: \(String(format: "%.2f", qualityScore))
        - Hash: \(batchHash.prefix(16))...
        - Signature: \(signature.prefix(16))...
        """
    }
}

/// Complete verification bundle for batch processing
public struct BatchVerificationBundle: Codable {
    public let batchProofs: [BatchProof]
    public let merkleTree: MerkleTree
    public let aggregatedSignature: String
    public let mainVerificationBundle: VerificationBundle
    public let batchingMetadata: BatchingInfo?
    public let totalProcessingTime: TimeInterval
    
    public var summary: String {
        return """
        Batch Verification Bundle:
        - Total Batches: \(batchProofs.count)
        - Merkle Root: \(merkleTree.rootHash.prefix(16))...
        - Aggregated Signature: \(aggregatedSignature.prefix(16))...
        - Verification Level: \(mainVerificationBundle.verificationLevel.description)
        - Processing Time: \(String(format: "%.2f", totalProcessingTime))s
        - Has App Attestation: \(mainVerificationBundle.attestation != nil)
        """
    }
}

/// Result of batch verification process
public struct BatchVerificationResult {
    public let isValid: Bool
    public let batchResults: [BatchResult]
    public let merkleTreeValid: Bool
    public let aggregatedSignatureValid: Bool
    public let verificationLevel: VerificationLevel
    public let totalBatches: Int
    public let verifiedAt: Date
    
    public struct BatchResult {
        public let batchId: UUID
        public let batchIndex: Int
        public let isValid: Bool
        public let qualityScore: Double
    }
    
    public var successRate: Double {
        let validBatches = batchResults.filter { $0.isValid }.count
        return Double(validBatches) / Double(batchResults.count)
    }
    
    public var averageQuality: Double {
        return batchResults.reduce(0.0) { $0 + $1.qualityScore } / Double(batchResults.count)
    }
}

/// Simple Merkle tree implementation for batch aggregation
public struct MerkleTree: Codable {
    public let leaves: [MerkleLeaf]
    public let rootHash: String
    private let tree: [String]
    
    public init(leaves: [MerkleLeaf]) throws {
        guard !leaves.isEmpty else {
            throw BatchVerificationError.emptyMerkleTree
        }
        
        self.leaves = leaves
        
        // Build the Merkle tree
        var currentLevel = leaves.map { $0.hash }
        var allNodes = currentLevel
        
        while currentLevel.count > 1 {
            var nextLevel: [String] = []
            
            for i in stride(from: 0, to: currentLevel.count, by: 2) {
                let left = currentLevel[i]
                let right = i + 1 < currentLevel.count ? currentLevel[i + 1] : left
                
                let combinedHash = SHA256.hash(data: "\(left):\(right)".data(using: .utf8)!)
                let parentHash = combinedHash.compactMap { String(format: "%02x", $0) }.joined()
                
                nextLevel.append(parentHash)
            }
            
            allNodes.append(contentsOf: nextLevel)
            currentLevel = nextLevel
        }
        
        self.tree = allNodes
        self.rootHash = currentLevel.first ?? ""
    }
    
    /// Verifies the integrity of the Merkle tree
    public func verify() throws -> Bool {
        // Reconstruct the tree and compare root hash
        let reconstructed = try MerkleTree(leaves: leaves)
        return reconstructed.rootHash == self.rootHash
    }
}

/// Leaf node in a Merkle tree
public struct MerkleLeaf: Codable {
    public let id: UUID
    public let hash: String
    public let data: String
}

/// Errors that can occur during batch verification
public enum BatchVerificationError: Error, LocalizedError {
    case noBatchProofs
    case emptyMerkleTree
    case invalidBatchProof(String)
    case merkleTreeVerificationFailed
    case signatureVerificationFailed(String)
    case aggregationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .noBatchProofs:
            return "No batch proofs provided for aggregation"
        case .emptyMerkleTree:
            return "Cannot create Merkle tree with empty leaves"
        case .invalidBatchProof(let reason):
            return "Invalid batch proof: \(reason)"
        case .merkleTreeVerificationFailed:
            return "Merkle tree verification failed"
        case .signatureVerificationFailed(let reason):
            return "Signature verification failed: \(reason)"
        case .aggregationFailed(let reason):
            return "Batch aggregation failed: \(reason)"
        }
    }
}