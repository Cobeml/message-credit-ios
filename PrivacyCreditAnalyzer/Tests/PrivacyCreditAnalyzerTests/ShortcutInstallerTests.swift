import XCTest
@testable import PrivacyCreditAnalyzer

final class ShortcutInstallerTests: XCTestCase {
    
    var installer: ShortcutInstaller!
    
    override func setUp() {
        super.setUp()
        installer = ShortcutInstaller()
    }
    
    override func tearDown() {
        installer = nil
        super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testDefaultConfiguration() {
        let config = ShortcutInstaller.ShortcutConfiguration.default
        XCTAssertEqual(config.name, "Privacy Credit Analyzer")
        XCTAssertEqual(config.version, "1.0.0")
        XCTAssertEqual(config.bundleIdentifier, "com.privacycredit.analyzer")
        XCTAssertEqual(config.urlScheme, "privacycredit")
    }
    
    // MARK: - Installation Step Tests
    
    func testInstallationStepProperties() {
        let steps = ShortcutInstaller.InstallationStep.allCases
        XCTAssertEqual(steps.count, 5)
        
        for step in steps {
            XCTAssertFalse(step.title.isEmpty)
            XCTAssertFalse(step.description.isEmpty)
            XCTAssertFalse(step.instructions.isEmpty)
        }
    }
    
    func testInstallationStepInstructions() {
        let downloadStep = ShortcutInstaller.InstallationStep.downloadShortcut
        XCTAssertTrue(downloadStep.instructions.contains { $0.contains("Shortcuts App") })
        
        let permissionsStep = ShortcutInstaller.InstallationStep.grantPermissions
        XCTAssertTrue(permissionsStep.instructions.contains { $0.contains("Messages") })
        
        let testStep = ShortcutInstaller.InstallationStep.testConnection
        XCTAssertTrue(testStep.instructions.contains { $0.contains("messages") })
    }
    
    // MARK: - Troubleshooting Tests
    
    func testTroubleshootingIssueProperties() {
        let issues = ShortcutInstaller.TroubleshootingIssue.allCases
        XCTAssertEqual(issues.count, 5)
        
        for issue in issues {
            XCTAssertFalse(issue.title.isEmpty)
            XCTAssertFalse(issue.description.isEmpty)
            XCTAssertFalse(issue.solutions.isEmpty)
        }
    }
    
    func testGetTroubleshootingInfo() {
        let issue = ShortcutInstaller.TroubleshootingIssue.shortcutNotFound
        let info = installer.getTroubleshootingInfo(for: issue)
        
        XCTAssertEqual(info.issue, issue)
        XCTAssertEqual(info.title, issue.title)
        XCTAssertEqual(info.description, issue.description)
        XCTAssertEqual(info.solutions, issue.solutions)
        XCTAssertFalse(info.contactSupport.isEmpty)
    }
    
    func testTroubleshootingSolutions() {
        let permissionIssue = ShortcutInstaller.TroubleshootingIssue.permissionDenied
        XCTAssertTrue(permissionIssue.solutions.contains { $0.contains("Privacy & Security") })
        
        let connectionIssue = ShortcutInstaller.TroubleshootingIssue.connectionFailed
        XCTAssertTrue(connectionIssue.solutions.contains { $0.contains("URL scheme") })
        
        let dataIssue = ShortcutInstaller.TroubleshootingIssue.dataLimitExceeded
        XCTAssertTrue(dataIssue.solutions.contains { $0.contains("Quick analysis") })
    }
    
    // MARK: - Shortcut Definition Tests
    
    func testGenerateShortcutDefinition() {
        let tier = ShortcutsDataHandler.PerformanceTier.standard
        let definition = installer.generateShortcutDefinition(for: tier)
        
        XCTAssertTrue(definition.name.contains("Standard Analysis"))
        XCTAssertEqual(definition.version, "1.0.0")
        XCTAssertEqual(definition.performanceTier, tier)
        XCTAssertEqual(definition.urlScheme, "privacycredit")
        XCTAssertFalse(definition.actions.isEmpty)
    }
    
    func testShortcutDefinitionActions() {
        let tier = ShortcutsDataHandler.PerformanceTier.quick
        let definition = installer.generateShortcutDefinition(for: tier)
        
        let actionTypes = definition.actions.map { $0.type }
        XCTAssertTrue(actionTypes.contains("GetMessages"))
        XCTAssertTrue(actionTypes.contains("FilterMessages"))
        XCTAssertTrue(actionTypes.contains("FormatData"))
        XCTAssertTrue(actionTypes.contains("ShareWithApp"))
    }
    
    func testShortcutActionParameters() {
        let tier = ShortcutsDataHandler.PerformanceTier.deep
        let definition = installer.generateShortcutDefinition(for: tier)
        
        let getMessagesAction = definition.actions.first { $0.type == "GetMessages" }
        XCTAssertNotNil(getMessagesAction)
        
        if let action = getMessagesAction {
            XCTAssertEqual(action.parameters["timeRange"] as? Int, tier.timeRangeDays)
            XCTAssertEqual(action.parameters["messageLimit"] as? Int, tier.messageLimit)
            XCTAssertEqual(action.parameters["prioritizeFinancial"] as? Bool, true)
        }
    }
    
    // MARK: - Performance Recommendations Tests
    
    func testGetPerformanceRecommendations() {
        let recommendations = installer.getPerformanceRecommendations()
        XCTAssertEqual(recommendations.count, 3)
        
        let quickRec = recommendations.first { $0.tier == .quick }
        XCTAssertNotNil(quickRec)
        XCTAssertEqual(quickRec?.messageCount, 200)
        XCTAssertEqual(quickRec?.timeRange, "7 days")
        
        let standardRec = recommendations.first { $0.tier == .standard }
        XCTAssertNotNil(standardRec)
        XCTAssertEqual(standardRec?.messageCount, 1000)
        XCTAssertEqual(standardRec?.timeRange, "30 days")
        
        let deepRec = recommendations.first { $0.tier == .deep }
        XCTAssertNotNil(deepRec)
        XCTAssertEqual(deepRec?.messageCount, 5000)
        XCTAssertEqual(deepRec?.timeRange, "90 days")
    }
    
    func testPerformanceRecommendationContent() {
        let recommendations = installer.getPerformanceRecommendations()
        
        for recommendation in recommendations {
            XCTAssertFalse(recommendation.title.isEmpty)
            XCTAssertFalse(recommendation.description.isEmpty)
            XCTAssertFalse(recommendation.processingTime.isEmpty)
            XCTAssertFalse(recommendation.memoryUsage.isEmpty)
            XCTAssertFalse(recommendation.recommendedFor.isEmpty)
        }
    }
    
    // MARK: - URL Generation Tests
    
    func testGetShortcutInstallationURL() {
        let url = installer.getShortcutInstallationURL()
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "shortcuts")
    }
    
    // MARK: - Validation Tests
    
    func testValidateInstallation() async {
        let result = await installer.validateInstallation()
        
        // Mock validation should return positive results
        XCTAssertTrue(result.isInstalled)
        XCTAssertTrue(result.hasPermissions)
        XCTAssertTrue(result.canCommunicate)
        XCTAssertEqual(result.version, "1.0.0")
        XCTAssertTrue(result.issues.isEmpty)
    }
    
    // MARK: - Custom Configuration Tests
    
    func testCustomConfiguration() {
        let customConfig = ShortcutInstaller.ShortcutConfiguration(
            name: "Custom App",
            version: "2.0.0",
            bundleIdentifier: "com.custom.app",
            urlScheme: "customscheme"
        )
        
        let customInstaller = ShortcutInstaller(configuration: customConfig)
        let definition = customInstaller.generateShortcutDefinition(for: .quick)
        
        XCTAssertTrue(definition.name.contains("Custom App"))
        XCTAssertEqual(definition.version, "2.0.0")
        XCTAssertEqual(definition.urlScheme, "customscheme")
        XCTAssertEqual(definition.bundleIdentifier, "com.custom.app")
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyActionParameters() {
        let tier = ShortcutsDataHandler.PerformanceTier.quick
        let definition = installer.generateShortcutDefinition(for: tier)
        
        for action in definition.actions {
            XCTAssertFalse(action.parameters.isEmpty, "Action \(action.type) should have parameters")
        }
    }
    
    func testAllTroubleshootingIssuesHaveSolutions() {
        for issue in ShortcutInstaller.TroubleshootingIssue.allCases {
            let info = installer.getTroubleshootingInfo(for: issue)
            XCTAssertFalse(info.solutions.isEmpty, "Issue \(issue.rawValue) should have solutions")
            
            for solution in info.solutions {
                XCTAssertFalse(solution.isEmpty, "Solution should not be empty")
            }
        }
    }
}