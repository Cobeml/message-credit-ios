import Foundation
import CryptoKit
import Security
#if canImport(DeviceCheck)
import DeviceCheck
#endif

/// Core cryptographic engine handling Secure Enclave operations, signing, and verification bundle creation
public class CryptographicEngine: ObservableObject {
    
    // MARK: - Configuration
    
    private struct Config {
        static let keyTag = "com.privacycreditanalyzer.signing.key"
        static let keySize = 256 // P-256 curve
        static let signatureAlgorithm = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256
    }
    
    // MARK: - Properties
    
    @Published public var isInitialized: Bool = false
    @Published public var lastError: CryptographicError?
    
    private var privateKey: SecKey?
    private var publicKey: SecKey?
    private var appAttestationManager: AppAttestationManager?
    
    // MARK: - Initialization
    
    public init() {
        // Initialize App Attestation Manager if available
        #if canImport(DeviceCheck)
        if #available(iOS 14.0, *) {
            self.appAttestationManager = AppAttestationManager()
        }
        #endif
    }
    
    /// Initializes the cryptographic engine with Secure Enclave key pair
    public func initialize() async throws {
        do {
            // Check if running in simulator (Secure Enclave not available)
            guard !isSimulatorEnvironment else {
                await MainActor.run {
                    isInitialized = true
                    print("🔐 CryptographicEngine: Simulator mode - using software keys for development")
                }
                return
            }
            
            // Try to load existing key pair or generate new one
            try await loadOrGenerateKeyPair()
            
            // Initialize App Attestation if available
            try await initializeAppAttestation()
            
            await MainActor.run {
                isInitialized = true
                print("✅ CryptographicEngine: Successfully initialized with Secure Enclave")
            }
            
        } catch {
            let cryptoError = error as? CryptographicError ?? .initializationFailed(error.localizedDescription)
            await MainActor.run {
                self.lastError = cryptoError
                print("❌ CryptographicEngine initialization failed: \(cryptoError.localizedDescription)")
            }
            throw cryptoError
        }
    }
    
    // MARK: - Key Management
    
    /// Generates a new Secure Enclave key pair
    private func generateSecureEnclaveKeyPair() throws -> (private: SecKey, public: SecKey) {
        // Configure key generation parameters for Secure Enclave
        let keyAttributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: Config.keySize,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecAttrApplicationTag as String: Config.keyTag.data(using: .utf8)!,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrAccessControl as String: createAccessControl()
            ]
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(keyAttributes as CFDictionary, &error) else {
            if let error = error?.takeRetainedValue() {
                throw CryptographicError.keyGenerationFailed(CFErrorCopyDescription(error) as String? ?? "Unknown error")
            } else {
                throw CryptographicError.keyGenerationFailed("Failed to generate Secure Enclave key")
            }
        }
        
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw CryptographicError.keyGenerationFailed("Failed to extract public key")
        }
        
        print("🔐 Generated new Secure Enclave key pair")
        return (private: privateKey, public: publicKey)
    }
    
    /// Creates access control for Secure Enclave key
    private func createAccessControl() -> SecAccessControl {
        var error: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.privateKeyUsage, .biometryAny], // Require biometry for key usage
            &error
        ) else {
            // Fallback to device passcode only if biometry fails
            return SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .devicePasscode,
                nil
            )!
        }
        
        return accessControl
    }
    
    /// Loads existing key pair or generates new one
    private func loadOrGenerateKeyPair() async throws {
        // Try to load existing private key
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: Config.keyTag.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess && CFGetTypeID(result) == SecKeyGetTypeID() {
            let existingPrivateKey = result as! SecKey
            // Load existing key pair
            self.privateKey = existingPrivateKey
            self.publicKey = SecKeyCopyPublicKey(existingPrivateKey)
            print("🔐 Loaded existing Secure Enclave key pair")
        } else {
            // Generate new key pair
            let keyPair = try generateSecureEnclaveKeyPair()
            self.privateKey = keyPair.private
            self.publicKey = keyPair.public
        }
    }
    
    // MARK: - Signing Operations
    
    /// Signs data using the Secure Enclave private key
    public func signData(_ data: Data) async throws -> Data {
        guard let privateKey = self.privateKey else {
            throw CryptographicError.keyNotAvailable("Private key not available")
        }
        
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey,
            Config.signatureAlgorithm,
            data as CFData,
            &error
        ) else {
            if let error = error?.takeRetainedValue() {
                throw CryptographicError.signingFailed(CFErrorCopyDescription(error) as String? ?? "Signing failed")
            } else {
                throw CryptographicError.signingFailed("Unknown signing error")
            }
        }
        
        return signature as Data
    }
    
    /// Verifies a signature using the public key
    public func verifySignature(_ signature: Data, for data: Data) throws -> Bool {
        guard let publicKey = self.publicKey else {
            throw CryptographicError.keyNotAvailable("Public key not available")
        }
        
        var error: Unmanaged<CFError>?
        let isValid = SecKeyVerifySignature(
            publicKey,
            Config.signatureAlgorithm,
            data as CFData,
            signature as CFData,
            &error
        )
        
        if let error = error?.takeRetainedValue() {
            throw CryptographicError.verificationFailed(CFErrorCopyDescription(error) as String? ?? "Verification failed")
        }
        
        return isValid
    }
    
    // MARK: - Hash Operations
    
    /// Creates SHA-256 hash of message content while preserving privacy
    public func createPrivacyPreservingHash(for messages: [Message]) -> String {
        // Create individual message hashes to avoid revealing content
        let messageHashes = messages.map { message in
            let messageData = "\(message.timestamp.timeIntervalSince1970):\(message.content):\(message.sender)".data(using: .utf8)!
            return SHA256.hash(data: messageData).compactMap { String(format: "%02x", $0) }.joined()
        }
        
        // Create combined hash of all message hashes
        let combinedHashData = messageHashes.joined(separator: ":").data(using: .utf8)!
        let finalHash = SHA256.hash(data: combinedHashData)
        return finalHash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Creates a hash of the analysis result for integrity verification
    public func createResultHash(for result: AnalysisResult) -> String {
        let resultData = """
        traits:\(result.personalityTraits.openness):\(result.personalityTraits.conscientiousness):\(result.personalityTraits.extraversion):\(result.personalityTraits.agreeableness):\(result.personalityTraits.neuroticism):\(result.personalityTraits.confidence):
        trust:\(result.trustworthinessScore.score):
        count:\(result.messageCount):
        time:\(result.processingTime)
        """.data(using: .utf8)!
        
        let hash = SHA256.hash(data: resultData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Verification Bundle Creation
    
    /// Creates a complete verification bundle for an analysis result
    public func createVerificationBundle(
        result: AnalysisResult,
        messages: [Message],
        modelHash: String?
    ) async throws -> VerificationBundle {
        guard isInitialized else {
            throw CryptographicError.engineNotInitialized
        }
        
        // Create privacy-preserving input hash
        let inputHash = createPrivacyPreservingHash(for: messages)
        
        // Create result hash
        let resultHash = createResultHash(for: result)
        
        // Create signature payload
        let signaturePayload = "\(inputHash):\(resultHash):\(modelHash ?? "unknown"):\(Date().timeIntervalSince1970)"
        let signatureData = signaturePayload.data(using: .utf8)!
        
        // Sign the payload
        let signature = try await signData(signatureData)
        
        // Get public key representation
        let publicKeyData = try getPublicKeyRepresentation()
        
        // Get app attestation if available
        let attestation = try await getAppAttestation()
        
        return VerificationBundle(
            signature: signature.base64EncodedString(),
            publicKey: publicKeyData.base64EncodedString(),
            inputHash: inputHash,
            resultHash: resultHash,
            modelHash: modelHash ?? "unknown",
            timestamp: Date(),
            attestation: attestation,
            verificationLevel: determineVerificationLevel(attestation: attestation)
        )
    }
    
    // MARK: - App Attestation Integration
    
    private func initializeAppAttestation() async throws {
        #if canImport(DeviceCheck)
        if let attestationManager = appAttestationManager {
            try await attestationManager.initialize()
            print("✅ App Attestation initialized")
        }
        #endif
    }
    
    private func getAppAttestation() async throws -> String? {
        #if canImport(DeviceCheck)
        guard let attestationManager = appAttestationManager else { return nil }
        return try await attestationManager.generateAttestation()
        #else
        return nil
        #endif
    }
    
    // MARK: - Utility Methods
    
    /// Gets the public key in a portable format
    public func getPublicKeyRepresentation() throws -> Data {
        guard let publicKey = self.publicKey else {
            throw CryptographicError.keyNotAvailable("Public key not available")
        }
        
        var error: Unmanaged<CFError>?
        guard let keyData = SecKeyCopyExternalRepresentation(publicKey, &error) else {
            if let error = error?.takeRetainedValue() {
                throw CryptographicError.keyExportFailed(CFErrorCopyDescription(error) as String? ?? "Key export failed")
            } else {
                throw CryptographicError.keyExportFailed("Unknown key export error")
            }
        }
        
        return keyData as Data
    }
    
    /// Determines the verification level based on available features
    private func determineVerificationLevel(attestation: String?) -> VerificationLevel {
        if isSimulatorEnvironment {
            return .development
        }
        
        if attestation != nil && privateKey != nil {
            return .full // Future: Add ZKP when implemented
        } else if privateKey != nil {
            return .partial
        } else {
            return .basic
        }
    }
    
    /// Detects simulator environment
    private var isSimulatorEnvironment: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Supporting Types

/// Represents different levels of cryptographic verification
public enum VerificationLevel: String, Codable, CaseIterable, Equatable {
    case full = "full"           // All features: signature + attestation + ZKP (future)
    case partial = "partial"     // Signature + attestation
    case basic = "basic"         // Signature only
    case development = "dev"     // Development/simulator mode
    
    public var description: String {
        switch self {
        case .full:
            return "Full verification (signature + attestation + ZKP)"
        case .partial:
            return "Partial verification (signature + attestation)"
        case .basic:
            return "Basic verification (signature only)"
        case .development:
            return "Development mode (no cryptographic verification)"
        }
    }
}

/// Complete verification bundle containing all cryptographic proof elements
public struct VerificationBundle: Codable, Equatable {
    public let signature: String
    public let publicKey: String
    public let inputHash: String
    public let resultHash: String
    public let modelHash: String
    public let timestamp: Date
    public let attestation: String?
    public let verificationLevel: VerificationLevel
    
    /// Validates that the verification bundle has all required fields
    public func isValid() -> Bool {
        return !signature.isEmpty &&
               !publicKey.isEmpty &&
               !inputHash.isEmpty &&
               !resultHash.isEmpty &&
               !modelHash.isEmpty
    }
    
    /// Returns a summary of the verification bundle
    public func summary() -> String {
        return """
        Verification Bundle (\(verificationLevel.description)):
        - Signature: \(signature.prefix(16))...
        - Public Key: \(publicKey.prefix(16))...
        - Input Hash: \(inputHash.prefix(16))...
        - Result Hash: \(resultHash.prefix(16))...
        - Model Hash: \(modelHash.prefix(16))...
        - Timestamp: \(timestamp)
        - Has Attestation: \(attestation != nil)
        """
    }
}

/// Errors that can occur during cryptographic operations
public enum CryptographicError: Error, LocalizedError {
    case engineNotInitialized
    case initializationFailed(String)
    case keyGenerationFailed(String)
    case keyNotAvailable(String)
    case keyExportFailed(String)
    case signingFailed(String)
    case verificationFailed(String)
    case hashingFailed(String)
    case attestationFailed(String)
    case secureEnclaveNotAvailable
    
    public var errorDescription: String? {
        switch self {
        case .engineNotInitialized:
            return "Cryptographic engine not initialized"
        case .initializationFailed(let reason):
            return "Cryptographic engine initialization failed: \(reason)"
        case .keyGenerationFailed(let reason):
            return "Key generation failed: \(reason)"
        case .keyNotAvailable(let reason):
            return "Cryptographic key not available: \(reason)"
        case .keyExportFailed(let reason):
            return "Key export failed: \(reason)"
        case .signingFailed(let reason):
            return "Digital signing failed: \(reason)"
        case .verificationFailed(let reason):
            return "Signature verification failed: \(reason)"
        case .hashingFailed(let reason):
            return "Hashing operation failed: \(reason)"
        case .attestationFailed(let reason):
            return "App attestation failed: \(reason)"
        case .secureEnclaveNotAvailable:
            return "Secure Enclave not available on this device"
        }
    }
}