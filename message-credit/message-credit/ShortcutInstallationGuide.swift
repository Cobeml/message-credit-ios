import SwiftUI
import PrivacyCreditAnalyzer

struct ShortcutInstallationGuide: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var shortcutsManager: ShortcutsManager
    
    @State private var selectedTier: ShortcutsDataHandler.PerformanceTier = .standard
    @State private var showingDetailedInstructions = false
    @State private var currentStep = 0
    
    private let installationSteps = [
        "Choose your analysis depth",
        "Download the shortcut",
        "Grant permissions",
        "Test the connection",
        "Start analyzing!"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection
                    
                    // Performance Tier Selection
                    performanceTierSection
                    
                    // Installation Steps
                    installationStepsSection
                    
                    // Quick Start Actions
                    quickStartSection
                    
                    // Tips and Best Practices
                    tipsSection
                }
                .padding()
            }
            .navigationTitle("Shortcuts Setup")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingDetailedInstructions) {
            DetailedInstructionsView(tier: selectedTier)
                .environmentObject(shortcutsManager)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shortcuts")
                    .font(.largeTitle)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading) {
                    Text("iOS Shortcuts Integration")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Streamline message import for faster analysis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(.green)
                Text("100% on-device processing")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var performanceTierSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Analysis Depth")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(ShortcutsDataHandler.PerformanceTier.allCases, id: \.self) { tier in
                    PerformanceTierSelectionCard(
                        tier: tier,
                        isSelected: selectedTier == tier,
                        onSelect: { selectedTier = tier }
                    )
                }
            }
        }
    }
    
    private var installationStepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Installation Steps")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(Array(installationSteps.enumerated()), id: \.offset) { index, step in
                    InstallationStepRow(
                        stepNumber: index + 1,
                        title: step,
                        isCompleted: index < currentStep,
                        isCurrent: index == currentStep
                    )
                }
            }
        }
    }
    
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Start")
                .font(.headline)
            
            VStack(spacing: 12) {
                Button(action: openShortcutsApp) {
                    HStack {
                        Image(systemName: "shortcuts")
                        Text("Open Shortcuts App")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: { showingDetailedInstructions = true }) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("View Detailed Instructions")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                }
                
                Button(action: testConnection) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Test Connection")
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tips for Best Results")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                TipRow(
                    icon: "battery.100",
                    title: "Battery Life",
                    description: "Ensure at least 50% battery for Deep analysis"
                )
                
                TipRow(
                    icon: "memorychip",
                    title: "Memory Management",
                    description: "Close other apps before running large analyses"
                )
                
                TipRow(
                    icon: "clock",
                    title: "Processing Time",
                    description: "Quick: 30s, Standard: 2-3min, Deep: 5-10min"
                )
                
                TipRow(
                    icon: "shield.lefthalf.filled",
                    title: "Privacy First",
                    description: "All processing happens on your device"
                )
            }
        }
    }
    
    private func openShortcutsApp() {
        if let url = shortcutsManager.getShortcutInstallationURL() {
            UIApplication.shared.open(url)
        }
        advanceStep()
    }
    
    private func testConnection() {
        // Simulate testing connection
        advanceStep()
    }
    
    private func advanceStep() {
        if currentStep < installationSteps.count - 1 {
            withAnimation {
                currentStep += 1
            }
        }
    }
}

struct PerformanceTierSelectionCard: View {
    let tier: ShortcutsDataHandler.PerformanceTier
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
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
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Label("\(tier.messageLimit) messages", systemImage: "message")
                        Spacer()
                        Label("\(tier.timeRangeDays) days", systemImage: "calendar")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InstallationStepRow: View {
    let stepNumber: Int
    let title: String
    let isCompleted: Bool
    let isCurrent: Bool
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : (isCurrent ? Color.blue : Color(.systemGray4)))
                    .frame(width: 32, height: 32)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.caption)
                        .fontWeight(.bold)
                } else {
                    Text("\(stepNumber)")
                        .foregroundColor(isCurrent ? .white : .secondary)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            
            Text(title)
                .font(.subheadline)
                .fontWeight(isCurrent ? .semibold : .regular)
                .foregroundColor(isCompleted ? .green : (isCurrent ? .primary : .secondary))
            
            Spacer()
            
            if isCurrent {
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct DetailedInstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var shortcutsManager: ShortcutsManager
    
    let tier: ShortcutsDataHandler.PerformanceTier
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Tier-specific information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected: \(tier.displayName)")
                            .font(.headline)
                        
                        Text(tier.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Label("\(tier.messageLimit) messages", systemImage: "message")
                            Spacer()
                            Label("\(tier.timeRangeDays) days", systemImage: "calendar")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Detailed steps
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Detailed Installation Steps")
                            .font(.headline)
                        
                        ForEach(ShortcutInstaller.InstallationStep.allCases, id: \.self) { step in
                            DetailedStepCard(step: step)
                        }
                    }
                    
                    // Troubleshooting
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Common Issues")
                            .font(.headline)
                        
                        ForEach(ShortcutInstaller.TroubleshootingIssue.allCases.prefix(3), id: \.self) { issue in
                            TroubleshootingCard(issue: issue, shortcutsManager: shortcutsManager)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Setup Guide")
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

struct DetailedStepCard: View {
    let step: ShortcutInstaller.InstallationStep
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(step.title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(step.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(step.instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top) {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(instruction)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.leading, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct TroubleshootingCard: View {
    let issue: ShortcutInstaller.TroubleshootingIssue
    let shortcutsManager: ShortcutsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(issue.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
            
            Text(issue.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let firstSolution = issue.solutions.first {
                Text("Quick fix: \(firstSolution)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    ShortcutInstallationGuide()
        .environmentObject(ShortcutsManager())
}