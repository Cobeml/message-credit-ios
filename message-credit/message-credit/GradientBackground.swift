//
//  GradientBackground.swift
//  message-credit
//
//  Created by Claude on 8/24/25.
//

import SwiftUI

struct GradientBackground: View {
    var body: some View {
        Rectangle()
            .fill(
                RadialGradient(
                    stops: [
                        Gradient.Stop(color: Color(red: 0.58, green: 0.81, blue: 1), location: 0.0),
                        Gradient.Stop(color: Color(red: 0.5, green: 0.25, blue: 0.83), location: 0.3),
                        Gradient.Stop(color: Color(red: 0.2, green: 0.1, blue: 0.51), location: 0.7),
                        Gradient.Stop(color: Color(red: 0, green: 0.01, blue: 0.08), location: 1.0),
                    ],
                    center: UnitPoint(x: 0.5, y: 0.1),
                    startRadius: 0,
                    endRadius: 800
                )
            )
            .ignoresSafeArea()
    }
}

#Preview {
    GradientBackground()
}