import SwiftUI
import PrivacyCreditAnalyzer

struct ShortcutsHelpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var shortcutsManager: ShortcutsManager
    
    @State private var selectedTier: ShortcutsDataHandler.PerformanceTier = .standard
    @State private var currentStep: ShortcutInstaller.InstallationStep = .downloadShortcut
    @State private var showingTroubleshooting = false
    @State private var selectedIssue: ShortcutInstaller.TroubleshootingIssue = .shortcutNotFound
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "shortcuts")
                                .font(.title2)
                                .foregroundColor(.purple)
                            Text("iOS Shortcuts Integration")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text("Streamline message import with iOS Shortcuts for faster analysis")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Performance Tiers
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose Your Analysis Depth")
                            .font(.headline)
                        
                        ForEach(ShortcutsDataHandler.PerformanceTier.allCases, id: \.self) { tier in
                            PerformanceTierCard(
                                tier: tier,
                                isSelected: selectedTier == tier,
                                onSelect: { selectedTier = tier }
                            )
                        }
                    }
                    
                    // Installation Steps
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Installation Steps")
                            .font(.headline)
                        
                        ForEach(ShortcutInstaller.InstallationStep.allCases, id: \.self) { step in
                            InstallationStepCard(
                                step: step,
                                isCurrent: currentStep == step,
                                onComplete: { 
                                    if let nextStep = nextStep(after: step) {
                                        currentStep = nextStep
                                    }
                                }
                            )
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: openShortcutsApp) {
                            HStack {
                                Image(systemName: "shortcuts")
                                Text("Open Shortcuts App")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: { showingTroubleshooting = true }) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                Text("Troubleshooting")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(10)
                        }
                    }
                    
                    // Tips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tips for Best Results")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            TipRow(icon: "shield.checkered", text: "All processing happens on your device for privacy")
                            TipRow(icon: "clock", text: "Choose Quick analysis for daily check-ins")
                            TipRow(icon: "chart.bar", text: "Use Deep analysis for comprehensive reports")
                            TipRow(icon: "battery.100", text: "Ensure sufficient battery for larger analyses")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Shortcuts Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingTroubleshooting) {
            TroubleshootingView(selectedIssue: $selectedIssue)
                .environmentObject(shortcutsManager)
        }
    }
    
    private func openShortcutsApp() {
        if let url = shortcutsManager.getShortcutInstallationURL() {
            UIApplication.shared.open(url)
        }
    }
    
    private func nextStep(after step: ShortcutInstaller.InstallationStep) -> ShortcutInstaller.InstallationStep? {
        let allSteps = ShortcutInstaller.InstallationStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: step),
              currentIndex + 1 < allSteps.count else {
            return nil
        }
        return allSteps[currentIndex + 1]
    }
}

struct PerformanceTierCard: View {
    let tier: ShortcutsDataHandler.PerformanceTier
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(tier.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                Text(tier.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label("\(tier.messageLimit) messages", systemImage: "message")
                    Spacer()
                    Label("\(tier.timeRangeDays) days", systemImage: "calendar")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InstallationStepCard: View {
    let step: ShortcutInstaller.InstallationStep
    let isCurrent: Bool
    let onComplete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: isCurrent ? "circle" : "checkmark.circle.fill")
                    .foregroundColor(isCurrent ? .blue : .green)
                
                Text(step.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if isCurrent {
                    Button("Mark Complete") {
                        onComplete()
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
                }
            }
            
            Text(step.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if isCurrent {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(step.instructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(instruction)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.leading, 8)
            }
        }
        .padding()
        .background(isCurrent ? Color.blue.opacity(0.05) : Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct TroubleshootingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var shortcutsManager: ShortcutsManager
    @Binding var selectedIssue: ShortcutInstaller.TroubleshootingIssue
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Issue Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Your Issue")
                            .font(.headline)
                        
                        ForEach(ShortcutInstaller.TroubleshootingIssue.allCases, id: \.self) { issue in
                            Button(action: { selectedIssue = issue }) {
                                HStack {
                                    Text(issue.title)
                                        .font(.subheadline)
                                    Spacer()
                                    if selectedIssue == issue {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(selectedIssue == issue ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Solutions
                    let troubleshootingInfo = shortcutsManager.getTroubleshootingInfo(for: selectedIssue)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Solutions")
                            .font(.headline)
                        
                        Text(troubleshootingInfo.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(troubleshootingInfo.solutions.enumerated()), id: \.offset) { index, solution in
                                HStack(alignment: .top) {
                                    Text("\(index + 1).")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(solution)
                                        .font(.subheadline)
                                }
                            }
                        }
                        
                        Text(troubleshootingInfo.contactSupport)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
                .padding()
            }
            .navigationTitle("Troubleshooting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ShortcutsHelpView()
        .environmentObject(ShortcutsManager())
}