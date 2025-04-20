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
<<<<<<< HEAD
=======
    @State private var showFixationTest = false
    @State private var fixationPhase = 0 // 0=center wait, 1=slow move, 2=fast move
    @State private var redDotX: CGFloat = 0.0
>>>>>>> 2ee4562ca1923ab19197c15d8350be3eb771b676

    private let maxAttempts = 5
    private var averageReactionTime: TimeInterval {
        guard attemptCount > 0 else { return 0 }
        return totalReactionTime / Double(attemptCount)
    }
<<<<<<< HEAD

    // sizes for collision‑avoidance
    private let redDotDiameter: CGFloat = 40
    private let blueDotDiameter: CGFloat = 100
=======
>>>>>>> 2ee4562ca1923ab19197c15d8350be3eb771b676

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                if showStartScreen {
                    // ───── Start Screen ───────────────────────────────────────────
                    VStack(spacing: 20) {
                        Text("Reaction Time Game")
                            .font(.largeTitle)
                            .foregroundColor(.white)

                        Text("""
<<<<<<< HEAD
                            When the blue circle appears, gaze at it and pinch to tap as quickly as you can. \
=======
                            When the red circle appears, gaze at it and pinch to tap as quickly as you can. \
>>>>>>> 2ee4562ca1923ab19197c15d8350be3eb771b676
                            You will get \(maxAttempts) attempts. After each tap, your reaction time and how \
                            far the dot moved (Δx, Δy) will be shown.
                            """)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()

                        Button("Start Game") {
<<<<<<< HEAD
=======
                            // reset everything
>>>>>>> 2ee4562ca1923ab19197c15d8350be3eb771b676
                            attemptCount = 0
                            reactionTime = 0
                            totalReactionTime = 0
                            deltaX = 0
                            deltaY = 0
                            lastPosition = .zero
                            showStartScreen = false
<<<<<<< HEAD
=======
                            showFixationTest = true
>>>>>>> 2ee4562ca1923ab19197c15d8350be3eb771b676
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

<<<<<<< HEAD
                } else if attemptCount < maxAttempts {
                    // ───── Gameplay ───────────────────────────────────────────────

                    // 🔴 static red dot in center
                    Circle()
                        .fill(Color.red)
                        .frame(width: redDotDiameter, height: redDotDiameter)
                        .position(x: geometry.size.width/2,
                                  y: geometry.size.height/2)

                    // 🔵 moving blue target
                    Circle()
                        .fill(Color.blue)
                        .frame(width: blueDotDiameter, height: blueDotDiameter)
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
=======
                } else if showFixationTest {
                    // ───── Fixation Test ─────────────────────────────────────────
                    Circle()
                        .fill(Color.red)
                        .frame(width: 50, height: 50)
                        .position(x: redDotX, y: geometry.size.height / 2)
                        .onAppear {
                            redDotX = geometry.size.width / 2

                            // Phase 0: Wait 13 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 13) {
                                fixationPhase = 1
                                animateFixationDot(width: geometry.size.width, duration: 5) {
                                    fixationPhase = 2
                                    animateFixationDot(width: geometry.size.width, duration: 5) {
                                        // Done → Start reaction game
                                        showFixationTest = false
                                        spawnTarget(in: geometry.size)
                                    }
>>>>>>> 2ee4562ca1923ab19197c15d8350be3eb771b676
                                }
                            }
                        }

<<<<<<< HEAD
=======
                } else if attemptCount < maxAttempts {
                    // ───── Gameplay ───────────────────────────────────────────────
                    Circle()
                        .fill(Color.red)
                        .frame(width: 50, height: 50)
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

                            // schedule next round or end
                            if attemptCount < maxAttempts {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    reactionTime = 0
                                    spawnTarget(in: geometry.size)
                                }
                            }
                        }

>>>>>>> 2ee4562ca1923ab19197c15d8350be3eb771b676
                    // Overlay: stats during play
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
                    // ───── End Screen ─────────────────────────────────────────────
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
<<<<<<< HEAD
=======
                            // go back to start
>>>>>>> 2ee4562ca1923ab19197c15d8350be3eb771b676
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

<<<<<<< HEAD
=======
    // MARK: - Fixation Dot Animation
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

>>>>>>> 2ee4562ca1923ab19197c15d8350be3eb771b676
    private func spawnTarget(in size: CGSize) {
        guard attemptCount < maxAttempts else { return }

        let pad: CGFloat = 50
<<<<<<< HEAD
        let center = CGPoint(x: size.width/2, y: size.height/2)
        let redRadius = redDotDiameter / 2
        let blueRadius = blueDotDiameter / 2
        let minClearance = redRadius + blueRadius

        lastPosition = targetPosition

        // keep sampling until we’re far enough from the red dot
        var newPoint: CGPoint
        repeat {
            let x = CGFloat.random(in: pad...(size.width - pad))
            let y = CGFloat.random(in: pad...(size.height - pad))
            newPoint = CGPoint(x: x, y: y)
        } while hypot(newPoint.x - center.x,
                      newPoint.y - center.y) < minClearance

        targetPosition = newPoint

        deltaX = targetPosition.x - lastPosition.x
        deltaY = targetPosition.y - lastPosition.y
=======
        lastPosition = targetPosition

        let newX = CGFloat.random(in: pad...(size.width - pad))
        let newY = CGFloat.random(in: pad...(size.height - pad))
        targetPosition = CGPoint(x: newX, y: newY)

        deltaX = newX - lastPosition.x
        deltaY = newY - lastPosition.y
>>>>>>> 2ee4562ca1923ab19197c15d8350be3eb771b676

        targetAppearedTime = Date()
    }
}

struct ReactionGameView_Previews: PreviewProvider {
    static var previews: some View {
        ReactionGameView()
    }
}
