import SwiftUI

struct ReactionGameView: View {
    // MARK: – Screen toggles
    @State private var showStartScreen = true
    @State private var showFixationTest = false
    @State private var showStarGame = false

    // MARK: – Game state
    @State private var targetPosition: CGPoint = .zero
    @State private var lastPosition: CGPoint = .zero
    @State private var deltaX: CGFloat = 0
    @State private var deltaY: CGFloat = 0
    @State private var reactionTime: TimeInterval = 0
    @State private var totalReactionTime: TimeInterval = 0
    @State private var targetAppearedTime: Date?
    @State private var attemptCount: Int = 0
    @State private var fixationPhase = 0 // 0=center wait, 1=slow move, 2=fast move
    @State private var redDotX: CGFloat = 0.0

    // MARK: – Star game state
    @State private var starPosition: CGPoint = .zero
    @State private var starTaps = 0

    private let maxAttempts = 5
    private let blueDotSize: CGFloat = 100
    private let redDotSize: CGFloat = 20
    private let starSize: CGFloat = 80
    private var averageReactionTime: TimeInterval {
        guard attemptCount > 0 else { return 0 }
        return totalReactionTime / Double(attemptCount)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                if showStartScreen {
                    // ───── Start Screen ─────
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
                            attemptCount = 0
                            reactionTime = 0
                            totalReactionTime = 0
                            deltaX = 0
                            deltaY = 0
                            lastPosition = .zero
                            showStartScreen = false
                            showFixationTest = true
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

                } else if showFixationTest {
                    // ───── Fixation Test ─────
                    Circle()
                        .fill(Color.red)
                        .frame(width: 50, height: 50)
                        .position(x: redDotX, y: geometry.size.height / 2)
                        .onAppear {
                            redDotX = geometry.size.width / 2

                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                fixationPhase = 1
                                animateFixationDot(width: geometry.size.width, duration: 13) {
                                    fixationPhase = 2
                                    animateFixationDot(width: geometry.size.width, duration: 5) {
                                        showFixationTest = false
                                        spawnTarget(in: geometry.size)
                                    }
                                }
                            }
                        }

                } else if attemptCount < maxAttempts {
                    // ───── Gameplay ─────
                    Circle()
                        .fill(Color.red)
                        .frame(width: redDotSize, height: redDotSize)
                        .position(x: geometry.size.width / 2,
                                  y: geometry.size.height / 2)

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
                            reactionTime = Date().timeIntervalSince(appear)
                            totalReactionTime += reactionTime
                            attemptCount += 1

                            if attemptCount < maxAttempts {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    reactionTime = 0
                                    spawnTarget(in: geometry.size)
                                }
                            }
                        }

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

                } else if showStarGame {
                    // ───── Star Game ─────
                    Image(systemName: "star.fill")
                        .resizable()
                        .frame(width: starSize, height: starSize)
                        .foregroundColor(.yellow)
                        .position(starPosition)
                        .onAppear {
                            moveStar(in: geometry.size)
                        }
                        .onTapGesture {
                            starTaps += 1
                            if starTaps < 3 {
                                moveStar(in: geometry.size)
                            } else {
                                showStarGame = false
                                showStartScreen = true
                            }
                        }

                } else {
                    // ───── End Screen ─────
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

                        Button("Continue") {
                            starTaps = 0
                            showStarGame = true
                        }
                        .font(.title2)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.purple)
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

    // MARK: – Fixation Dot Animation
    private func animateFixationDot(width: CGFloat, duration: TimeInterval, completion: @escaping () -> Void) {
        let gap: CGFloat = 20
        let left = gap
        let right = width - gap
        let center = width / 2
        let segment = duration / 3

        withAnimation(.easeInOut(duration: segment)) {
            redDotX = right
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + segment) {
            withAnimation(.easeInOut(duration: segment)) {
                redDotX = left
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + segment) {
                withAnimation(.easeInOut(duration: segment)) {
                    redDotX = center
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + segment) {
                    completion()
                }
            }
        }
    }

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

    private func moveStar(in size: CGSize) {
        let pad: CGFloat = 80
        let x = CGFloat.random(in: pad...(size.width - pad))
        let y = CGFloat.random(in: pad...(size.height - pad))
        starPosition = CGPoint(x: x, y: y)
    }
}

struct ReactionGameView_Previews: PreviewProvider {
    static var previews: some View {
        ReactionGameView()
    }
}
