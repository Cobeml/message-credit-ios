import Foundation
import CryptoKit
#if canImport(DeviceCheck)
import DeviceCheck
#endif

/// Manages Apple App Attest for device and app integrity verification
/// Requires iOS 14.0+ and App Attest entitlement
@available(iOS 14.0, *)
public class AppAttestationManager: ObservableObject {
    
    // MARK: - Configuration
    
    private struct Config {
        static let keyIdentifierKey = "com.privacycreditanalyzer.appattest.keyid"
        static let attestationKey = "com.privacycreditanalyzer.appattest.attestation"
        static let challengeTimeout: TimeInterval = 30.0
    }
    
    // MARK: - Properties
    
    @Published public var isSupported: Bool = false
    @Published public var isInitialized: Bool = false
    @Published public var lastError: AppAttestError?
    
    private var keyIdentifier: String?
    private var storedAttestation: Data?
    
    // MARK: - Initialization
    
    public init() {
        checkAppAttestSupport()
    }
    
    /// Initializes App Attest by generating or loading existing attestation
    public func initialize() async throws {
        guard isSupported else {
            throw AppAttestError.notSupported("App Attest not supported on this device")
        }
        
        do {
            // Try to load existing key identifier and attestation
            if let existingKeyId = loadStoredKeyIdentifier(),
               let existingAttestation = loadStoredAttestation() {
                self.keyIdentifier = existingKeyId
                self.storedAttestation = existingAttestation
                print("📱 App Attest: Loaded existing attestation")
            } else {
                // Generate new attestation
                try await generateNewAttestation()
                print("📱 App Attest: Generated new attestation")
            }
            
            await MainActor.run {
                isInitialized = true
            }
            
        } catch {
            let attestError = error as? AppAttestError ?? .initializationFailed(error.localizedDescription)
            await MainActor.run {
                self.lastError = attestError
                print("❌ App Attest initialization failed: \(attestError.localizedDescription)")
            }
            throw attestError
        }
    }
    
    // MARK: - App Attest Operations
    
    /// Generates a new App Attest attestation
    private func generateNewAttestation() async throws {
        #if canImport(DeviceCheck)
        // Generate a new key
        let keyId = try await DCAppAttestService.shared.generateKey()
        
        // Create attestation challenge
        let challenge = createAttestationChallenge()
        
        // Create attestation
        let attestation = try await DCAppAttestService.shared.attestKey(keyId, clientDataHash: challenge)
        
        // Store the key identifier and attestation
        storeKeyIdentifier(keyId)
        storeAttestation(attestation)
        
        self.keyIdentifier = keyId
        self.storedAttestation = attestation
        
        print("✅ Generated new App Attest key and attestation")
        #else
        throw AppAttestError.notSupported("DeviceCheck framework not available")
        #endif
    }
    
    /// Creates a challenge for attestation (should be unique per request)
    public func createAttestationChallenge() -> Data {
        // Create a unique challenge combining timestamp and random data
        let timestamp = Date().timeIntervalSince1970
        let randomData = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
        let challengeString = "\(timestamp):\(randomData.base64EncodedString())"
        
        return challengeString.data(using: .utf8) ?? Data()
    }
    
    /// Generates an attestation string for verification bundles
    public func generateAttestation() async throws -> String {
        guard isInitialized else {
            throw AppAttestError.notInitialized("App Attest not initialized")
        }
        
        guard let keyId = keyIdentifier else {
            throw AppAttestError.keyNotAvailable("App Attest key not available")
        }
        
        #if canImport(DeviceCheck)
        // Create a fresh challenge for this attestation
        let challenge = createAttestationChallenge()
        
        // Generate assertion (proof of possession)
        let clientDataHash = SHA256Hash.hash(data: challenge)
        let assertion = try await DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: Data(clientDataHash))
        
        // Combine attestation data and assertion into a verification string
        let attestationData: [String: Any] = [
            "keyId": keyId,
            "challenge": challenge.base64EncodedString(),
            "assertion": assertion.base64EncodedString(),
            "timestamp": Date().timeIntervalSince1970,
            "version": "1.0"
        ]
        
        // Serialize to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: attestationData)
        return jsonData.base64EncodedString()
        
        #else
        throw AppAttestError.notSupported("DeviceCheck framework not available")
        #endif
    }
    
    /// Validates app integrity using App Attest
    public func validateAppIntegrity() async throws -> Bool {
        guard isSupported else {
            throw AppAttestError.notSupported("App Attest not supported")
        }
        
        guard isInitialized else {
            throw AppAttestError.notInitialized("App Attest not initialized")
        }
        
        #if canImport(DeviceCheck)
        // For client-side validation, we primarily check if the service is available
        // and our stored attestation exists. Full validation happens on the server.
        return DCAppAttestService.shared.isSupported &&
               keyIdentifier != nil &&
               storedAttestation != nil
        #else
        return false
        #endif
    }
    
    // MARK: - Support Detection
    
    private func checkAppAttestSupport() {
        #if canImport(DeviceCheck)
        if #available(iOS 14.0, *) {
            isSupported = DCAppAttestService.shared.isSupported
        } else {
            isSupported = false
        }
        #else
        isSupported = false
        #endif
        
        print("📱 App Attest support: \(isSupported)")
    }
    
    // MARK: - Storage Operations
    
    private func storeKeyIdentifier(_ keyId: String) {
        UserDefaults.standard.set(keyId, forKey: Config.keyIdentifierKey)
    }
    
    private func loadStoredKeyIdentifier() -> String? {
        return UserDefaults.standard.string(forKey: Config.keyIdentifierKey)
    }
    
    private func storeAttestation(_ attestation: Data) {
        UserDefaults.standard.set(attestation, forKey: Config.attestationKey)
    }
    
    private func loadStoredAttestation() -> Data? {
        return UserDefaults.standard.data(forKey: Config.attestationKey)
    }
    
    // MARK: - Utility Methods
    
    /// Returns diagnostic information about App Attest status
    public func diagnosticInfo() -> [String: Any] {
        return [
            "isSupported": isSupported,
            "isInitialized": isInitialized,
            "hasKeyIdentifier": keyIdentifier != nil,
            "hasStoredAttestation": storedAttestation != nil,
            "lastError": lastError?.localizedDescription ?? "none",
            "iOSVersion": ProcessInfo.processInfo.operatingSystemVersionString
        ]
    }
    
    /// Resets App Attest state (useful for testing or recovery)
    public func reset() async {
        UserDefaults.standard.removeObject(forKey: Config.keyIdentifierKey)
        UserDefaults.standard.removeObject(forKey: Config.attestationKey)
        
        await MainActor.run {
            keyIdentifier = nil
            storedAttestation = nil
            isInitialized = false
            lastError = nil
        }
        
        print("🔄 App Attest state reset")
    }
}

// MARK: - Supporting Types

/// Errors that can occur during App Attest operations
public enum AppAttestError: Error, LocalizedError {
    case notSupported(String)
    case notInitialized(String)
    case initializationFailed(String)
    case keyGenerationFailed(String)
    case keyNotAvailable(String)
    case attestationFailed(String)
    case assertionFailed(String)
    case validationFailed(String)
    case storageError(String)
    
    public var errorDescription: String? {
        switch self {
        case .notSupported(let reason):
            return "App Attest not supported: \(reason)"
        case .notInitialized(let reason):
            return "App Attest not initialized: \(reason)"
        case .initializationFailed(let reason):
            return "App Attest initialization failed: \(reason)"
        case .keyGenerationFailed(let reason):
            return "App Attest key generation failed: \(reason)"
        case .keyNotAvailable(let reason):
            return "App Attest key not available: \(reason)"
        case .attestationFailed(let reason):
            return "App attestation failed: \(reason)"
        case .assertionFailed(let reason):
            return "App assertion failed: \(reason)"
        case .validationFailed(let reason):
            return "App validation failed: \(reason)"
        case .storageError(let reason):
            return "App Attest storage error: \(reason)"
        }
    }
}

// MARK: - SHA256Hash Utility

/// Utility for creating SHA256 hashes compatible with App Attest
private struct SHA256Hash {
    static func hash(data: Data) -> [UInt8] {
        let digest = SHA256.hash(data: data)
        return Array(digest)
    }
}

// MARK: - Mock Implementation for Unsupported Platforms

/// Mock App Attest manager for platforms that don't support DeviceCheck
public class MockAppAttestationManager: ObservableObject {
    @Published public var isSupported: Bool = false
    @Published public var isInitialized: Bool = false
    @Published public var lastError: AppAttestError? = nil
    
    public init() {
        print("📱 Using Mock App Attestation Manager (DeviceCheck not available)")
    }
    
    public func initialize() async throws {
        await MainActor.run {
            isInitialized = true
        }
    }
    
    public func generateAttestation() async throws -> String {
        // Return a mock attestation for development purposes
        let mockAttestation: [String: Any] = [
            "keyId": "mock_key_id",
            "challenge": "mock_challenge",
            "assertion": "mock_assertion",
            "timestamp": Date().timeIntervalSince1970,
            "version": "1.0-mock"
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: mockAttestation)
        return jsonData.base64EncodedString()
    }
    
    public func validateAppIntegrity() async throws -> Bool {
        return true // Always valid in mock mode
    }
    
    public func diagnosticInfo() -> [String: Any] {
        return [
            "isSupported": false,
            "isInitialized": isInitialized,
            "mode": "mock",
            "reason": "DeviceCheck framework not available"
        ]
    }
    
    public func reset() async {
        await MainActor.run {
            isInitialized = false
            lastError = nil
        }
    }
}