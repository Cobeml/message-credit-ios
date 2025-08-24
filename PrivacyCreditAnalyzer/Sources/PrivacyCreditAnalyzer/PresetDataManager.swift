import Foundation
import Combine

/// Manages preset data loading for frontend testing and demonstration
public class PresetDataManager: ObservableObject {
    
    public init() {}
    
    // MARK: - Preset Types
    
    public enum PresetType: String, CaseIterable {
        case responsibleUser = "responsible"
        case irresponsibleUser = "irresponsible" 
        
        public var displayName: String {
            switch self {
            case .responsibleUser:
                return "Responsible User Sample"
            case .irresponsibleUser:
                return "Irresponsible User Sample"
            }
        }
        
        public var description: String {
            switch self {
            case .responsibleUser:
                return "High creditworthiness user with excellent financial habits, strong relationships, and good planning skills"
            case .irresponsibleUser:
                return "Low creditworthiness user with poor financial management, emotional volatility, and relationship issues"
            }
        }
        
        public var icon: String {
            switch self {
            case .responsibleUser:
                return "🏆"
            case .irresponsibleUser:
                return "📉"
            }
        }
        
        public var expectedScore: Double {
            switch self {
            case .responsibleUser:
                return 0.809
            case .irresponsibleUser:
                return 0.290
            }
        }
        
        public var riskLevel: String {
            switch self {
            case .responsibleUser:
                return "🟢 LOW RISK"
            case .irresponsibleUser:
                return "🔴 VERY HIGH RISK"
            }
        }
    }
    
    // MARK: - Data Loading Methods
    
    /// Loads preset messages for the specified type
    public func loadPresetMessages(type: PresetType) -> [Message] {
        switch type {
        case .responsibleUser:
            return SampleDataGenerator.generateResponsibleUserMessages()
        case .irresponsibleUser:
            return SampleDataGenerator.generateIrresponsibleUserMessages()
        }
    }
    
    /// Loads preset messages as JSON string for file import testing
    public func loadPresetJSON(type: PresetType) -> String {
        switch type {
        case .responsibleUser:
            return SampleDataGenerator.responsibleUserJSON()
        case .irresponsibleUser:
            return SampleDataGenerator.irresponsibleUserJSON()
        }
    }
    
    /// Loads expected analysis result for comparison testing
    public func loadExpectedResult(type: PresetType) -> AnalysisResult {
        switch type {
        case .responsibleUser:
            return createExpectedResponsibleResult()
        case .irresponsibleUser:
            return createExpectedIrresponsibleResult()
        }
    }
    
    /// Converts messages to display text for text input field
    public func messagesToDisplayText(_ messages: [Message]) -> String {
        return messages.map { message in
            let sender = message.isFromUser ? "Me" : message.sender
            let timestamp = DateFormatter.shortDateTime.string(from: message.timestamp)
            return "[\(timestamp)] \(sender): \(message.content)"
        }.joined(separator: "\n\n")
    }
    
    // MARK: - Temporary File Creation for Testing
    
    /// Creates temporary JSON file for file import testing
    public func createTemporaryJSONFile(type: PresetType) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(type.rawValue)_user_sample_\(Int(Date().timeIntervalSince1970)).json"
        let tempURL = tempDir.appendingPathComponent(fileName)
        
        let jsonContent = loadPresetJSON(type: type)
        try jsonContent.write(to: tempURL, atomically: true, encoding: .utf8)
        
        return tempURL
    }
    
    /// Cleans up temporary files created for testing
    public func cleanupTemporaryFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            for url in contents {
                if url.lastPathComponent.contains("_user_sample_") && url.pathExtension == "json" {
                    try FileManager.default.removeItem(at: url)
                }
            }
        } catch {
            print("Failed to cleanup temporary files: \(error)")
        }
    }
    
    // MARK: - Analysis Comparison
    
    /// Compares actual result with expected result
    public func compareResults(actual: AnalysisResult, expected: AnalysisResult) -> ResultComparison {
        let personalityDifferences = [
            "openness": abs(actual.personalityTraits.openness - expected.personalityTraits.openness),
            "conscientiousness": abs(actual.personalityTraits.conscientiousness - expected.personalityTraits.conscientiousness),
            "extraversion": abs(actual.personalityTraits.extraversion - expected.personalityTraits.extraversion),
            "agreeableness": abs(actual.personalityTraits.agreeableness - expected.personalityTraits.agreeableness),
            "neuroticism": abs(actual.personalityTraits.neuroticism - expected.personalityTraits.neuroticism),
            "confidence": abs(actual.personalityTraits.confidence - expected.personalityTraits.confidence)
        ]
        
        let trustworthinessDifference = abs(actual.trustworthinessScore.score - expected.trustworthinessScore.score)
        
        let avgPersonalityDifference = personalityDifferences.values.reduce(0, +) / Double(personalityDifferences.count)
        
        return ResultComparison(
            personalityDifferences: personalityDifferences,
            trustworthinessDifference: trustworthinessDifference,
            averagePersonalityDifference: avgPersonalityDifference,
            isWithinExpectedRange: trustworthinessDifference < 0.1 && avgPersonalityDifference < 0.15
        )
    }
    
    // MARK: - UI Integration Helpers
    
    /// Gets preset info for UI display
    public func getPresetInfo() -> [PresetInfo] {
        return PresetType.allCases.compactMap { type in
            do {
                let messages = loadPresetMessages(type: type)
                return PresetInfo(
                    type: type,
                    title: type.displayName,
                    description: type.description,
                    icon: type.icon,
                    expectedScore: type.expectedScore,
                    riskLevel: type.riskLevel,
                    messageCount: messages.count
                )
            } catch {
                print("⚠️ Failed to load preset info for \(type): \(error)")
                return nil
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func createExpectedResponsibleResult() -> AnalysisResult {
        let traits = PersonalityTraits(
            openness: 0.660,
            conscientiousness: 0.750,
            extraversion: 0.550,
            agreeableness: 0.817,
            neuroticism: 0.230,
            confidence: 0.820
        )
        
        let trustworthiness = TrustworthinessScore(
            score: 0.809,
            factors: [
                "communication_style": 0.735,
                "financial_responsibility": 0.880,
                "relationship_stability": 0.850,
                "emotional_intelligence": 0.770
            ],
            explanation: "Analysis indicates excellent creditworthiness based on consistent financial planning, early bill payments, active budgeting, and strong relationship stability. User demonstrates excellent self-control, long-term thinking, and reliable communication patterns. Very low risk with strong positive financial behaviors."
        )
        
        return AnalysisResult(
            personalityTraits: traits,
            trustworthinessScore: trustworthiness,
            messageCount: 15,
            processingTime: 2.3
        )
    }
    
    private func createExpectedIrresponsibleResult() -> AnalysisResult {
        let traits = PersonalityTraits(
            openness: 0.410,
            conscientiousness: 0.267,
            extraversion: 0.720,
            agreeableness: 0.360,
            neuroticism: 0.683,
            confidence: 0.280
        )
        
        let trustworthiness = TrustworthinessScore(
            score: 0.290,
            factors: [
                "communication_style": 0.324,
                "financial_responsibility": 0.200,
                "relationship_stability": 0.320,
                "emotional_intelligence": 0.317
            ],
            explanation: "Analysis reveals significant credit risk based on poor financial management, frequent overdrafts, maxed credit cards, and impulsive spending behaviors. User shows low conscientiousness, high emotional volatility, and strained relationships. Multiple red flags including borrowing from family, avoidance of responsibilities, and short-term thinking patterns."
        )
        
        return AnalysisResult(
            personalityTraits: traits,
            trustworthinessScore: trustworthiness,
            messageCount: 15,
            processingTime: 2.1
        )
    }
}

// MARK: - Supporting Types

public struct PresetInfo {
    public let type: PresetDataManager.PresetType
    public let title: String
    public let description: String
    public let icon: String
    public let expectedScore: Double
    public let riskLevel: String
    public let messageCount: Int
}

public struct ResultComparison {
    public let personalityDifferences: [String: Double]
    public let trustworthinessDifference: Double
    public let averagePersonalityDifference: Double
    public let isWithinExpectedRange: Bool
    
    public var accuracyPercentage: Double {
        let maxDifference = max(trustworthinessDifference, averagePersonalityDifference)
        return max(0.0, (1.0 - maxDifference) * 100)
    }
    
    public var summary: String {
        let accuracy = Int(accuracyPercentage)
        if isWithinExpectedRange {
            return "✅ Analysis accuracy: \(accuracy)% - Results within expected range"
        } else {
            return "⚠️ Analysis accuracy: \(accuracy)% - Results differ from expected"
        }
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter
    }()
}