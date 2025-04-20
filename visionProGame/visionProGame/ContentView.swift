import SwiftUI

struct ReactionGameView: View {
    // MARK: – Screen toggles
    @State private var showStartScreen = true

    // MARK: – Game state
    @State private var targetPosition: CGPoint = .zero
    @State private var lastPosition: CGPoint = .zero
    @State private var deltaX: CGFloat = 0
    @State private var deltaY: CGFloat = 0
    @State private var reactionTime: TimeInterval = 0
    @State private var totalReactionTime: TimeInterval = 0
    @State private var targetAppearedTime: Date?
    @State private var attemptCount: Int = 0

    private let maxAttempts = 5
    private let blueDotSize: CGFloat = 100
    private let redDotSize: CGFloat = 20
    private var averageReactionTime: TimeInterval {
        guard attemptCount > 0 else { return 0 }
        return totalReactionTime / Double(attemptCount)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                if showStartScreen {
                    // ───── Start Screen ─────────────────────────────────────
                    VStack(spacing: 20) {
                        Text("Reaction Time Game")
                            .font(.largeTitle)
                            .foregroundColor(.white)

                        Text("""
                        When the blue circle appears, gaze at it and pinch to tap as quickly as you can. \
                        You will get \(maxAttempts) attempts. After each tap, your reaction time and how \
                        far the dot moved (Δx, Δy) will be shown.
                        """)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()

                        Button("Start Game") {
                            // reset everything
                            attemptCount = 0
                            reactionTime = 0
                            totalReactionTime = 0
                            deltaX = 0
                            deltaY = 0
                            lastPosition = .zero
                            showStartScreen = false
                        }
                        .font(.title2)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .frame(width: geometry.size.width * 0.8)
                    .position(x: geometry.size.width / 2,
                              y: geometry.size.height / 2)

                } else if attemptCount < maxAttempts {
                    // ───── Gameplay ─────────────────────────────────────────
                    // Red dot fixed at center
                    Circle()
                        .fill(Color.red)
                        .frame(width: redDotSize, height: redDotSize)
                        .position(x: geometry.size.width / 2,
                                  y: geometry.size.height / 2)

                    // Blue target circle
                    Circle()
                        .fill(Color.blue)
                        .frame(width: blueDotSize, height: blueDotSize)
                        .position(targetPosition)
                        .onAppear {
                            spawnTarget(in: geometry.size)
                        }
                        .focusable(true)
                        .onTapGesture {
                            guard let appear = targetAppearedTime else { return }
                            // measure reaction
                            reactionTime = Date().timeIntervalSince(appear)
                            totalReactionTime += reactionTime
                            attemptCount += 1

                            // next round or end
                            if attemptCount < maxAttempts {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    reactionTime = 0
                                    spawnTarget(in: geometry.size)
                                }
                            }
                        }

                    // Overlay: stats
                    VStack(spacing: 6) {
                        if reactionTime > 0 {
                            Text("Reaction: \(reactionTime, specifier: "%.2f") s")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        Text("Δx: \(deltaX, specifier: "%.0f"), Δy: \(deltaY, specifier: "%.0f")")
                            .font(.body)
                            .foregroundColor(.yellow)
                    }
                    .position(x: geometry.size.width / 2, y: 50)

                } else {
                    // ───── End Screen ───────────────────────────────────────
                    VStack(spacing: 20) {
                        Text("Game Over!")
                            .font(.largeTitle)
                            .foregroundColor(.green)

                        Text("Your average reaction time:")
                            .font(.title2)
                            .foregroundColor(.white)

                        Text("\(averageReactionTime, specifier: "%.2f") s")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)

                        Button("Play Again") {
                            showStartScreen = true
                        }
                        .font(.title2)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .frame(width: geometry.size.width * 0.8)
                    .position(x: geometry.size.width / 2,
                              y: geometry.size.height / 2)
                }
            }
        }
    }

    /// Spawns a blue target at a random position, avoiding the center red dot
    private func spawnTarget(in size: CGSize) {
        guard attemptCount < maxAttempts else { return }

        lastPosition = targetPosition
        let pad: CGFloat = 50
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let redRadius = redDotSize / 2
        let blueRadius = blueDotSize / 2
        let minDistance = redRadius + blueRadius

        var newX: CGFloat
        var newY: CGFloat
        repeat {
            newX = CGFloat.random(in: pad...(size.width - pad))
            newY = CGFloat.random(in: pad...(size.height - pad))
        } while hypot(newX - center.x, newY - center.y) < minDistance

        targetPosition = CGPoint(x: newX, y: newY)
        deltaX = newX - lastPosition.x
        deltaY = newY - lastPosition.y
        targetAppearedTime = Date()
    }
}

struct ReactionGameView_Previews: PreviewProvider {
    static var previews: some View {
        ReactionGameView()
    }
}

