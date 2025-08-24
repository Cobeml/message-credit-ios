//
//  LoadingView.swift
//  message-credit
//
//  Created by Claude on 8/24/25.
//

import SwiftUI

struct LoadingView: View {
    @State private var rotationAngle: Double = 0
    @State private var scale: Double = 1.0
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated loading icon
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 4)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [.white, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(Angle(degrees: rotationAngle))
                        .animation(
                            Animation.linear(duration: 2)
                                .repeatForever(autoreverses: false),
                            value: rotationAngle
                        )
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .scaleEffect(scale)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: scale
                        )
                }
                
                VStack(spacing: 16) {
                    Text("Analyzing Your Messages")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Processing personality traits and trustworthiness indicators securely on your device")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.white.opacity(0.6))
                                .frame(width: 8, height: 8)
                                .scaleEffect(scale)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(0.2 * Double(index)),
                                    value: scale
                                )
                        }
                    }
                    
                    Text("Please wait while we ensure your privacy...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
        }
        .onAppear {
            rotationAngle = 360
            scale = 0.8
        }
    }
}

#Preview {
    LoadingView()
}