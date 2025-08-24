import Foundation
import Security
#if canImport(UIKit)
import UIKit
#endif
#if canImport(DeviceCheck)
import DeviceCheck
#endif
#if canImport(MachO)
import MachO
#endif

/// Security validation and jailbreak detection for cryptographic verification integrity
public class SecurityValidator: ObservableObject {
    
    // MARK: - Security Levels
    
    public enum SecurityLevel: String, CaseIterable {
        case secure = "secure"         // All security checks pass
        case compromised = "compromised" // Device may be jailbroken/compromised
        case suspicious = "suspicious"  // Some security indicators fail
        case unknown = "unknown"       // Unable to determine security status
        
        public var description: String {
            switch self {
            case .secure:
                return "Device security is intact"
            case .compromised:
                return "Device appears to be compromised"
            case .suspicious:
                return "Device security is questionable"
            case .unknown:
                return "Security status cannot be determined"
            }
        }
    }
    
    // MARK: - Properties
    
    @Published public var currentSecurityLevel: SecurityLevel = .unknown
    @Published public var securityChecks: [SecurityCheck] = []
    @Published public var lastValidationDate: Date?
    
    private let validationCache = NSCache<NSString, SecurityValidationResult>()
    
    // MARK: - Public Interface
    
    /// Performs comprehensive security validation
    public func validateDeviceSecurity() async -> SecurityValidationResult {
        let cacheKey = "device_security_\(Date().timeIntervalSince1970 / 3600)" // Cache for 1 hour
        
        if let cached = validationCache.object(forKey: cacheKey as NSString) {
            await updateSecurityStatus(cached)
            return cached
        }
        
        let startTime = Date()
        var checks: [SecurityCheck] = []
        
        // Perform all security checks
        checks.append(await checkJailbreakIndicators())
        checks.append(await checkAppIntegrity())
        checks.append(await checkDebuggingDetection())
        checks.append(await checkSecureEnclaveAvailability())
        checks.append(await checkAppAttestSupport())
        checks.append(await checkCodeSigningIntegrity())
        checks.append(await checkRuntimeManipulation())
        checks.append(await checkSuspiciousApps())
        
        let validationTime = Date().timeIntervalSince(startTime)
        
        // Determine overall security level
        let securityLevel = determineSecurityLevel(from: checks)
        
        let result = SecurityValidationResult(
            securityLevel: securityLevel,
            checks: checks,
            validationTime: validationTime,
            validatedAt: Date(),
            deviceInfo: collectDeviceInfo()
        )
        
        // Cache result
        validationCache.setObject(result, forKey: cacheKey as NSString)
        
        await updateSecurityStatus(result)
        return result
    }
    
    /// Quick security check for runtime validation
    public func quickSecurityCheck() -> Bool {
        // Basic jailbreak detection that runs quickly
        return !isJailbrokenBasic()
    }
    
    /// Validates a cryptographic verification bundle against security requirements
    public func validateVerificationBundle(_ bundle: VerificationBundle) -> SecurityValidationResult.BundleValidation {
        var issues: [String] = []
        var warnings: [String] = []
        
        // Check if device is compromised
        if currentSecurityLevel == .compromised {
            issues.append("Device security is compromised - verification bundle may be unreliable")
        }
        
        // Validate signature format
        if bundle.signature.isEmpty {
            issues.append("Empty signature in verification bundle")
        }
        
        // Validate public key format
        if bundle.publicKey.isEmpty {
            issues.append("Empty public key in verification bundle")
        }
        
        // Check verification level appropriateness
        if currentSecurityLevel == .compromised && bundle.verificationLevel == .full {
            warnings.append("Full verification level claimed on compromised device")
        }
        
        // Check attestation presence on supported devices
        if bundle.attestation == nil && isAppAttestSupported() {
            warnings.append("App attestation missing on supported device")
        }
        
        let isValid = issues.isEmpty && (currentSecurityLevel == .secure || currentSecurityLevel == .suspicious)
        
        return SecurityValidationResult.BundleValidation(
            isValid: isValid,
            issues: issues,
            warnings: warnings,
            recommendedAction: isValid ? .accept : .reject
        )
    }
    
    // MARK: - Individual Security Checks
    
    private func checkJailbreakIndicators() async -> SecurityCheck {
        var indicators: [String] = []
        var score = 1.0
        
        // Check for common jailbreak files and directories
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/Users/",
            "/private/var/root/",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                indicators.append("Detected jailbreak file: \(path)")
                score -= 0.2
            }
        }
        
        // Check for ability to write outside sandbox
        let testPath = "/private/test_write"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            indicators.append("Can write outside sandbox")
            score -= 0.3
        } catch {
            // Normal behavior - unable to write outside sandbox
        }
        
        // Check for suspicious URL schemes
        #if canImport(UIKit)
        let suspiciousSchemes = ["cydia://", "sileo://", "zbra://"]
        for scheme in suspiciousSchemes {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                indicators.append("Can open jailbreak URL scheme: \(scheme)")
                score -= 0.15
            }
        }
        #endif
        
        // Skip fork check as it's not available in modern iOS
        // This check is commented out for iOS compatibility
        
        let status: SecurityCheck.Status = score > 0.7 ? .pass : (score > 0.3 ? .warning : .fail)
        
        return SecurityCheck(
            name: "Jailbreak Detection",
            status: status,
            score: max(0.0, score),
            details: indicators.isEmpty ? ["No jailbreak indicators detected"] : indicators,
            impact: .critical
        )
    }
    
    private func checkAppIntegrity() async -> SecurityCheck {
        var details: [String] = []
        var score = 1.0
        
        // Check app bundle integrity
        guard !Bundle.main.bundlePath.isEmpty else {
            return SecurityCheck(
                name: "App Integrity",
                status: .fail,
                score: 0.0,
                details: ["Cannot determine app bundle path"],
                impact: .high
            )
        }
        
        // Check if Info.plist has been modified
        let infoPlistPath = Bundle.main.path(forResource: "Info", ofType: "plist")
        if let plistPath = infoPlistPath {
            let attributes = try? FileManager.default.attributesOfItem(atPath: plistPath)
            if let modDate = attributes?[.modificationDate] as? Date {
                // Check if modification date is suspiciously recent
                let timeSinceModification = Date().timeIntervalSince(modDate)
                if timeSinceModification < 86400 { // Less than 24 hours
                    details.append("Info.plist recently modified")
                    score -= 0.2
                }
            }
        }
        
        // Check for debugging indicators
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        
        let result = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        if result == 0 && (info.kp_proc.p_flag & P_TRACED) != 0 {
            details.append("Process is being traced/debugged")
            score -= 0.5
        }
        
        let status: SecurityCheck.Status = score > 0.8 ? .pass : (score > 0.5 ? .warning : .fail)
        
        return SecurityCheck(
            name: "App Integrity",
            status: status,
            score: score,
            details: details.isEmpty ? ["App integrity checks passed"] : details,
            impact: .high
        )
    }
    
    private func checkDebuggingDetection() async -> SecurityCheck {
        var details: [String] = []
        var score = 1.0
        
        // Check if debugger is attached
        if isDebuggerAttached() {
            details.append("Debugger detected")
            score -= 0.8
        }
        
        // Check for dynamic library injection
        #if canImport(MachO) && os(iOS)
        let dyldImageCount = _dyld_image_count()
        var suspiciousLibraries = 0
        
        for i in 0..<dyldImageCount {
            if let imageName = _dyld_get_image_name(i) {
                let name = String(cString: imageName).lowercased()
                if name.contains("frida") || name.contains("cycript") || name.contains("substrate") {
                    details.append("Suspicious dynamic library: \(name)")
                    suspiciousLibraries += 1
                    score -= 0.3
                }
            }
        }
        #else
        // Dynamic library checking not available on this platform
        details.append("Dynamic library checking not available")
        #endif
        
        let status: SecurityCheck.Status = score > 0.7 ? .pass : (score > 0.3 ? .warning : .fail)
        
        return SecurityCheck(
            name: "Debugging Detection",
            status: status,
            score: max(0.0, score),
            details: details.isEmpty ? ["No debugging activity detected"] : details,
            impact: .medium
        )
    }
    
    private func checkSecureEnclaveAvailability() async -> SecurityCheck {
        // Check if device supports hardware security features
        #if os(iOS) && !targetEnvironment(simulator)
        let hasSecureEnclave = true
        #else
        let hasSecureEnclave = false
        #endif
        
        return SecurityCheck(
            name: "Secure Enclave",
            status: hasSecureEnclave ? .pass : .warning,
            score: hasSecureEnclave ? 1.0 : 0.5,
            details: [hasSecureEnclave ? "Hardware security features available" : "Running in simulator or unsupported platform"],
            impact: .high
        )
    }
    
    private func checkAppAttestSupport() async -> SecurityCheck {
        #if canImport(DeviceCheck)
        if #available(iOS 14.0, *) {
            let isSupported = DCAppAttestService.shared.isSupported
            return SecurityCheck(
                name: "App Attest",
                status: isSupported ? .pass : .warning,
                score: isSupported ? 1.0 : 0.7,
                details: [isSupported ? "App Attest supported" : "App Attest not supported"],
                impact: .medium
            )
        }
        #endif
        
        return SecurityCheck(
            name: "App Attest",
            status: .warning,
            score: 0.5,
            details: ["App Attest not available on this platform/version"],
            impact: .medium
        )
    }
    
    private func checkCodeSigningIntegrity() async -> SecurityCheck {
        var details: [String] = []
        var score = 1.0
        
        // Basic bundle integrity checks without SecCode APIs
        let bundle = Bundle.main
        
        // Check if bundle exists and has expected structure
        if let bundlePath = bundle.bundlePath as String?, !bundlePath.isEmpty {
            details.append("App bundle path is valid")
            
            // Check if Info.plist exists
            if bundle.infoDictionary != nil {
                details.append("Info.plist is accessible")
            } else {
                details.append("Info.plist is missing or corrupted")
                score -= 0.3
            }
            
            // Check if bundle identifier exists
            if let bundleId = bundle.bundleIdentifier, !bundleId.isEmpty {
                details.append("Bundle identifier: \(bundleId)")
            } else {
                details.append("Bundle identifier is missing")
                score -= 0.2
            }
            
            // Check if executable exists
            if let executablePath = bundle.executablePath, FileManager.default.fileExists(atPath: executablePath) {
                details.append("Executable file is present")
            } else {
                details.append("Executable file is missing")
                score -= 0.4
            }
        } else {
            details.append("Bundle path is invalid")
            score -= 0.5
        }
        
        let checkStatus: SecurityCheck.Status = score > 0.8 ? .pass : (score > 0.5 ? .warning : .fail)
        
        return SecurityCheck(
            name: "App Integrity",
            status: checkStatus,
            score: score,
            details: details,
            impact: .high
        )
    }
    
    private func checkRuntimeManipulation() async -> SecurityCheck {
        var details: [String] = []
        var score = 1.0
        
        // Check for common runtime manipulation indicators
        
        // Method swizzling detection
        let originalMethod = class_getInstanceMethod(NSString.self, #selector(getter: NSString.length))
        let swizzledMethod = class_getInstanceMethod(NSString.self, #selector(getter: NSString.hash))
        
        if originalMethod == nil || swizzledMethod == nil {
            details.append("Suspicious method resolution")
            score -= 0.3
        }
        
        // Check for unusual memory layout
        let testString = "SecurityTest"
        let stringAddress = Unmanaged.passUnretained(testString as NSString).toOpaque()
        let expectedRange = 0x100000000...0x200000000 // Typical iOS app memory range
        
        if !expectedRange.contains(Int(bitPattern: stringAddress)) {
            details.append("Unusual memory layout detected")
            score -= 0.2
        }
        
        let status: SecurityCheck.Status = score > 0.8 ? .pass : (score > 0.5 ? .warning : .fail)
        
        return SecurityCheck(
            name: "Runtime Manipulation",
            status: status,
            score: score,
            details: details.isEmpty ? ["No runtime manipulation detected"] : details,
            impact: .medium
        )
    }
    
    private func checkSuspiciousApps() async -> SecurityCheck {
        var details: [String] = []
        var score = 1.0
        
        // Check for suspicious URL schemes that might indicate jailbreak apps
        let suspiciousSchemes = [
            "cydia://", "sileo://", "zbra://", "installer://",
            "activator://", "barrel://", "springtomize://",
            "undecimus://", "checkra1n://", "taurine://"
        ]
        
        var detectedSchemes = 0
        #if canImport(UIKit)
        for scheme in suspiciousSchemes {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                detectedSchemes += 1
                score -= 0.1
            }
        }
        #endif
        
        if detectedSchemes > 0 {
            details.append("Detected \(detectedSchemes) suspicious app URL schemes")
        } else {
            details.append("No suspicious apps detected")
        }
        
        let status: SecurityCheck.Status = score > 0.9 ? .pass : (score > 0.7 ? .warning : .fail)
        
        return SecurityCheck(
            name: "Suspicious Apps",
            status: status,
            score: max(0.0, score),
            details: details,
            impact: .low
        )
    }
    
    // MARK: - Helper Methods
    
    private func isJailbrokenBasic() -> Bool {
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/usr/sbin/sshd",
            "/bin/bash",
            "/etc/apt"
        ]
        
        return jailbreakPaths.contains { FileManager.default.fileExists(atPath: $0) }
    }
    
    private func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        
        let result = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        return result == 0 && (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    private func isAppAttestSupported() -> Bool {
        #if canImport(DeviceCheck)
        if #available(iOS 14.0, *) {
            return DCAppAttestService.shared.isSupported
        }
        #endif
        return false
    }
    
    private func determineSecurityLevel(from checks: [SecurityCheck]) -> SecurityLevel {
        let criticalFails = checks.filter { $0.impact == .critical && $0.status == .fail }.count
        let highFails = checks.filter { $0.impact == .high && $0.status == .fail }.count
        let totalWarnings = checks.filter { $0.status == .warning }.count
        
        if criticalFails > 0 {
            return .compromised
        } else if highFails > 1 {
            return .compromised
        } else if highFails > 0 || totalWarnings > 3 {
            return .suspicious
        } else if totalWarnings > 0 {
            return .secure // Minor warnings are acceptable
        } else {
            return .secure
        }
    }
    
    private func collectDeviceInfo() -> DeviceInfo {
        #if canImport(UIKit)
        return DeviceInfo(
            model: UIDevice.current.model,
            systemName: UIDevice.current.systemName,
            systemVersion: UIDevice.current.systemVersion,
            identifierForVendor: UIDevice.current.identifierForVendor?.uuidString,
            isSimulator: isRunningInSimulator()
        )
        #else
        return DeviceInfo(
            model: "Unknown",
            systemName: "Unknown",
            systemVersion: "Unknown",
            identifierForVendor: nil,
            isSimulator: isRunningInSimulator()
        )
        #endif
    }
    
    private func isRunningInSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    private func updateSecurityStatus(_ result: SecurityValidationResult) async {
        await MainActor.run {
            currentSecurityLevel = result.securityLevel
            securityChecks = result.checks
            lastValidationDate = result.validatedAt
        }
    }
}

// MARK: - Supporting Types

/// Individual security check result
public struct SecurityCheck {
    public enum Status: String, CaseIterable {
        case pass = "pass"
        case warning = "warning"
        case fail = "fail"
        
        public var emoji: String {
            switch self {
            case .pass: return "✅"
            case .warning: return "⚠️"
            case .fail: return "❌"
            }
        }
    }
    
    public enum Impact: String, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
    
    public let name: String
    public let status: Status
    public let score: Double // 0.0 to 1.0
    public let details: [String]
    public let impact: Impact
    
    public var summary: String {
        return "\(status.emoji) \(name): \(status.rawValue.capitalized) (Score: \(String(format: "%.2f", score)))"
    }
}

/// Complete security validation result
public class SecurityValidationResult: ObservableObject {
    public let securityLevel: SecurityValidator.SecurityLevel
    public let checks: [SecurityCheck]
    public let validationTime: TimeInterval
    public let validatedAt: Date
    public let deviceInfo: DeviceInfo
    
    public init(securityLevel: SecurityValidator.SecurityLevel, checks: [SecurityCheck], validationTime: TimeInterval, validatedAt: Date, deviceInfo: DeviceInfo) {
        self.securityLevel = securityLevel
        self.checks = checks
        self.validationTime = validationTime
        self.validatedAt = validatedAt
        self.deviceInfo = deviceInfo
    }
    
    public var overallScore: Double {
        let scores = checks.map { $0.score }
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    public var summary: String {
        let passCount = checks.filter { $0.status == .pass }.count
        let warningCount = checks.filter { $0.status == .warning }.count
        let failCount = checks.filter { $0.status == .fail }.count
        
        return """
        Security Validation Result:
        - Level: \(securityLevel.description)
        - Overall Score: \(String(format: "%.2f", overallScore))
        - Checks: \(passCount) pass, \(warningCount) warning, \(failCount) fail
        - Validation Time: \(String(format: "%.2f", validationTime))s
        - Device: \(deviceInfo.model) (\(deviceInfo.systemName) \(deviceInfo.systemVersion))
        - Validated: \(validatedAt)
        """
    }
    
    public struct BundleValidation {
        public enum Action: String {
            case accept = "accept"
            case reject = "reject"
            case warn = "warn"
        }
        
        public let isValid: Bool
        public let issues: [String]
        public let warnings: [String]
        public let recommendedAction: Action
    }
}

/// Device information for security context
public struct DeviceInfo {
    public let model: String
    public let systemName: String
    public let systemVersion: String
    public let identifierForVendor: String?
    public let isSimulator: Bool
}