import Foundation
import SwiftUI
import PrivacyCreditAnalyzer

/// Manages iOS Shortcuts integration and URL scheme handling
@MainActor
class ShortcutsManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isProcessingShortcutData = false
    @Published var shortcutMessages: [Message] = []
    @Published var lastShortcutError: String?
    @Published var validationResult: ValidationResult?
    
    // MARK: - Private Properties
    
    private let shortcutsDataHandler = ShortcutsDataHandler()
    private let shortcutInstaller = ShortcutInstaller()
    
    // MARK: - Public Methods
    
    /// Handles incoming URL from iOS Shortcuts
    func handleIncomingURL(_ url: URL) {
        guard url.scheme == "privacycredit" else {
            lastShortcutError = "Invalid URL scheme: \(url.scheme ?? "none")"
            return
        }
        
        guard url.host == "import" else {
            lastShortcutError = "Invalid URL host: \(url.host ?? "none")"
            return
        }
        
        // Extract data parameter from URL
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let dataItem = queryItems.first(where: { $0.name == "data" }),
              let dataString = dataItem.value,
              let data = dataString.data(using: .utf8) else {
            lastShortcutError = "No data parameter found in URL"
            return
        }
        
        processShortcutData(data)
    }
    
    /// Processes data received from iOS Shortcuts
    func processShortcutData(_ data: Data) {
        isProcessingShortcutData = true
        lastShortcutError = nil
        
        Task {
            do {
                // First validate the data
                let validation = try shortcutsDataHandler.validateShortcutData(data)
                validationResult = validation
                
                // Process the data
                let messages = try shortcutsDataHandler.processShortcutData(data)
                
                await MainActor.run {
                    shortcutMessages = messages
                    isProcessingShortcutData = false
                    
                    // Show validation info if sampling was needed
                    if validation.needsSampling {
                        lastShortcutError = "Dataset was large (\(validation.messageCount) messages). Sampled to \(validation.recommendedSampleSize) messages for optimal performance."
                    }
                }
                
            } catch let error as ShortcutsDataHandler.ShortcutDataError {
                await MainActor.run {
                    lastShortcutError = error.localizedDescription
                    isProcessingShortcutData = false
                }
            } catch {
                await MainActor.run {
                    lastShortcutError = "Unexpected error: \(error.localizedDescription)"
                    isProcessingShortcutData = false
                }
            }
        }
    }
    
    /// Converts messages to display text format
    func messagesToDisplayText(_ messages: [Message]) -> String {
        return messages.map { message in
            let sender = message.isFromUser ? "Me" : message.sender
            let timestamp = DateFormatter.shortTime.string(from: message.timestamp)
            return "[\(timestamp)] \(sender): \(message.content)"
        }.joined(separator: "\n")
    }
    
    /// Gets performance recommendations
    func getPerformanceRecommendations() -> [PerformanceRecommendation] {
        return shortcutInstaller.getPerformanceRecommendations()
    }
    
    /// Gets troubleshooting info for an issue
    func getTroubleshootingInfo(for issue: ShortcutInstaller.TroubleshootingIssue) -> TroubleshootingInfo {
        return shortcutInstaller.getTroubleshootingInfo(for: issue)
    }
    
    /// Gets shortcut installation URL
    func getShortcutInstallationURL() -> URL? {
        return shortcutInstaller.getShortcutInstallationURL()
    }
    
    /// Clears current shortcut data and errors
    func clearShortcutData() {
        shortcutMessages = []
        lastShortcutError = nil
        validationResult = nil
    }
}

// MARK: - Supporting Extensions

extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Validation Result Extension

extension ValidationResult {
    var statusMessage: String {
        if needsSampling {
            return "Large dataset detected (\(messageCount) messages). Sampling recommended for optimal performance."
        } else {
            return "Dataset ready for analysis (\(messageCount) messages, \(ByteCountFormatter.string(fromByteCount: Int64(dataSize), countStyle: .file)))"
        }
    }
    
    var statusColor: Color {
        if needsSampling {
            return .orange
        } else {
            return .green
        }
    }
}