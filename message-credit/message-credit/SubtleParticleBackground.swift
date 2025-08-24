//
//  SubtleParticleBackground.swift
//  message-credit
//
//  Created by Claude on 8/24/25.
//

import SwiftUI

struct SubtleParticleBackground: View {
    @State private var particles: [Particle] = []
    @State private var timer: Timer?
    
    let maxParticles = 15
    
    var body: some View {
        ZStack {
            // Base gradient background
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating particles
            GeometryReader { geometry in
                ForEach(particles) { particle in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    particle.color.opacity(0.6),
                                    particle.color.opacity(0.3),
                                    particle.color.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: particle.size / 2
                            )
                        )
                        .frame(width: particle.size, height: particle.size)
                        .position(x: particle.x, y: particle.y)
                        .blur(radius: 2.0)
                        .animation(.linear(duration: particle.speed), value: particle.y)
                }
            }
        }
        .onAppear {
            startParticleSystem()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startParticleSystem() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            if particles.count < maxParticles {
                addParticle()
            }
            updateParticles()
        }
    }
    
    private func addParticle() {
        let newParticle = Particle(
            id: UUID(),
            x: Double.random(in: 0...UIScreen.main.bounds.width),
            y: UIScreen.main.bounds.height + 50,
            size: Double.random(in: 8...25),
            color: [Color.cyan.opacity(0.4), Color.blue.opacity(0.3), Color.white.opacity(0.2)].randomElement() ?? Color.white.opacity(0.2),
            speed: Double.random(in: 15...35)
        )
        
        withAnimation(.linear(duration: newParticle.speed)) {
            particles.append(newParticle)
        }
    }
    
    private func updateParticles() {
        particles = particles.compactMap { particle in
            var updatedParticle = particle
            updatedParticle.y -= 2.0 // Slow upward movement
            updatedParticle.x += sin(Date().timeIntervalSinceReferenceDate + particle.id.hashValue.d) * 0.5 // Gentle side-to-side drift
            
            // Remove particles that have moved off screen
            if updatedParticle.y < -50 {
                return nil
            }
            
            return updatedParticle
        }
    }
}

struct Particle: Identifiable {
    let id: UUID
    var x: Double
    var y: Double
    let size: Double
    let color: Color
    let speed: Double
}

// Helper extension for converting hash to double
extension Int {
    var d: Double {
        return Double(self)
    }
}

#Preview {
    SubtleParticleBackground()
}