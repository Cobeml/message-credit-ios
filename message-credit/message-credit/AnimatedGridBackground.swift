//
//  AnimatedGridBackground.swift
//  message-credit
//
//  Created by Claude on 8/24/25.
//

import SwiftUI

struct AnimatedGridBackground: View {
    @State private var animationOffset: CGFloat = 0
    @State private var glowIntensity: Double = 0.5
    
    let gridSize: Int = 20
    let lineWidth: CGFloat = 1.0
    let animationSpeed: Double = 2.0
    
    var body: some View {
        ZStack {
            // Base gradient background
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 3D Grid layers
            ZStack {
                // Back grid layer (smaller perspective)
                gridLayer(scale: 0.6, opacity: 0.2, offset: animationOffset * 0.5)
                
                // Middle grid layer
                gridLayer(scale: 0.8, opacity: 0.4, offset: animationOffset * 0.7)
                
                // Front grid layer (full size)
                gridLayer(scale: 1.0, opacity: 0.6, offset: animationOffset)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func gridLayer(scale: CGFloat, opacity: Double, offset: CGFloat) -> some View {
        Canvas { context, size in
            drawGrid(context: context, size: size, scale: scale, opacity: opacity, offset: offset)
        }
        .blur(radius: scale < 1.0 ? 2.0 * (1.0 - scale) : 0)
    }
    
    private func drawGrid(context: GraphicsContext, size: CGSize, scale: CGFloat, opacity: Double, offset: CGFloat) {
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Calculate grid spacing
        let spacingX = scaledSize.width / CGFloat(gridSize)
        let spacingY = scaledSize.height / CGFloat(gridSize)
        
        // Create perspective transformation
        let startX = centerX - scaledSize.width / 2
        let startY = centerY - scaledSize.height / 2
        
        // Draw vertical lines
        for i in 0...gridSize {
            let x = startX + CGFloat(i) * spacingX
            
            // Calculate line positions with trickling effect
            let lineOffset = (offset + CGFloat(i) * 10).truncatingRemainder(dividingBy: scaledSize.height + 100)
            
            // Create multiple flowing segments per line
            for segment in 0..<3 {
                let segmentOffset = lineOffset + CGFloat(segment) * (scaledSize.height / 3)
                let segmentY = segmentOffset - 50
                let segmentHeight: CGFloat = 80
                
                if segmentY < scaledSize.height + startY && segmentY + segmentHeight > startY {
                    let path = Path { path in
                        path.move(to: CGPoint(x: x, y: max(startY, segmentY)))
                        path.addLine(to: CGPoint(x: x, y: min(startY + scaledSize.height, segmentY + segmentHeight)))
                    }
                    
                    // Create glowing effect
                    let glowColor = Color.cyan.opacity(opacity * glowIntensity)
                    
                    // Draw glow layers
                    context.stroke(path, with: .color(glowColor), style: StrokeStyle(lineWidth: lineWidth * 3))
                    context.stroke(path, with: .color(glowColor.opacity(0.8)), style: StrokeStyle(lineWidth: lineWidth * 2))
                    context.stroke(path, with: .color(.white.opacity(opacity)), style: StrokeStyle(lineWidth: lineWidth))
                }
            }
        }
        
        // Draw horizontal lines
        for i in 0...gridSize {
            let y = startY + CGFloat(i) * spacingY
            
            // Calculate line positions with trickling effect
            let lineOffset = (offset * 0.7 + CGFloat(i) * 8).truncatingRemainder(dividingBy: scaledSize.width + 100)
            
            // Create multiple flowing segments per line
            for segment in 0..<2 {
                let segmentOffset = lineOffset + CGFloat(segment) * (scaledSize.width / 2)
                let segmentX = segmentOffset - 40
                let segmentWidth: CGFloat = 60
                
                if segmentX < scaledSize.width + startX && segmentX + segmentWidth > startX {
                    let path = Path { path in
                        path.move(to: CGPoint(x: max(startX, segmentX), y: y))
                        path.addLine(to: CGPoint(x: min(startX + scaledSize.width, segmentX + segmentWidth), y: y))
                    }
                    
                    // Create glowing effect
                    let glowColor = Color.blue.opacity(opacity * glowIntensity * 0.7)
                    
                    // Draw glow layers
                    context.stroke(path, with: .color(glowColor), style: StrokeStyle(lineWidth: lineWidth * 3))
                    context.stroke(path, with: .color(glowColor.opacity(0.8)), style: StrokeStyle(lineWidth: lineWidth * 2))
                    context.stroke(path, with: .color(.white.opacity(opacity * 0.6)), style: StrokeStyle(lineWidth: lineWidth))
                }
            }
        }
        
        // Add diagonal perspective lines for 3D effect
        let diagonalCount = 8
        for i in 0..<diagonalCount {
            let progress = CGFloat(i) / CGFloat(diagonalCount - 1)
            let diagonalOffset = (offset * 0.5 + progress * 50).truncatingRemainder(dividingBy: 300)
            
            let startPoint = CGPoint(
                x: startX + progress * scaledSize.width * 0.3,
                y: startY + diagonalOffset - 100
            )
            let endPoint = CGPoint(
                x: startX + scaledSize.width - progress * scaledSize.width * 0.3,
                y: startY + scaledSize.height + diagonalOffset - 100
            )
            
            if startPoint.y < startY + scaledSize.height && endPoint.y > startY {
                let path = Path { path in
                    path.move(to: startPoint)
                    path.addLine(to: endPoint)
                }
                
                let glowColor = Color.purple.opacity(opacity * glowIntensity * 0.5)
                context.stroke(path, with: .color(glowColor), style: StrokeStyle(lineWidth: lineWidth * 2))
                context.stroke(path, with: .color(.white.opacity(opacity * 0.3)), style: StrokeStyle(lineWidth: lineWidth * 0.5))
            }
        }
    }
    
    private func startAnimation() {
        // Continuous downward animation
        withAnimation(.linear(duration: animationSpeed).repeatForever(autoreverses: false)) {
            animationOffset = 1000
        }
        
        // Pulsing glow effect
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
        }
    }
}

#Preview {
    AnimatedGridBackground()
}