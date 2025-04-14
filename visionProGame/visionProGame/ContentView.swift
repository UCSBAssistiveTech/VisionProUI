//
//  ContentView.swift
//  visionProGame
//
//  Created by Srihari Prazid on 4/13/25.
//

import SwiftUI

/// A SwiftUI view that simulates a reaction time game.
/// In a real Vision Pro application, you would replace `.onHover` with the actual eye-tracking API callbacks.
struct ReactionGameView: View {
    // Position of the target on screen.
    @State private var targetPosition: CGPoint = .zero
    // Reaction time measured in seconds.
    @State private var reactionTime: TimeInterval = 0
    // Timestamp when the target appeared.
    @State private var targetAppearedTime: Date?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background color.
                Color.black.ignoresSafeArea()
                
                // The target: a red circle.
                Circle()
                    .fill(Color.red)
                    .frame(width: 50, height: 50)
                    .position(targetPosition)
                    .onAppear {
                        // Start the game by spawning the first target.
                        spawnTarget(in: geometry.size)
                    }
                    // Here, .onHover acts as a stand-in for detecting when the user's gaze lands on the target.
                    .onHover { isHovering in
                        // When the "gaze" is on the target and we have a recorded appearance time...
                        if isHovering, let appearTime = targetAppearedTime {
                            // Calculate the reaction time.
                            reactionTime = Date().timeIntervalSince(appearTime)
                            print("Reaction time: \(reactionTime) seconds")
                            
                            // For visual feedback, the reaction time is displayed at the top.
                            // Spawn a new target after a short delay.
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                reactionTime = 0
                                spawnTarget(in: geometry.size)
                            }
                        }
                    }
                
                // Display the reaction time on-screen.
                if reactionTime > 0 {
                    Text("Reaction: \(reactionTime, specifier: "%.2f") s")
                        .font(.title)
                        .foregroundColor(.white)
                        .position(x: geometry.size.width / 2, y: 50)
                }
            }
        }
    }
    
    /// Spawns the target at a random location within the given size.
    private func spawnTarget(in size: CGSize) {
        let padding: CGFloat = 50
        let randomX = CGFloat.random(in: padding...(size.width - padding))
        let randomY = CGFloat.random(in: padding...(size.height - padding))
        targetPosition = CGPoint(x: randomX, y: randomY)
        targetAppearedTime = Date()
    }
}

struct ReactionGameView_Previews: PreviewProvider {
    static var previews: some View {
        ReactionGameView()
    }
}

