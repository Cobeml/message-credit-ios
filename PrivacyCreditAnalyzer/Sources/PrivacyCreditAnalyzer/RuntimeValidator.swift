import Foundation

/// Comprehensive runtime environment validation and safety checks
public class RuntimeValidator {
    
    // MARK: - Singleton
    
    public static let shared = RuntimeValidator()
    
    private init() {}
    
    // MARK: - Environment Validation
    
    /// Performs comprehensive environment validation at app startup
    public func validateEnvironment() -> RuntimeValidationResult {
        var warnings: [String] = []
        var errors: [String] = []
        var isValid = true
        
        // Check iOS version compatibility
        let iosVersionResult = validateiOSVersion()
        warnings.append(contentsOf: iosVersionResult.warnings)
        errors.append(contentsOf: iosVersionResult.errors)
        if !iosVersionResult.isValid { isValid = false }
        
        // Check device capabilities
        let deviceResult = validateDeviceCapabilities()
        warnings.append(contentsOf: deviceResult.warnings)
        errors.append(contentsOf: deviceResult.errors)
        if !deviceResult.isValid { isValid = false }
        
        // Check memory availability
        let memoryResult = validateMemoryAvailability()
        warnings.append(contentsOf: memoryResult.warnings)
        errors.append(contentsOf: memoryResult.errors)
        if !memoryResult.isValid { isValid = false }
        
        // Check MLX compatibility
        let mlxResult = validateMLXCompatibility()
        warnings.append(contentsOf: mlxResult.warnings)
        errors.append(contentsOf: mlxResult.errors)
        // Note: MLX incompatibility is not a validation failure, just affects feature availability
        
        let result = RuntimeValidationResult(
            isValid: isValid,
            warnings: warnings,
            errors: errors,
            environment: currentEnvironment
        )
        
        logValidationResult(result)
        return result
    }
    
    /// Validates that the app can safely initialize MLX components
    public func validateMLXSafety() -> MLXSafetyResult {
        #if targetEnvironment(simulator)
        return MLXSafetyResult(
            canInitializeMLX: false,
            reason: "iOS Simulator does not support MLX framework",
            recommendation: "Use mock analysis in simulator; deploy to physical device for MLX",
            severity: .info
        )
        #else
        
        // Check device compatibility
        guard validateAppleSiliconCompatibility() else {
            return MLXSafetyResult(
                canInitializeMLX: false,
                reason: "Device may not support MLX framework (Apple Silicon required)",
                recommendation: "Verify device compatibility; fallback to mock analysis if needed",
                severity: .warning
            )
        }
        
        // Check memory availability
        let availableMemory = ProcessInfo.processInfo.physicalMemory
        let requiredMemory: UInt64 = 1_000_000_000 // 1GB minimum
        
        guard availableMemory >= requiredMemory else {
            return MLXSafetyResult(
                canInitializeMLX: false,
                reason: "Insufficient memory for MLX operations (\(formatMemory(availableMemory)) available, \(formatMemory(requiredMemory)) required)",
                recommendation: "Close other apps to free memory or use lightweight analysis mode",
                severity: .error
            )
        }
        
        // Check thermal state
        let thermalState = ProcessInfo.processInfo.thermalState
        if thermalState == .critical {
            return MLXSafetyResult(
                canInitializeMLX: false,
                reason: "Device thermal state is critical",
                recommendation: "Allow device to cool before attempting MLX operations",
                severity: .error
            )
        } else if thermalState == .serious {
            return MLXSafetyResult(
                canInitializeMLX: true,
                reason: "Device thermal state is elevated but acceptable",
                recommendation: "Monitor thermal state during processing; may reduce performance",
                severity: .warning
            )
        }
        
        return MLXSafetyResult(
            canInitializeMLX: true,
            reason: "Device meets all MLX requirements",
            recommendation: "Proceed with MLX initialization",
            severity: .info
        )
        #endif
    }
    
    /// Continuously monitors runtime conditions
    public func monitorRuntimeConditions() -> RuntimeConditions {
        let processInfo = ProcessInfo.processInfo
        
        return RuntimeConditions(
            memoryPressure: calculateMemoryPressure(),
            thermalState: processInfo.thermalState,
            isLowPowerMode: processInfo.isLowPowerModeEnabled,
            availableProcessors: processInfo.activeProcessorCount,
            uptime: processInfo.systemUptime,
            timestamp: Date()
        )
    }
    
    // MARK: - Private Validation Methods
    
    private func validateiOSVersion() -> RuntimeValidationResult {
        let currentVersion = ProcessInfo.processInfo.operatingSystemVersion
        let minimumVersion = OperatingSystemVersion(majorVersion: 17, minorVersion: 0, patchVersion: 0)
        
        var warnings: [String] = []
        var errors: [String] = []
        
        if !ProcessInfo.processInfo.isOperatingSystemAtLeast(minimumVersion) {
            errors.append("iOS version \(formatVersion(currentVersion)) is below minimum required version \(formatVersion(minimumVersion))")
            return RuntimeValidationResult(isValid: false, warnings: warnings, errors: errors, environment: currentEnvironment)
        }
        
        // Check for optimal versions
        let recommendedVersion = OperatingSystemVersion(majorVersion: 17, minorVersion: 4, patchVersion: 0)
        if !ProcessInfo.processInfo.isOperatingSystemAtLeast(recommendedVersion) {
            warnings.append("iOS version \(formatVersion(currentVersion)) is below recommended version \(formatVersion(recommendedVersion)) for optimal performance")
        }
        
        return RuntimeValidationResult(isValid: true, warnings: warnings, errors: errors, environment: currentEnvironment)
    }
    
    private func validateDeviceCapabilities() -> RuntimeValidationResult {
        let processInfo = ProcessInfo.processInfo
        var warnings: [String] = []
        let errors: [String] = []
        
        // Check processor count
        if processInfo.processorCount < 4 {
            warnings.append("Device has only \(processInfo.processorCount) processors, which may impact performance")
        }
        
        // Check active processors
        if processInfo.activeProcessorCount < processInfo.processorCount {
            warnings.append("Only \(processInfo.activeProcessorCount) of \(processInfo.processorCount) processors are active")
        }
        
        return RuntimeValidationResult(isValid: true, warnings: warnings, errors: errors, environment: currentEnvironment)
    }
    
    private func validateMemoryAvailability() -> RuntimeValidationResult {
        let processInfo = ProcessInfo.processInfo
        let availableMemory = processInfo.physicalMemory
        let minimumMemory: UInt64 = 500_000_000 // 500MB
        let recommendedMemory: UInt64 = 2_000_000_000 // 2GB
        
        var warnings: [String] = []
        var errors: [String] = []
        
        if availableMemory < minimumMemory {
            errors.append("Insufficient memory: \(formatMemory(availableMemory)) available, \(formatMemory(minimumMemory)) minimum required")
            return RuntimeValidationResult(isValid: false, warnings: warnings, errors: errors, environment: currentEnvironment)
        }
        
        if availableMemory < recommendedMemory {
            warnings.append("Memory below recommended: \(formatMemory(availableMemory)) available, \(formatMemory(recommendedMemory)) recommended")
        }
        
        // Check current memory pressure
        let memoryPressure = calculateMemoryPressure()
        if memoryPressure > 0.8 {
            warnings.append("High memory pressure detected (\(Int(memoryPressure * 100))%)")
        }
        
        return RuntimeValidationResult(isValid: true, warnings: warnings, errors: errors, environment: currentEnvironment)
    }
    
    private func validateMLXCompatibility() -> RuntimeValidationResult {
        var warnings: [String] = []
        var errors: [String] = []
        
        #if targetEnvironment(simulator)
        warnings.append("MLX framework not available in iOS Simulator")
        return RuntimeValidationResult(isValid: true, warnings: warnings, errors: errors, environment: currentEnvironment)
        #else
        
        // Check Apple Silicon compatibility
        if !validateAppleSiliconCompatibility() {
            warnings.append("Device may not support MLX framework optimally")
        }
        
        return RuntimeValidationResult(isValid: true, warnings: warnings, errors: errors, environment: currentEnvironment)
        #endif
    }
    
    private func validateAppleSiliconCompatibility() -> Bool {
        // Basic heuristic: check if we're on a device that likely has Apple Silicon
        // This is a simplified check; more sophisticated detection could be implemented
        let processInfo = ProcessInfo.processInfo
        
        // Apple Silicon devices typically have 8+ cores and 4GB+ RAM
        return processInfo.processorCount >= 8 && processInfo.physicalMemory >= 4_000_000_000
    }
    
    private func calculateMemoryPressure() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0.0 }
        
        let usedMemory = Double(info.resident_size)
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
        
        return usedMemory / totalMemory
    }
    
    // MARK: - Utility Methods
    
    private var currentEnvironment: RuntimeEnvironment {
        #if targetEnvironment(simulator)
        return .simulator
        #else
        return .device
        #endif
    }
    
    private func formatMemory(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func formatVersion(_ version: OperatingSystemVersion) -> String {
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    
    private func logValidationResult(_ result: RuntimeValidationResult) {
        print("🔍 RUNTIME VALIDATION RESULTS:")
        print("Environment: \(result.environment)")
        print("Valid: \(result.isValid ? "✅" : "❌")")
        
        if !result.warnings.isEmpty {
            print("⚠️ Warnings:")
            for warning in result.warnings {
                print("  • \(warning)")
            }
        }
        
        if !result.errors.isEmpty {
            print("❌ Errors:")
            for error in result.errors {
                print("  • \(error)")
            }
        }
        
        if result.warnings.isEmpty && result.errors.isEmpty {
            print("✅ All validation checks passed")
        }
    }
}

// MARK: - Supporting Types

public struct RuntimeValidationResult {
    public let isValid: Bool
    public let warnings: [String]
    public let errors: [String]
    public let environment: RuntimeEnvironment
    
    public var hasWarnings: Bool { !warnings.isEmpty }
    public var hasErrors: Bool { !errors.isEmpty }
    
    public var summary: String {
        let status = isValid ? "✅ Valid" : "❌ Invalid"
        let warningCount = warnings.isEmpty ? "" : " (\(warnings.count) warnings)"
        let errorCount = errors.isEmpty ? "" : " (\(errors.count) errors)"
        return "\(status)\(warningCount)\(errorCount)"
    }
}

public struct MLXSafetyResult {
    public let canInitializeMLX: Bool
    public let reason: String
    public let recommendation: String
    public let severity: SafetySeverity
    
    public enum SafetySeverity {
        case info
        case warning
        case error
        
        public var emoji: String {
            switch self {
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            }
        }
    }
}

public struct RuntimeConditions {
    public let memoryPressure: Double // 0.0 to 1.0
    public let thermalState: ProcessInfo.ThermalState
    public let isLowPowerMode: Bool
    public let availableProcessors: Int
    public let uptime: TimeInterval
    public let timestamp: Date
    
    public var isOptimal: Bool {
        return memoryPressure < 0.7 && 
               thermalState == .nominal && 
               !isLowPowerMode
    }
    
    public var summary: String {
        let memoryStatus = memoryPressure < 0.5 ? "Good" : memoryPressure < 0.8 ? "Fair" : "High"
        let thermalStatus = thermalState == .nominal ? "Good" : "Elevated"
        let powerStatus = isLowPowerMode ? "Low Power" : "Normal"
        
        return "Memory: \(memoryStatus), Thermal: \(thermalStatus), Power: \(powerStatus)"
    }
}

public enum RuntimeEnvironment {
    case simulator
    case device
    
    public var description: String {
        switch self {
        case .simulator: return "iOS Simulator"
        case .device: return "Physical Device"
        }
    }
}

// MARK: - Safety Helpers

extension RuntimeValidator {
    
    /// Performs a quick safety check before critical operations
    public func quickSafetyCheck() -> Bool {
        let conditions = monitorRuntimeConditions()
        
        // Basic safety criteria
        return conditions.memoryPressure < 0.9 && 
               conditions.thermalState != .critical
    }
    
    /// Gets a user-friendly status message
    public func getStatusMessage() -> String {
        let conditions = monitorRuntimeConditions()
        
        if conditions.isOptimal {
            return "✅ System conditions optimal"
        } else {
            var issues: [String] = []
            
            if conditions.memoryPressure > 0.8 {
                issues.append("high memory usage")
            }
            
            if conditions.thermalState != .nominal {
                issues.append("elevated temperature")
            }
            
            if conditions.isLowPowerMode {
                issues.append("low power mode")
            }
            
            let issueList = issues.joined(separator: ", ")
            return "⚠️ System conditions: \(issueList)"
        }
    }
}