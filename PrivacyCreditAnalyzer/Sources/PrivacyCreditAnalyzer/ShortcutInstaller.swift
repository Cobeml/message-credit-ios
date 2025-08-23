import Foundation

/// Manages iOS Shortcut installation and user guidance
public class ShortcutInstaller {
    
    // MARK: - Configuration
    
    public struct ShortcutConfiguration {
        public let name: String
        public let version: String
        public let bundleIdentifier: String
        public let urlScheme: String
        
        public static let `default` = ShortcutConfiguration(
            name: "Privacy Credit Analyzer",
            version: "1.0.0",
            bundleIdentifier: "com.privacycredit.analyzer",
            urlScheme: "privacycredit"
        )
        
        public init(name: String, version: String, bundleIdentifier: String, urlScheme: String) {
            self.name = name
            self.version = version
            self.bundleIdentifier = bundleIdentifier
            self.urlScheme = urlScheme
        }
    }
    
    // MARK: - Installation Steps
    
    public enum InstallationStep: String, CaseIterable {
        case downloadShortcut = "download"
        case grantPermissions = "permissions"
        case testConnection = "test"
        case selectPerformanceTier = "performance"
        case complete = "complete"
        
        public var title: String {
            switch self {
            case .downloadShortcut:
                return "Download Shortcut"
            case .grantPermissions:
                return "Grant Permissions"
            case .testConnection:
                return "Test Connection"
            case .selectPerformanceTier:
                return "Choose Performance Tier"
            case .complete:
                return "Setup Complete"
            }
        }
        
        public var description: String {
            switch self {
            case .downloadShortcut:
                return "Download and install the Privacy Credit Analyzer shortcut from the Shortcuts app"
            case .grantPermissions:
                return "Grant the shortcut permission to access your Messages app data"
            case .testConnection:
                return "Run a test to ensure the shortcut can communicate with this app"
            case .selectPerformanceTier:
                return "Choose your preferred analysis depth and processing time"
            case .complete:
                return "Your shortcut is ready to use! You can now extract messages directly from iMessages"
            }
        }
        
        public var instructions: [String] {
            switch self {
            case .downloadShortcut:
                return [
                    "Tap 'Open Shortcuts App' below",
                    "Find the 'Privacy Credit Analyzer' shortcut",
                    "Tap 'Add Shortcut' to install it",
                    "Return to this app when complete"
                ]
            case .grantPermissions:
                return [
                    "Open the Shortcuts app",
                    "Find your 'Privacy Credit Analyzer' shortcut",
                    "Tap the shortcut to run it",
                    "When prompted, grant access to Messages",
                    "Allow the shortcut to share data with this app"
                ]
            case .testConnection:
                return [
                    "Run the shortcut from the Shortcuts app",
                    "Select a small number of recent messages (10-20)",
                    "The shortcut should automatically open this app",
                    "Verify that messages appear in the input field"
                ]
            case .selectPerformanceTier:
                return [
                    "Choose your preferred analysis depth:",
                    "• Quick: 200 messages, 7 days (~30 seconds)",
                    "• Standard: 1,000 messages, 30 days (~2-3 minutes)",
                    "• Deep: 5,000 messages, 90 days (~5-10 minutes)"
                ]
            case .complete:
                return [
                    "Your shortcut is now configured and ready to use",
                    "Run it anytime to extract messages for analysis",
                    "The app will automatically process and analyze your data",
                    "Remember: all processing happens on your device for privacy"
                ]
            }
        }
    }
    
    // MARK: - Troubleshooting Issues
    
    public enum TroubleshootingIssue: String, CaseIterable {
        case shortcutNotFound = "not_found"
        case permissionDenied = "permission_denied"
        case connectionFailed = "connection_failed"
        case dataLimitExceeded = "data_limit"
        case processingTimeout = "timeout"
        
        public var title: String {
            switch self {
            case .shortcutNotFound:
                return "Shortcut Not Found"
            case .permissionDenied:
                return "Permission Denied"
            case .connectionFailed:
                return "Connection Failed"
            case .dataLimitExceeded:
                return "Data Limit Exceeded"
            case .processingTimeout:
                return "Processing Timeout"
            }
        }
        
        public var description: String {
            switch self {
            case .shortcutNotFound:
                return "The Privacy Credit Analyzer shortcut is not installed or cannot be found"
            case .permissionDenied:
                return "The shortcut doesn't have permission to access Messages or share data"
            case .connectionFailed:
                return "The shortcut cannot communicate with this app"
            case .dataLimitExceeded:
                return "The selected messages exceed the maximum data size or count limits"
            case .processingTimeout:
                return "Message extraction is taking too long or has timed out"
            }
        }
        
        public var solutions: [String] {
            switch self {
            case .shortcutNotFound:
                return [
                    "Open the Shortcuts app and search for 'Privacy Credit Analyzer'",
                    "If not found, reinstall the shortcut using the link in this app",
                    "Make sure you're signed in to the same Apple ID",
                    "Try restarting the Shortcuts app"
                ]
            case .permissionDenied:
                return [
                    "Open Settings > Privacy & Security > Shortcuts",
                    "Find 'Privacy Credit Analyzer' and enable permissions",
                    "Open the shortcut and grant access when prompted",
                    "Try running the shortcut again"
                ]
            case .connectionFailed:
                return [
                    "Make sure this app is installed and up to date",
                    "Check that the URL scheme is correctly configured",
                    "Try closing and reopening both apps",
                    "Restart your device if the issue persists"
                ]
            case .dataLimitExceeded:
                return [
                    "Select fewer conversations or a shorter time range",
                    "Use the Quick analysis option (200 messages, 7 days)",
                    "Focus on conversations with financial content",
                    "The app will automatically sample large datasets"
                ]
            case .processingTimeout:
                return [
                    "Select a smaller dataset (fewer messages or shorter time range)",
                    "Close other apps to free up memory",
                    "Make sure your device has sufficient battery",
                    "Try the Quick analysis option for faster processing"
                ]
            }
        }
    }
    
    // MARK: - Properties
    
    private let configuration: ShortcutConfiguration
    
    // MARK: - Initialization
    
    public init(configuration: ShortcutConfiguration = .default) {
        self.configuration = configuration
    }
    
    // MARK: - Public Methods
    
    /// Generates the shortcut installation URL
    public func getShortcutInstallationURL() -> URL? {
        // In a real implementation, this would point to the actual shortcut
        // For now, we'll create a placeholder URL that opens the Shortcuts app
        return URL(string: "shortcuts://")
    }
    
    /// Generates the shortcut definition for installation
    public func generateShortcutDefinition(for tier: ShortcutsDataHandler.PerformanceTier) -> ShortcutDefinition {
        return ShortcutDefinition(
            name: "\(configuration.name) - \(tier.displayName)",
            version: configuration.version,
            performanceTier: tier,
            urlScheme: configuration.urlScheme,
            bundleIdentifier: configuration.bundleIdentifier,
            actions: generateShortcutActions(for: tier)
        )
    }
    
    /// Validates that the shortcut is properly installed and configured
    public func validateInstallation() async -> ShortcutValidationResult {
        // In a real implementation, this would check:
        // 1. If the shortcut exists in the Shortcuts app
        // 2. If it has the correct permissions
        // 3. If it can communicate with this app
        
        // For now, return a mock validation result
        return ShortcutValidationResult(
            isInstalled: true,
            hasPermissions: true,
            canCommunicate: true,
            version: configuration.version,
            issues: []
        )
    }
    
    /// Gets troubleshooting information for common issues
    public func getTroubleshootingInfo(for issue: TroubleshootingIssue) -> TroubleshootingInfo {
        return TroubleshootingInfo(
            issue: issue,
            title: issue.title,
            description: issue.description,
            solutions: issue.solutions,
            contactSupport: "If these solutions don't work, please contact support with details about your device and iOS version."
        )
    }
    
    /// Gets performance recommendations based on device capabilities
    public func getPerformanceRecommendations() -> [PerformanceRecommendation] {
        return [
            PerformanceRecommendation(
                tier: .quick,
                title: "Quick Analysis",
                description: "Best for daily check-ins and recent activity",
                messageCount: 200,
                timeRange: "7 days",
                processingTime: "~30 seconds",
                memoryUsage: "~5MB",
                recommendedFor: ["Daily monitoring", "Quick insights", "Low battery situations"]
            ),
            PerformanceRecommendation(
                tier: .standard,
                title: "Standard Analysis",
                description: "Balanced analysis for monthly assessments",
                messageCount: 1000,
                timeRange: "30 days",
                processingTime: "~2-3 minutes",
                memoryUsage: "~15-25MB",
                recommendedFor: ["Monthly reviews", "Credit monitoring", "General use"]
            ),
            PerformanceRecommendation(
                tier: .deep,
                title: "Deep Analysis",
                description: "Comprehensive evaluation for important decisions",
                messageCount: 5000,
                timeRange: "90 days",
                processingTime: "~5-10 minutes",
                memoryUsage: "~50-75MB",
                recommendedFor: ["Loan applications", "Major financial decisions", "Comprehensive reports"]
            )
        ]
    }
    
    // MARK: - Private Methods
    
    private func generateShortcutActions(for tier: ShortcutsDataHandler.PerformanceTier) -> [ShortcutAction] {
        return [
            ShortcutAction(
                type: "GetMessages",
                parameters: [
                    "timeRange": tier.timeRangeDays,
                    "messageLimit": tier.messageLimit,
                    "prioritizeFinancial": true
                ]
            ),
            ShortcutAction(
                type: "FilterMessages",
                parameters: [
                    "maxPerConversation": 1000,
                    "financialKeywords": true,
                    "recentPriority": true
                ]
            ),
            ShortcutAction(
                type: "FormatData",
                parameters: [
                    "format": "json",
                    "includeMetadata": true,
                    "performanceTier": tier.rawValue
                ]
            ),
            ShortcutAction(
                type: "ShareWithApp",
                parameters: [
                    "urlScheme": configuration.urlScheme,
                    "bundleIdentifier": configuration.bundleIdentifier
                ]
            )
        ]
    }
}

// MARK: - Supporting Types

/// Definition of a shortcut for installation
public struct ShortcutDefinition {
    public let name: String
    public let version: String
    public let performanceTier: ShortcutsDataHandler.PerformanceTier
    public let urlScheme: String
    public let bundleIdentifier: String
    public let actions: [ShortcutAction]
    
    public init(name: String, version: String, performanceTier: ShortcutsDataHandler.PerformanceTier, urlScheme: String, bundleIdentifier: String, actions: [ShortcutAction]) {
        self.name = name
        self.version = version
        self.performanceTier = performanceTier
        self.urlScheme = urlScheme
        self.bundleIdentifier = bundleIdentifier
        self.actions = actions
    }
}

/// Individual action within a shortcut
public struct ShortcutAction {
    public let type: String
    public let parameters: [String: Any]
    
    public init(type: String, parameters: [String: Any]) {
        self.type = type
        self.parameters = parameters
    }
}

/// Result of shortcut installation validation
public struct ShortcutValidationResult {
    public let isInstalled: Bool
    public let hasPermissions: Bool
    public let canCommunicate: Bool
    public let version: String
    public let issues: [String]
    
    public init(isInstalled: Bool, hasPermissions: Bool, canCommunicate: Bool, version: String, issues: [String]) {
        self.isInstalled = isInstalled
        self.hasPermissions = hasPermissions
        self.canCommunicate = canCommunicate
        self.version = version
        self.issues = issues
    }
}

/// Troubleshooting information for common issues
public struct TroubleshootingInfo {
    public let issue: ShortcutInstaller.TroubleshootingIssue
    public let title: String
    public let description: String
    public let solutions: [String]
    public let contactSupport: String
    
    public init(issue: ShortcutInstaller.TroubleshootingIssue, title: String, description: String, solutions: [String], contactSupport: String) {
        self.issue = issue
        self.title = title
        self.description = description
        self.solutions = solutions
        self.contactSupport = contactSupport
    }
}

/// Performance recommendation for different analysis tiers
public struct PerformanceRecommendation {
    public let tier: ShortcutsDataHandler.PerformanceTier
    public let title: String
    public let description: String
    public let messageCount: Int
    public let timeRange: String
    public let processingTime: String
    public let memoryUsage: String
    public let recommendedFor: [String]
    
    public init(tier: ShortcutsDataHandler.PerformanceTier, title: String, description: String, messageCount: Int, timeRange: String, processingTime: String, memoryUsage: String, recommendedFor: [String]) {
        self.tier = tier
        self.title = title
        self.description = description
        self.messageCount = messageCount
        self.timeRange = timeRange
        self.processingTime = processingTime
        self.memoryUsage = memoryUsage
        self.recommendedFor = recommendedFor
    }
}