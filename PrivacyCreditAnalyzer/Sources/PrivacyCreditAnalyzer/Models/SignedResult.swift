import Foundation

/// Represents a cryptographically signed and verified analysis result with comprehensive proof bundle
public struct SignedResult: Codable, Identifiable, Equatable {
    public let result: AnalysisResult
    public let verificationBundle: VerificationBundle
    
    // Implement Equatable conformance
    public static func == (lhs: SignedResult, rhs: SignedResult) -> Bool {
        return lhs.result.id == rhs.result.id &&
               lhs.verificationBundle.signature == rhs.verificationBundle.signature &&
               lhs.verificationBundle.publicKey == rhs.verificationBundle.publicKey &&
               lhs.verificationBundle.inputHash == rhs.verificationBundle.inputHash &&
               lhs.verificationBundle.resultHash == rhs.verificationBundle.resultHash
    }
    
    // Legacy fields for backward compatibility
    public var signature: String { verificationBundle.signature }
    public var publicKey: String { verificationBundle.publicKey }
    public var inputHash: String { verificationBundle.inputHash }
    public var modelHash: String { verificationBundle.modelHash }
    
    public var id: UUID {
        return result.id
    }
    
    public init(result: AnalysisResult, verificationBundle: VerificationBundle) {
        self.result = result
        self.verificationBundle = verificationBundle
    }
    
    // Legacy initializer for backward compatibility
    public init(result: AnalysisResult, signature: String, publicKey: String, inputHash: String, modelHash: String) {
        self.result = result
        self.verificationBundle = VerificationBundle(
            signature: signature,
            publicKey: publicKey,
            inputHash: inputHash,
            resultHash: "", // Empty for legacy compatibility
            modelHash: modelHash,
            timestamp: result.timestamp,
            attestation: nil,
            verificationLevel: .basic
        )
    }
    
    /// Validates that the signed result has all required fields
    public func isValid() -> Bool {
        return result.isValid() && verificationBundle.isValid()
    }
    
    /// Returns the timestamp from the underlying analysis result
    public var timestamp: Date {
        return result.timestamp
    }
    
    /// Returns a comprehensive summary including verification information
    public func signedSummary() -> String {
        let baseSummary = result.summary()
        return """
        \(baseSummary)
        
        \(verificationBundle.summary())
        """
    }
    
    /// Returns verification level information
    public var verificationLevel: VerificationLevel {
        return verificationBundle.verificationLevel
    }
    
    /// Checks if the result includes App Attest verification
    public var hasAppAttestation: Bool {
        return verificationBundle.attestation != nil
    }
    
    /// Returns a dictionary representation for JSON serialization
    public func toDictionary() -> [String: Any] {
        var dict = result.toDictionary()
        
        // Add verification bundle data
        dict["signature"] = verificationBundle.signature
        dict["publicKey"] = verificationBundle.publicKey
        dict["inputHash"] = verificationBundle.inputHash
        dict["resultHash"] = verificationBundle.resultHash
        dict["modelHash"] = verificationBundle.modelHash
        dict["verificationTimestamp"] = verificationBundle.timestamp.timeIntervalSince1970
        dict["attestation"] = verificationBundle.attestation
        dict["verificationLevel"] = verificationBundle.verificationLevel.rawValue
        
        return dict
    }
    
    /// Creates a SignedResult from a dictionary
    public static func fromDictionary(_ dict: [String: Any]) throws -> SignedResult {
        guard let signature = dict["signature"] as? String,
              let publicKey = dict["publicKey"] as? String,
              let inputHash = dict["inputHash"] as? String,
              let modelHash = dict["modelHash"] as? String else {
            throw SignedResultError.invalidDictionary
        }
        
        let result = try AnalysisResult.fromDictionary(dict)
        
        // Try to construct full verification bundle if data is available
        let resultHash = dict["resultHash"] as? String ?? ""
        let verificationTimestamp = (dict["verificationTimestamp"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) } ?? result.timestamp
        let attestation = dict["attestation"] as? String
        let verificationLevelString = dict["verificationLevel"] as? String ?? "basic"
        let verificationLevel = VerificationLevel(rawValue: verificationLevelString) ?? .basic
        
        let verificationBundle = VerificationBundle(
            signature: signature,
            publicKey: publicKey,
            inputHash: inputHash,
            resultHash: resultHash,
            modelHash: modelHash,
            timestamp: verificationTimestamp,
            attestation: attestation,
            verificationLevel: verificationLevel
        )
        
        return SignedResult(result: result, verificationBundle: verificationBundle)
    }
    
    /// Returns JSON data representation
    public func toJSONData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    /// Creates a SignedResult from JSON data
    public static func fromJSONData(_ data: Data) throws -> SignedResult {
        return try JSONDecoder().decode(SignedResult.self, from: data)
    }
}

public enum SignedResultError: Error, LocalizedError {
    case invalidDictionary
    case serializationFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidDictionary:
            return "Invalid dictionary format for SignedResult"
        case .serializationFailed:
            return "Failed to serialize SignedResult"
        }
    }
}