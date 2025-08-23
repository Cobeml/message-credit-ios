import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "shield.checkered")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Privacy Credit Analyzer")
                .font(.title)
            Text("Secure on-device credit analysis")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}