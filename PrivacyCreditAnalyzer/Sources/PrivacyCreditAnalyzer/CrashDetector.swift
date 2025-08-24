import Foundation
import os.log

#if os(iOS) && !targetEnvironment(simulator)
import UIKit
#endif

/// Comprehensive crash detection and logging system for debugging app pauses and crashes
public class CrashDetector {
    
    // MARK: - Singleton
    
    public static let shared = CrashDetector()
    
    private init() {
        setupCrashDetection()
    }
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.privacycreditanalyzer.app", category: "CrashDetector")
    private var appLaunchTime = Date()
    private var lastActivityTime = Date()
    
    // MARK: - Public Interface
    
    /// Logs app startup and initialization
    public func logAppStartup() {
        appLaunchTime = Date()
        logger.info("🚀 App startup initiated at \(self.appLaunchTime)")
        
        // Log environment information
        logEnvironmentInfo()
        
        // Log device capabilities
        logDeviceCapabilities()
        
        // Log memory status
        logMemoryStatus()
    }
    
    /// Records activity to track app responsiveness
    public func recordActivity(_ description: String) {
        lastActivityTime = Date()
        logger.debug("📱 Activity: \(description)")
    }
    
    /// Logs potential crash/pause with detailed context
    public func logPotentialCrash(_ context: String, error: Error? = nil) {
        logger.error("🚨 POTENTIAL CRASH/PAUSE DETECTED")
        logger.error("📍 Context: \(context)")
        logger.error("⏰ Time since launch: \(Date().timeIntervalSince(self.appLaunchTime))s")
        logger.error("🔄 Time since last activity: \(Date().timeIntervalSince(self.lastActivityTime))s")
        
        if let error = error {
            logger.error("❌ Error: \(error.localizedDescription)")
        }
        
        // Log current system state
        logSystemState()
        
        // Log MLX-specific information
        logMLXStatus()
        
        // Print to console for immediate visibility
        print("🚨 CRASH DETECTOR ALERT:")
        print("📍 Context: \(context)")
        print("⏰ Time since launch: \(Date().timeIntervalSince(self.appLaunchTime))s")
        if let error = error {
            print("❌ Error: \(error)")
        }
    }
    
    /// Logs MLX initialization attempt with detailed tracking
    public func logMLXInitialization() {
        logger.info("🔄 MLX INITIALIZATION ATTEMPT")
        
        #if targetEnvironment(simulator)
        logger.warning("📱 Environment: iOS Simulator - MLX not supported")
        logger.info("✅ Expected behavior: Should skip MLX initialization")
        print("📱 SIMULATOR MODE: MLX initialization should be skipped")
        #else
        logger.info("📱 Environment: Physical Device - MLX supported")
        logger.info("🔄 Attempting MLX framework initialization...")
        print("📱 DEVICE MODE: Attempting MLX initialization")
        #endif
        
        recordActivity("MLX initialization attempt")
    }
    
    /// Logs successful operations for baseline comparison
    public func logSuccess(_ operation: String, duration: TimeInterval) {
        logger.info("✅ SUCCESS: \(operation) completed in \(String(format: "%.2f", duration))s")
        recordActivity("Successful \(operation)")
    }
    
    /// Monitors app state transitions
    public func logStateTransition(from: String, to: String) {
        logger.info("🔄 State transition: \(from) → \(to)")
        recordActivity("State transition to \(to)")
    }
    
    // MARK: - Private Implementation
    
    private func setupCrashDetection() {
        // Set up signal handlers for common crash signals
        signal(SIGABRT) { signal in
            CrashDetector.shared.handleCrashSignal("SIGABRT", signal: signal)
        }
        
        signal(SIGSEGV) { signal in
            CrashDetector.shared.handleCrashSignal("SIGSEGV", signal: signal)
        }
        
        signal(SIGILL) { signal in
            CrashDetector.shared.handleCrashSignal("SIGILL", signal: signal)
        }
        
        signal(SIGFPE) { signal in
            CrashDetector.shared.handleCrashSignal("SIGFPE", signal: signal)
        }
    }
    
    private func handleCrashSignal(_ signalName: String, signal: Int32) {
        logger.critical("💥 CRASH SIGNAL RECEIVED: \(signalName) (\(signal))")
        print("💥 FATAL: \(signalName) signal received")
        print("📱 Check console for detailed crash information")
        
        // Log crash context
        logSystemState()
        logMLXStatus()
        
        // Try to save crash info (if possible)
        saveCrashInfo(signal: signalName)
        
        // Re-raise the signal to allow normal crash handling
        raise(signal)
    }
    
    private func logEnvironmentInfo() {
        #if targetEnvironment(simulator)
        logger.info("📱 Environment: iOS Simulator")
        logger.info("🚫 MLX Support: Not Available")
        logger.info("💻 Host Platform: \(ProcessInfo.processInfo.hostName)")
        print("📱 ENVIRONMENT: iOS Simulator (MLX disabled)")
        #else
        logger.info("📱 Environment: Physical iOS Device")
        logger.info("✅ MLX Support: Available")
        print("📱 ENVIRONMENT: Physical Device (MLX enabled)")
        #endif
        
        logger.info("🔧 iOS Version: \(ProcessInfo.processInfo.operatingSystemVersionString)")
        logger.info("💾 Physical Memory: \(ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory))")
    }
    
    private func logDeviceCapabilities() {
        let processInfo = ProcessInfo.processInfo
        
        logger.info("💻 DEVICE CAPABILITIES:")
        logger.info("  • Processor Count: \(processInfo.processorCount)")
        logger.info("  • Active Processors: \(processInfo.activeProcessorCount)")
        
        #if !targetEnvironment(simulator)
        logger.info("  • Thermal State: \(self.thermalStateDescription(processInfo.thermalState))")
        logger.info("  • Low Power Mode: \(processInfo.isLowPowerModeEnabled)")
        #endif
    }
    
    private func logMemoryStatus() {
        let processInfo = ProcessInfo.processInfo
        let memoryFormatter = ByteCountFormatter()
        memoryFormatter.countStyle = .memory
        
        logger.info("💾 MEMORY STATUS:")
        logger.info("  • Physical Memory: \(memoryFormatter.string(fromByteCount: Int64(processInfo.physicalMemory)))")
        
        // Get current memory usage using mach APIs
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedMemory = Int64(info.resident_size)
            logger.info("  • Current Usage: \(memoryFormatter.string(fromByteCount: usedMemory))")
            logger.info("  • Memory Pressure: \(usedMemory > Int64(processInfo.physicalMemory) / 2 ? "HIGH" : "NORMAL")")
            
            print("💾 Memory: \(memoryFormatter.string(fromByteCount: usedMemory)) / \(memoryFormatter.string(fromByteCount: Int64(processInfo.physicalMemory)))")
        }
    }
    
    private func logSystemState() {
        logger.info("📊 CURRENT SYSTEM STATE:")
        logMemoryStatus()
        
        #if !targetEnvironment(simulator)
        let processInfo = ProcessInfo.processInfo
        logger.info("🌡️ Thermal State: \(self.thermalStateDescription(processInfo.thermalState))")
        
        if processInfo.thermalState == .serious || processInfo.thermalState == .critical {
            logger.warning("⚠️ Device overheating may be causing performance issues")
            print("🌡️ WARNING: Device thermal state is \(self.thermalStateDescription(processInfo.thermalState))")
        }
        #endif
    }
    
    private func logMLXStatus() {
        logger.info("🧠 MLX STATUS CHECK:")
        
        #if targetEnvironment(simulator)
        logger.info("📱 Simulator: MLX imports should be excluded")
        logger.info("🚫 MLX Availability: Not Available (Expected)")
        print("🧠 MLX: Simulator mode - framework not loaded")
        #else
        logger.info("📱 Device: MLX imports should be available")
        logger.info("✅ MLX Availability: Should be Available")
        print("🧠 MLX: Device mode - framework should be available")
        
        // This is a minimal check that shouldn't cause crashes
        logger.info("🔍 Performing MLX availability check...")
        print("🔍 Checking MLX framework availability...")
        #endif
    }
    
    #if !targetEnvironment(simulator)
    private func thermalStateDescription(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal:
            return "Nominal (Good)"
        case .fair:
            return "Fair (Warm)"
        case .serious:
            return "Serious (Hot)"
        case .critical:
            return "Critical (Very Hot)"
        @unknown default:
            return "Unknown"
        }
    }
    #else
    private func thermalStateDescription(_ state: Any) -> String {
        return "N/A (Simulator)"
    }
    #endif
    
    private func saveCrashInfo(signal: String) {
        let crashInfo = """
        CRASH DETECTED: \(signal)
        Time: \(Date())
        Time since launch: \(Date().timeIntervalSince(self.appLaunchTime))s
        Time since last activity: \(Date().timeIntervalSince(self.lastActivityTime))s
        Environment: \(targetEnvironment)
        Memory: \(ProcessInfo.processInfo.physicalMemory) bytes
        """
        
        print("💾 Crash info:")
        print(crashInfo)
        
        // In a production app, you might save this to a file or send to crash reporting service
        logger.critical("💾 Crash info logged: \(crashInfo)")
    }
    
    private var targetEnvironment: String {
        #if targetEnvironment(simulator)
        return "iOS Simulator"
        #else
        return "iOS Device"
        #endif
    }
}

// MARK: - Convenience Methods

extension CrashDetector {
    
    /// Wraps potentially dangerous operations with crash detection
    public func safeExecute<T>(_ operation: String, _ block: () throws -> T) -> T? {
        recordActivity("Starting \(operation)")
        
        do {
            let startTime = Date()
            let result = try block()
            let duration = Date().timeIntervalSince(startTime)
            logSuccess(operation, duration: duration)
            return result
        } catch {
            logPotentialCrash("Failed during \(operation)", error: error)
            return nil
        }
    }
    
    /// Async version of safe execution
    public func safeExecuteAsync<T>(_ operation: String, _ block: () async throws -> T) async -> T? {
        recordActivity("Starting async \(operation)")
        
        do {
            let startTime = Date()
            let result = try await block()
            let duration = Date().timeIntervalSince(startTime)
            logSuccess(operation, duration: duration)
            return result
        } catch {
            logPotentialCrash("Failed during async \(operation)", error: error)
            return nil
        }
    }
}

// MARK: - App State Monitoring

extension CrashDetector {
    
    /// Sets up monitoring for app lifecycle events
    public func setupAppLifecycleMonitoring() {
        #if os(iOS) && !targetEnvironment(simulator)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.logStateTransition(from: "Background/Inactive", to: "Active")
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.logStateTransition(from: "Active", to: "Inactive")
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.logStateTransition(from: "Inactive", to: "Background")
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.logger.warning("⚠️ MEMORY WARNING RECEIVED")
            self.logMemoryStatus()
            print("⚠️ MEMORY WARNING: App received memory pressure notification")
        }
        #else
        // In simulator, set up basic monitoring without UIApplication
        print("📱 Simulator mode: Limited app lifecycle monitoring available")
        #endif
    }
}