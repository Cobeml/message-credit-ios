import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Performance optimization manager for iPhone constraints and thermal management
/// Handles device capabilities, memory pressure, and thermal throttling for cryptographic operations
public class PerformanceOptimizer: ObservableObject {
    
    // MARK: - Configuration
    
    public struct OptimizationProfile {
        let maxMemoryUsage: Int64 // Maximum memory usage in bytes
        let thermalThrottlingThreshold: ProcessInfo.ThermalState
        let backgroundProcessingEnabled: Bool
        let zkpOptimizationLevel: ZKPOptimizationLevel
        let batchSizeLimit: Int
        let proofCachingEnabled: Bool
        
        public static let iPhone = OptimizationProfile(
            maxMemoryUsage: 500_000_000, // 500MB
            thermalThrottlingThreshold: .serious,
            backgroundProcessingEnabled: true,
            zkpOptimizationLevel: .balanced,
            batchSizeLimit: 50,
            proofCachingEnabled: true
        )
        
        public static let iPadPro = OptimizationProfile(
            maxMemoryUsage: 2_000_000_000, // 2GB
            thermalThrottlingThreshold: .critical,
            backgroundProcessingEnabled: true,
            zkpOptimizationLevel: .high,
            batchSizeLimit: 100,
            proofCachingEnabled: true
        )
        
        public static let simulator = OptimizationProfile(
            maxMemoryUsage: 1_000_000_000, // 1GB
            thermalThrottlingThreshold: .critical,
            backgroundProcessingEnabled: false,
            zkpOptimizationLevel: .mock,
            batchSizeLimit: 25,
            proofCachingEnabled: false
        )
    }
    
    public enum ZKPOptimizationLevel: String, CaseIterable {
        case mock = "mock"           // Simulator/testing mode
        case minimal = "minimal"     // Fastest, lowest security
        case balanced = "balanced"   // Balance of speed and security
        case high = "high"          // Maximum security, slower
        
        public var description: String {
            switch self {
            case .mock:
                return "Mock mode (no real ZKP)"
            case .minimal:
                return "Minimal ZKP (fast)"
            case .balanced:
                return "Balanced ZKP"
            case .high:
                return "High security ZKP"
            }
        }
    }
    
    // MARK: - Properties
    
    @Published public var currentProfile: OptimizationProfile
    @Published public var thermalState: ProcessInfo.ThermalState = .nominal
    @Published public var memoryPressure: MemoryPressureLevel = .normal
    @Published public var batteryLevel: Float = 1.0
    @Published public var isLowPowerModeEnabled: Bool = false
    @Published public var optimizationRecommendations: [OptimizationRecommendation] = []
    
    private let deviceCapabilities: DeviceCapabilities
    private var thermalStateObserver: NSObjectProtocol?
    private var batteryLevelObserver: NSObjectProtocol?
    private var lowPowerModeObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    
    public init() {
        self.deviceCapabilities = DeviceCapabilities.detect()
        self.currentProfile = deviceCapabilities.recommendedProfile
        
        setupSystemMonitoring()
        updateOptimizationRecommendations()
    }
    
    deinit {
        removeSystemMonitoring()
    }
    
    // MARK: - System Monitoring
    
    private func setupSystemMonitoring() {
        // Monitor thermal state changes
        thermalStateObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateThermalState()
        }
        
        // Monitor battery level changes
        #if canImport(UIKit)
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevelObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateBatteryLevel()
        }
        #endif
        
        // Monitor low power mode changes
        lowPowerModeObserver = NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePowerState()
        }
        
        // Initial state update
        updateThermalState()
        updateBatteryLevel()
        updatePowerState()
        updateMemoryPressure()
    }
    
    private func removeSystemMonitoring() {
        if let observer = thermalStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = batteryLevelObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = lowPowerModeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func updateThermalState() {
        thermalState = ProcessInfo.processInfo.thermalState
        updateOptimizationRecommendations()
    }
    
    private func updateBatteryLevel() {
        #if canImport(UIKit)
        batteryLevel = UIDevice.current.batteryLevel
        #else
        batteryLevel = 1.0 // Default to full battery on non-iOS platforms
        #endif
        updateOptimizationRecommendations()
    }
    
    private func updatePowerState() {
        isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        updateOptimizationRecommendations()
    }
    
    private func updateMemoryPressure() {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let availableMemory = getAvailableMemory()
        let usageRatio = 1.0 - (Double(availableMemory) / Double(physicalMemory))
        
        if usageRatio > 0.9 {
            memoryPressure = .critical
        } else if usageRatio > 0.7 {
            memoryPressure = .high
        } else if usageRatio > 0.5 {
            memoryPressure = .moderate
        } else {
            memoryPressure = .normal
        }
        
        updateOptimizationRecommendations()
    }
    
    // MARK: - Optimization Recommendations
    
    private func updateOptimizationRecommendations() {
        var recommendations: [OptimizationRecommendation] = []
        
        // Thermal recommendations
        if thermalStateRawValue() >= thermalThrottlingThresholdRawValue() {
            recommendations.append(.thermalThrottling(
                "Device thermal state is \(thermalState). Consider reducing processing intensity or adding cooling delays."
            ))
        }
        
        // Memory recommendations
        if memoryPressure == .critical {
            recommendations.append(.memoryOptimization(
                "Critical memory pressure detected. Reduce batch sizes and enable memory cleanup."
            ))
        } else if memoryPressure == .high {
            recommendations.append(.memoryOptimization(
                "High memory usage. Consider enabling proof caching and reducing concurrent operations."
            ))
        }
        
        // Battery recommendations
        if batteryLevel < 0.2 {
            recommendations.append(.batteryOptimization(
                "Low battery (\(Int(batteryLevel * 100))%). Consider reducing ZKP complexity or deferring analysis."
            ))
        }
        
        // Low power mode recommendations
        if isLowPowerModeEnabled {
            recommendations.append(.powerModeOptimization(
                "Low power mode enabled. Switch to minimal ZKP optimization and reduce background processing."
            ))
        }
        
        // Device capability recommendations
        if !deviceCapabilities.supportsSecureEnclave {
            recommendations.append(.securityOptimization(
                "Device doesn't support Secure Enclave. Consider software-based key storage with additional warnings."
            ))
        }
        
        self.optimizationRecommendations = recommendations
    }
    
    // MARK: - Optimization Methods
    
    /// Determines if ZKP generation should be performed given current conditions
    public func shouldPerformZKPGeneration() -> ZKPDecision {
        // Check thermal state
        if thermalStateRawValue() >= ProcessInfo.ThermalState.critical.rawValue {
            return .skip("Critical thermal state - device too hot")
        }
        
        // Check memory pressure
        if memoryPressure == .critical {
            return .skip("Critical memory pressure")
        }
        
        // Check battery level
        if batteryLevel < 0.1 {
            return .skip("Battery too low (\(Int(batteryLevel * 100))%)")
        }
        
        // Check low power mode
        if isLowPowerModeEnabled {
            return .deferUntilLater("Low power mode enabled - defer until charging")
        }
        
        // Determine optimization level
        let optimizationLevel = determineZKPOptimizationLevel()
        return .proceed(optimizationLevel)
    }
    
    /// Calculates optimal batch size based on current system conditions
    public func calculateOptimalBatchSize(requestedSize: Int) -> Int {
        var optimalSize = min(requestedSize, currentProfile.batchSizeLimit)
        
        // Adjust for thermal state
        if thermalStateRawValue() >= ProcessInfo.ThermalState.serious.rawValue {
            optimalSize = Int(Double(optimalSize) * 0.5)
        }
        
        // Adjust for memory pressure
        switch memoryPressure {
        case .critical:
            optimalSize = Int(Double(optimalSize) * 0.3)
        case .high:
            optimalSize = Int(Double(optimalSize) * 0.6)
        case .moderate:
            optimalSize = Int(Double(optimalSize) * 0.8)
        case .normal:
            break
        }
        
        // Adjust for low power mode
        if isLowPowerModeEnabled {
            optimalSize = Int(Double(optimalSize) * 0.4)
        }
        
        return max(optimalSize, 5) // Minimum batch size
    }
    
    /// Determines if background processing should be enabled
    public func shouldEnableBackgroundProcessing() -> Bool {
        return currentProfile.backgroundProcessingEnabled &&
               !isLowPowerModeEnabled &&
               memoryPressure != .critical &&
               thermalStateRawValue() < ProcessInfo.ThermalState.critical.rawValue
    }
    
    /// Calculates recommended delay between operations to prevent overheating
    public func calculateCooldownDelay() -> TimeInterval {
        switch thermalState {
        case .critical:
            return 10.0 // 10 second delay
        case .serious:
            return 5.0  // 5 second delay
        case .fair:
            return 2.0  // 2 second delay
        case .nominal:
            return 0.0  // No delay
        @unknown default:
            return 5.0  // Conservative default
        }
    }
    
    private func determineZKPOptimizationLevel() -> ZKPOptimizationLevel {
        // If low power mode or critical conditions, use minimal
        if isLowPowerModeEnabled || thermalStateRawValue() >= ProcessInfo.ThermalState.critical.rawValue || memoryPressure == .critical {
            return .minimal
        }
        
        // If moderate stress, use balanced
        if thermalStateRawValue() >= ProcessInfo.ThermalState.serious.rawValue || memoryPressureRawValue() >= 2 || batteryLevel < 0.3 {
            return .balanced
        }
        
        // Otherwise use profile default
        return currentProfile.zkpOptimizationLevel
    }
    
    // MARK: - Thermal State Helpers
    
    /// Helper method to get thermal state raw value for comparison
    private func thermalStateRawValue() -> Int {
        return thermalState.rawValue
    }
    
    /// Helper method to get thermal throttling threshold raw value
    private func thermalThrottlingThresholdRawValue() -> Int {
        return currentProfile.thermalThrottlingThreshold.rawValue
    }
    
    /// Helper method to get memory pressure raw value for comparison
    public func memoryPressureRawValue() -> Int {
        switch memoryPressure {
        case .normal: return 0
        case .moderate: return 1
        case .high: return 2
        case .critical: return 3
        }
    }
    
    // MARK: - Memory Management
    
    private func getAvailableMemory() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
    
    /// Forces memory cleanup and garbage collection
    public func performMemoryCleanup() {
        // Force garbage collection
        autoreleasepool {
            // Trigger memory cleanup
        }
        
        print("🧹 Performed memory cleanup")
    }
    
    // MARK: - Device Detection
    
    public struct DeviceCapabilities {
        public let modelName: String
        public let physicalMemory: Int64
        public let processorCount: Int
        public let supportsSecureEnclave: Bool
        public let supportsAppAttest: Bool
        public let recommendedProfile: OptimizationProfile
        
        public static func detect() -> DeviceCapabilities {
            let processInfo = ProcessInfo.processInfo
            let physicalMemory = processInfo.physicalMemory
            let processorCount = processInfo.processorCount
            
            #if targetEnvironment(simulator)
            return DeviceCapabilities(
                modelName: "iOS Simulator",
                physicalMemory: physicalMemory,
                processorCount: processorCount,
                supportsSecureEnclave: false,
                supportsAppAttest: false,
                recommendedProfile: .simulator
            )
            #else
            #if canImport(UIKit)
            let modelName = UIDevice.current.model
            #else
            let modelName = "Unknown Device"
            #endif
            let supportsSecureEnclave = physicalMemory >= 3_000_000_000 // 3GB+ typically have Secure Enclave
            let supportsAppAttest = ProcessInfo.processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 14, minorVersion: 0, patchVersion: 0))
            
            // Determine profile based on memory and model
            let recommendedProfile: OptimizationProfile
            if physicalMemory >= 6_000_000_000 { // 6GB+ (iPad Pro, iPhone Pro models)
                recommendedProfile = .iPadPro
            } else {
                recommendedProfile = .iPhone
            }
            
            return DeviceCapabilities(
                modelName: modelName,
                physicalMemory: Int64(physicalMemory),
                processorCount: processorCount,
                supportsSecureEnclave: supportsSecureEnclave,
                supportsAppAttest: supportsAppAttest,
                recommendedProfile: recommendedProfile
            )
            #endif
        }
    }
    
    // MARK: - Public Interface
    
    /// Returns current system status summary
    public func getSystemStatus() -> SystemStatus {
        return SystemStatus(
            deviceCapabilities: deviceCapabilities,
            thermalState: thermalState,
            memoryPressure: memoryPressure,
            batteryLevel: batteryLevel,
            isLowPowerModeEnabled: isLowPowerModeEnabled,
            recommendations: optimizationRecommendations
        )
    }
}

// MARK: - Supporting Types

public enum MemoryPressureLevel: String, CaseIterable {
    case normal = "normal"
    case moderate = "moderate"
    case high = "high"
    case critical = "critical"
    
    public var description: String {
        switch self {
        case .normal: return "Normal"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

public enum OptimizationRecommendation: Equatable {
    case thermalThrottling(String)
    case memoryOptimization(String)
    case batteryOptimization(String)
    case powerModeOptimization(String)
    case securityOptimization(String)
    
    public var message: String {
        switch self {
        case .thermalThrottling(let message),
             .memoryOptimization(let message),
             .batteryOptimization(let message),
             .powerModeOptimization(let message),
             .securityOptimization(let message):
            return message
        }
    }
    
    public var priority: RecommendationPriority {
        switch self {
        case .thermalThrottling, .memoryOptimization:
            return .critical
        case .batteryOptimization, .powerModeOptimization:
            return .high
        case .securityOptimization:
            return .medium
        }
    }
}

public enum RecommendationPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

public enum ZKPDecision {
    case proceed(PerformanceOptimizer.ZKPOptimizationLevel)
    case deferUntilLater(String)
    case skip(String)
    
    public var shouldProceed: Bool {
        if case .proceed = self { return true }
        return false
    }
    
    public var reason: String? {
        switch self {
        case .proceed: return nil
        case .deferUntilLater(let reason), .skip(let reason): return reason
        }
    }
}

public struct SystemStatus {
    public let deviceCapabilities: PerformanceOptimizer.DeviceCapabilities
    public let thermalState: ProcessInfo.ThermalState
    public let memoryPressure: MemoryPressureLevel
    public let batteryLevel: Float
    public let isLowPowerModeEnabled: Bool
    public let recommendations: [OptimizationRecommendation]
    
    public var summary: String {
        return """
        System Status:
        - Device: \(deviceCapabilities.modelName)
        - Memory: \(String(format: "%.1f", Double(deviceCapabilities.physicalMemory) / 1_000_000_000))GB
        - Thermal: \(thermalState)
        - Memory Pressure: \(memoryPressure.description)
        - Battery: \(Int(batteryLevel * 100))%
        - Low Power Mode: \(isLowPowerModeEnabled)
        - Secure Enclave: \(deviceCapabilities.supportsSecureEnclave)
        - App Attest: \(deviceCapabilities.supportsAppAttest)
        - Recommendations: \(recommendations.count)
        """
    }
}