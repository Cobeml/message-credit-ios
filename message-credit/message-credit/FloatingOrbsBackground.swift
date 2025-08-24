//
//  FloatingOrbsBackground.swift
//  message-credit
//
//  Created by Claude on 8/24/25.
//

import SwiftUI

struct FloatingOrbsBackground: View {
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: Double = 1.0
    
    var body: some View {
        ZStack {
            // Base gradient background
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GeometryReader { geometry in
                ZStack {
                    // Large floating orb - top left quadrant
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.cyan.opacity(0.3),
                                    Color.blue.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .blur(radius: 20)
                        .offset(
                            x: -geometry.size.width * 0.4 + sin(rotationAngle * 0.5) * 30,
                            y: -geometry.size.height * 0.3 + cos(rotationAngle * 0.3) * 20
                        )
                    
                    // Medium floating orb - top right quadrant
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.purple.opacity(0.25),
                                    Color.indigo.opacity(0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .blur(radius: 15)
                        .offset(
                            x: geometry.size.width * 0.35 + cos(rotationAngle * 0.4) * 25,
                            y: -geometry.size.height * 0.2 + sin(rotationAngle * 0.6) * 15
                        )
                    
                    // Small floating orb - bottom left quadrant
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.mint.opacity(0.4),
                                    Color.teal.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .blur(radius: 12)
                        .scaleEffect(pulseScale)
                        .offset(
                            x: -geometry.size.width * 0.3 + cos(rotationAngle * 0.7) * 20,
                            y: geometry.size.height * 0.3 + sin(rotationAngle * 0.4) * 25
                        )
                    
                    // Medium-small floating orb - bottom right quadrant
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.pink.opacity(0.2),
                                    Color.purple.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                        .blur(radius: 18)
                        .offset(
                            x: geometry.size.width * 0.4 + sin(rotationAngle * 0.3) * 35,
                            y: geometry.size.height * 0.25 + cos(rotationAngle * 0.5) * 30
                        )
                    
                    // Tiny accent orb - center floating
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.cyan.opacity(0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 8)
                        .scaleEffect(pulseScale * 0.8)
                        .offset(
                            x: sin(rotationAngle * 0.8) * 50,
                            y: cos(rotationAngle * 0.6) * 40
                        )
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Continuous rotation animation for orbital movement
        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // Gentle pulsing animation
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            pulseScale = 1.2
        }
    }
}

#Preview {
    FloatingOrbsBackground()
}