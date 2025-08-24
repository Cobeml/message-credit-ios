import Foundation

/// Provides comprehensive logging and developer feedback for MLX inference engine
public class DevelopmentLogger {
    
    // MARK: - Environment Detection Logging
    
    /// Logs comprehensive environment information for developers
    public static func logEnvironmentInfo() {
        print("🔍 DEVELOPMENT ENVIRONMENT ANALYSIS")
        print(String.repeatString("=", count: 50))
        
        #if targetEnvironment(simulator)
        logSimulatorEnvironment()
        #else
        logDeviceEnvironment()
        #endif
        
        logSystemInfo()
        print(String.repeatString("=", count: 50))
    }
    
    /// Logs MLX initialization attempt with context
    public static func logMLXInitialization(isSimulator: Bool, isCompatible: Bool) {
        if isSimulator {
            print("🚨 MLX INITIALIZATION BLOCKED")
            print("📱 Environment: iOS Simulator")
            print("❌ MLX Support: Not Available")
            print("🎯 Action: Using mock analysis")
            print("💡 Tip: Deploy to physical device for real MLX")
        } else if isCompatible {
            print("🚀 MLX INITIALIZATION STARTING")
            print("📱 Environment: Physical Device")
            print("✅ MLX Support: Available")
            print("🎯 Action: Loading MLX framework")
        } else {
            print("⚠️ MLX INITIALIZATION FAILED")
            print("📱 Environment: Physical Device")
            print("❓ MLX Support: Uncertain")
            print("🎯 Action: Falling back to mock analysis")
        }
    }
    
    /// Logs analysis method selection with reasoning
    public static func logAnalysisMethodSelection(messageCount: Int, method: String, reason: String) {
        print("🧠 ANALYSIS METHOD SELECTION")
        print("📊 Message Count: \(messageCount)")
        print("🔧 Selected Method: \(method)")
        print("💭 Reasoning: \(reason)")
        
        #if targetEnvironment(simulator)
        print("⚙️ Simulator Override: All methods use mock analysis")
        #endif
    }
    
    /// Logs performance metrics and recommendations
    public static func logPerformanceInfo(processingTime: TimeInterval, messageCount: Int, method: String) {
        print("⏱️ PERFORMANCE ANALYSIS")
        print("📊 Messages Processed: \(messageCount)")
        print("🔧 Processing Method: \(method)")
        print("⏰ Total Time: \(String(format: "%.2f", processingTime))s")
        print("📈 Rate: \(String(format: "%.1f", Double(messageCount) / processingTime)) messages/second")
        
        // Performance recommendations
        if processingTime > 60 {
            print("💡 Recommendation: Consider using intelligent sampling for datasets over 10,000 messages")
        }
        
        #if targetEnvironment(simulator)
        print("⚙️ Note: Simulator performance doesn't reflect device performance")
        #endif
    }
    
    // MARK: - Private Implementation
    
    private static func logSimulatorEnvironment() {
        print("📱 Environment: iOS Simulator")
        print("🔧 Platform: \(processPlatform())")
        print("💾 MLX Support: ❌ Not Available")
        print("🎯 Analysis Mode: Enhanced Mock Analysis")
        print("🚀 UI Testing: ✅ Full Functionality")
        print("📋 Development: ✅ Perfect for UI/UX work")
        print("")
        print("📝 SIMULATOR LIMITATIONS:")
        print("  • No Metal GPU support")
        print("  • No MLX framework initialization")
        print("  • Performance metrics not representative")
        print("  • Memory usage different from device")
        print("")
        print("🔄 DEVELOPMENT WORKFLOW:")
        print("  1. ✅ Use simulator for UI/UX development")
        print("  2. ✅ Test app flows with mock data")
        print("  3. 📱 Deploy to device for MLX testing")
        print("  4. 🚀 Test performance on physical device")
    }
    
    private static func logDeviceEnvironment() {
        print("📱 Environment: Physical Device")
        print("🔧 Platform: \(processPlatform())")
        print("💾 MLX Support: ✅ Available")
        print("🎯 Analysis Mode: Real MLX Inference")
        print("🚀 Full Functionality: ✅ Complete")
        print("")
        print("💪 DEVICE CAPABILITIES:")
        print("  • Metal GPU acceleration")
        print("  • MLX framework support")
        print("  • Real performance metrics")
        print("  • Accurate memory usage")
        print("")
        print("🎯 RECOMMENDED TESTING:")
        print("  1. 🧪 Test with small datasets first")
        print("  2. 📊 Monitor memory usage")
        print("  3. ⏱️ Measure real performance")
        print("  4. 🔋 Check battery impact")
    }
    
    private static func logSystemInfo() {
        print("💻 SYSTEM INFORMATION:")
        
        let processInfo = ProcessInfo.processInfo
        print("  • Physical Memory: \(ByteCountFormatter.string(fromByteCount: Int64(processInfo.physicalMemory), countStyle: .memory))")
        print("  • Processor Count: \(processInfo.processorCount)")
        print("  • Active Processors: \(processInfo.activeProcessorCount)")
        
        #if !targetEnvironment(simulator)
        print("  • Thermal State: \(thermalStateDescription(processInfo.thermalState))")
        if processInfo.thermalState != .nominal {
            print("    ⚠️ Warning: High thermal state may affect performance")
        }
        #endif
        
        print("  • Low Power Mode: \(processInfo.isLowPowerModeEnabled ? "🔋 Enabled" : "⚡ Disabled")")
    }
    
    private static func processPlatform() -> String {
        #if targetEnvironment(macCatalyst)
        return "macOS (Catalyst)"
        #elseif os(iOS)
        #if targetEnvironment(simulator)
        return "iOS Simulator"
        #else
        return "iOS Device"
        #endif
        #elseif os(macOS)
        return "macOS"
        #else
        return "Unknown"
        #endif
    }
    
    #if !targetEnvironment(simulator)
    private static func thermalStateDescription(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal:
            return "😎 Nominal"
        case .fair:
            return "🌡️ Fair"
        case .serious:
            return "🔥 Serious"
        case .critical:
            return "🚨 Critical"
        @unknown default:
            return "❓ Unknown"
        }
    }
    #endif
}

// MARK: - String Repeat Extension

private extension String {
    static func repeatString(_ string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}

// MARK: - Developer Tips

extension DevelopmentLogger {
    
    /// Provides context-sensitive tips for developers
    public static func provideDevelopmentTips(for context: DevelopmentContext) {
        print("💡 DEVELOPMENT TIPS:")
        
        switch context {
        case .simulatorTesting:
            print("  • ✅ Perfect for UI/UX development")
            print("  • 🎨 Test all app flows and navigation")
            print("  • 📱 Validate responsive design")
            print("  • 🔄 Mock data provides consistent results")
            print("  • 🚫 Don't rely on performance metrics")
            
        case .deviceTesting:
            print("  • 🧪 Test with real message datasets")
            print("  • 📊 Monitor memory usage during analysis")
            print("  • ⏱️ Measure actual processing times")
            print("  • 🔋 Check battery impact on long analyses")
            print("  • 🌡️ Watch for thermal throttling")
            
        case .performanceTesting:
            print("  • 📈 Start with small datasets (10-100 messages)")
            print("  • 📊 Gradually increase to find limits")
            print("  • 💾 Monitor memory usage closely")
            print("  • ⏰ Time different processing methods")
            print("  • 🔄 Test batch vs single processing")
            
        case .debugging:
            print("  • 🐛 Enable detailed console logging")
            print("  • 📝 Check MLX initialization logs")
            print("  • 🔍 Verify device compatibility")
            print("  • 📊 Monitor analysis progress")
            print("  • ⚠️ Look for thermal throttling warnings")
        }
    }
}

// MARK: - Development Context

public enum DevelopmentContext {
    case simulatorTesting
    case deviceTesting
    case performanceTesting
    case debugging
}

// MARK: - Analysis Logging

extension DevelopmentLogger {
    
    /// Logs detailed analysis progress for debugging
    public static func logAnalysisProgress(stage: String, progress: Double, status: String) {
        let percentage = Int(progress * 100)
        let progressBar = createProgressBar(progress: progress)
        
        print("🔄 [\(progressBar)] \(percentage)% - \(stage): \(status)")
    }
    
    /// Logs analysis completion with summary
    public static func logAnalysisCompletion(result: AnalysisResult, isSimulator: Bool) {
        print("✅ ANALYSIS COMPLETE")
        print("📊 Messages: \(result.messageCount)")
        print("⏰ Processing Time: \(String(format: "%.2f", result.processingTime))s")
        
        if let batchInfo = result.batchingInfo {
            print("🔄 Batches: \(batchInfo.totalBatches)")
            print("🏆 Method: \(batchInfo.processingMethod.description)")
        }
        
        if let variance = result.varianceMetrics {
            print("📈 Stability: \(String(format: "%.2f", variance.stabilityScore))")
        }
        
        if isSimulator {
            print("⚙️ Mode: Mock Analysis (Simulator)")
        } else {
            print("🚀 Mode: Real MLX Analysis (Device)")
        }
    }
    
    private static func createProgressBar(progress: Double, length: Int = 20) -> String {
        let filledLength = Int(progress * Double(length))
        let filled = String(repeating: "█", count: filledLength)
        let empty = String(repeating: "░", count: length - filledLength)
        return filled + empty
    }
}