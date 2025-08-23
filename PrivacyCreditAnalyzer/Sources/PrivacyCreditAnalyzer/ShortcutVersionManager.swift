import Foundation

/// Manages shortcut versions and updates
public class ShortcutVersionManager {
    
    // MARK: - Version Information
    
    public struct ShortcutVersion {
        public let version: String
        public let releaseDate: Date
        public let features: [String]
        public let bugFixes: [String]
        public let isRequired: Bool
        
        public init(version: String, releaseDate: Date, features: [String], bugFixes: [String], isRequired: Bool) {
            self.version = version
            self.releaseDate = releaseDate
            self.features = features
            self.bugFixes = bugFixes
            self.isRequired = isRequired
        }
    }
    
    // MARK: - Current Version
    
    public static let currentVersion = "1.0.0"
    
    // MARK: - Version History
    
    public static let versionHistory: [ShortcutVersion] = [
        ShortcutVersion(
            version: "1.0.0",
            releaseDate: Date(),
            features: [
                "Initial release with three performance tiers",
                "Smart message filtering and sampling",
                "Privacy-compliant data extraction",
                "Comprehensive error handling"
            ],
            bugFixes: [],
            isRequired: true
        )
    ]
    
    // MARK: - Update Information
    
    public struct UpdateInfo {
        public let hasUpdate: Bool
        public let latestVersion: String
        public let currentVersion: String
        public let isRequired: Bool
        public let releaseNotes: String
        
        public init(hasUpdate: Bool, latestVersion: String, currentVersion: String, isRequired: Bool, releaseNotes: String) {
            self.hasUpdate = hasUpdate
            self.latestVersion = latestVersion
            self.currentVersion = currentVersion
            self.isRequired = isRequired
            self.releaseNotes = releaseNotes
        }
    }
    
    // MARK: - Public Methods
    
    /// Checks if a shortcut version is compatible with the current app
    public static func isVersionCompatible(_ version: String) -> Bool {
        // For now, all versions are compatible
        // In the future, this could check for breaking changes
        return true
    }
    
    /// Gets update information for a given version
    public static func getUpdateInfo(for currentVersion: String) -> UpdateInfo {
        let latest = versionHistory.last!
        let hasUpdate = currentVersion != latest.version
        
        let releaseNotes = latest.features.map { "• \($0)" }.joined(separator: "\n") +
                          (latest.bugFixes.isEmpty ? "" : "\n\nBug Fixes:\n" + latest.bugFixes.map { "• \($0)" }.joined(separator: "\n"))
        
        return UpdateInfo(
            hasUpdate: hasUpdate,
            latestVersion: latest.version,
            currentVersion: currentVersion,
            isRequired: latest.isRequired,
            releaseNotes: releaseNotes
        )
    }
    
    /// Validates shortcut data version compatibility
    public static func validateDataVersion(_ dataVersion: String) throws {
        guard isVersionCompatible(dataVersion) else {
            throw ShortcutVersionError.incompatibleVersion(dataVersion: dataVersion, appVersion: currentVersion)
        }
    }
    
    /// Gets migration instructions for upgrading from an old version
    public static func getMigrationInstructions(from oldVersion: String, to newVersion: String) -> [String] {
        // For now, return generic migration instructions
        return [
            "Delete the old shortcut from the Shortcuts app",
            "Download and install the new version",
            "Grant permissions when prompted",
            "Test the connection with a small dataset"
        ]
    }
    
    /// Generates a changelog for display in the app
    public static func generateChangelog() -> String {
        return versionHistory.reversed().map { version in
            var changelog = "## Version \(version.version)\n"
            changelog += "Released: \(DateFormatter.shortDate.string(from: version.releaseDate))\n\n"
            
            if !version.features.isEmpty {
                changelog += "### New Features\n"
                changelog += version.features.map { "• \($0)" }.joined(separator: "\n")
                changelog += "\n\n"
            }
            
            if !version.bugFixes.isEmpty {
                changelog += "### Bug Fixes\n"
                changelog += version.bugFixes.map { "• \($0)" }.joined(separator: "\n")
                changelog += "\n\n"
            }
            
            return changelog
        }.joined(separator: "\n")
    }
}

// MARK: - Errors

public enum ShortcutVersionError: Error, LocalizedError {
    case incompatibleVersion(dataVersion: String, appVersion: String)
    case updateRequired(currentVersion: String, requiredVersion: String)
    
    public var errorDescription: String? {
        switch self {
        case .incompatibleVersion(let dataVersion, let appVersion):
            return "Shortcut data version \(dataVersion) is not compatible with app version \(appVersion). Please update your shortcuts."
        case .updateRequired(let currentVersion, let requiredVersion):
            return "Shortcut version \(currentVersion) is outdated. Version \(requiredVersion) or later is required."
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}