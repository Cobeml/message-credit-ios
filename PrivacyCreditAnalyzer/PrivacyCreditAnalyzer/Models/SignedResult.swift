import Foundation

/// Represents a cryptographically signed analysis result for verification
struct SignedResult: Codable, Identifiable, Equatable {
    let result: AnalysisResult
    let signature: String
    let publicKey: String
    let inputHash: String
    let modelHash: String
    
    var id: UUID {
        return result.id
    }
    
    init(result: AnalysisResult, signature: String, publicKey: String, inputHash: String, modelHash: String) {
        self.result = result
        self.signature = signature
        self.publicKey = publicKey
        self.inputHash = inputHash
        self.modelHash = modelHash
    }
    
    /// Validates that the signed result has all required fields
    func isValid() -> Bool {
        return result.isValid() &&
               !signature.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !publicKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !inputHash.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !modelHash.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Returns the timestamp from the underlying analysis result
    var timestamp: Date {
        return result.timestamp
    }
    
    /// Returns a summary including signature information
    func signedSummary() -> String {
        let baseSummary = result.summary()
        return """
        \(baseSummary)
        
        Cryptographic Verification:
        - Signature: \(signature.prefix(16))...
        - Public Key: \(publicKey.prefix(16))...
        - Input Hash: \(inputHash.prefix(16))...
        - Model Hash: \(modelHash.prefix(16))...
        """
    }
    
    /// Returns a dictionary representation for JSON serialization
    func toDictionary() -> [String: Any] {
        var dict = result.toDictionary()
        dict["signature"] = signature
        dict["publicKey"] = publicKey
        dict["inputHash"] = inputHash
        dict["modelHash"] = modelHash
        return dict
    }
    
    /// Creates a SignedResult from a dictionary
    static func fromDictionary(_ dict: [String: Any]) throws -> SignedResult {
        guard let signature = dict["signature"] as? String,
              let publicKey = dict["publicKey"] as? String,
              let inputHash = dict["inputHash"] as? String,
              let modelHash = dict["modelHash"] as? String else {
            throw SignedResultError.invalidDictionary
        }
        
        let result = try AnalysisResult.fromDictionary(dict)
        
        return SignedResult(
            result: result,
            signature: signature,
            publicKey: publicKey,
            inputHash: inputHash,
            modelHash: modelHash
        )
    }
    
    /// Returns JSON data representation
    func toJSONData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    /// Creates a SignedResult from JSON data
    static func fromJSONData(_ data: Data) throws -> SignedResult {
        return try JSONDecoder().decode(SignedResult.self, from: data)
    }
}

enum SignedResultError: Error, LocalizedError {
    case invalidDictionary
    case serializationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidDictionary:
            return "Invalid dictionary format for SignedResult"
        case .serializationFailed:
            return "Failed to serialize SignedResult"
        }
    }
}