import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: – Main View orchestrating all three tests, with slide screens
// ─────────────────────────────────────────────────────────────────────────────
struct ReactionGameView: View {
    // which slide we’re on (0 = no slide; 1,2,3 = “Test 1/3” … “Test 3/3”)
    @State private var slidePhase: Int       = 0

    // which screen is active
    @State private var showStartScreen       = true
    @State private var showReflexDotGame     = false
    @State private var showOptokineticTest   = false

    // reaction-time game state
    @State private var targetPosition: CGPoint      = .zero
    @State private var lastPosition: CGPoint        = .zero
    @State private var deltaX: CGFloat              = 0
    @State private var deltaY: CGFloat              = 0
    @State private var totalDeltaX: CGFloat         = 0
    @State private var totalDeltaY: CGFloat         = 0
    @State private var finalHitPercentage: Double   = 0
    @State private var reactionTime: TimeInterval   = 0
    @State private var totalReactionTime: TimeInterval = 0
    @State private var targetAppearedTime: Date?
    @State private var attemptCount: Int            = 0

    private let maxAttempts: Int           = 5
    private let blueDotSize: CGFloat       = 100
    private let redDotSize: CGFloat        = 20

    private var averageReactionTime: TimeInterval {
        guard attemptCount > 0 else { return 0 }
        return totalReactionTime / Double(attemptCount)
    }
    private var averageDeltaX: CGFloat {
        guard attemptCount > 0 else { return 0 }
        return totalDeltaX / CGFloat(attemptCount)
    }
    private var averageDeltaY: CGFloat {
        guard attemptCount > 0 else { return 0 }
        return totalDeltaY / CGFloat(attemptCount)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ─── SLIDE SCREEN ───────────────────────────────────────
                if slidePhase > 0 {
                    Color.white.ignoresSafeArea()
                    Text("Test \(slidePhase)/3")
                        .font(.largeTitle)
                        .foregroundColor(.black)
                        .onAppear {
                            // after 3s, hide slide and jump to the appropriate next test
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                slidePhase = 0
                                switch slidePhase {
                                case 1: showStartScreen = true
                                case 2: showReflexDotGame = true
                                case 3: showOptokineticTest = true
                                default: break
                                }
                            }
                        }

                // ─── 1) Start Screen ────────────────────────────────────
                } else if showStartScreen {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("Reaction Time Game")
                            .font(.largeTitle)
                            .foregroundColor(.white)

                        Text("""
                            When the blue circle appears, gaze at it and pinch to tap as quickly as you can. \
                            You will get \(maxAttempts) attempts. After that, you’ll be tested on your reflexes.
                            """)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()

                        Button("Start Game") {
                            // reset
                            attemptCount      = 0
                            reactionTime      = 0
                            totalReactionTime = 0
                            deltaX            = 0
                            deltaY            = 0
                            totalDeltaX       = 0
                            totalDeltaY       = 0
                            finalHitPercentage = 0
                            lastPosition      = .zero

                            // first slide → test 1/3
                            showStartScreen = false
                            slidePhase = 1
                            // onAppear of that slide will flip showStartScreen back
                        }
                        .font(.title2)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .frame(width: geo.size.width * 0.8)
                    .position(x: geo.size.width/2, y: geo.size.height/2)

                // ─── 2) Reaction-Time Gameplay ───────────────────────────
                } else if attemptCount < maxAttempts
                         && !showReflexDotGame
                         && !showOptokineticTest
                {
                    Color.black.ignoresSafeArea()
                    // fixed red dot
                    Circle()
                        .fill(Color.red)
                        .frame(width: redDotSize, height: redDotSize)
                        .position(x: geo.size.width/2, y: geo.size.height/2)

                    // moving blue target
                    Circle()
                        .fill(Color.blue)
                        .frame(width: blueDotSize, height: blueDotSize)
                        .position(targetPosition)
                        .onAppear { spawnTarget(in: geo.size) }
                        .focusable(true)
                        .onTapGesture {
                            guard let appear = targetAppearedTime else { return }
                            reactionTime = Date().timeIntervalSince(appear)
                            totalReactionTime += reactionTime
                            attemptCount += 1

                            if attemptCount < maxAttempts {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    reactionTime = 0
                                    spawnTarget(in: geo.size)
                                }
                            } else {
                                // between test 1→2: show “Test 2/3”
                                showReflexDotGame = false
                                slidePhase = 2
                            }
                        }

                    // stats overlay
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
                    .position(x: geo.size.width/2, y: 50)

                // ─── 3) Reflex-Dot Game ──────────────────────────────────
                } else if showReflexDotGame {
                    ReflexDotGameView(
                        isShowing: $showReflexDotGame,
                        hitPercentageHandler: { pct in finalHitPercentage = pct }
                    )
                    .onDisappear {
                        // between test 2→3: show “Test 3/3”
                        slidePhase = 3
                    }

                // ─── 4) Optokinetic Test ─────────────────────────────────
                } else if showOptokineticTest {
                    OptokineticTestView(isShowing: $showOptokineticTest)

                // ─── 5) Final End Screen ─────────────────────────────────
                } else {
                    Color.black.ignoresSafeArea()
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

                        Text("Average Δx: \(averageDeltaX, specifier: "%.0f")")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text("Average Δy: \(averageDeltaY, specifier: "%.0f")")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text("Dot Hit Accuracy: \(finalHitPercentage, specifier: "%.0f")%")
                            .font(.title2)
                            .foregroundColor(.blue)

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
                    .frame(width: geo.size.width * 0.8)
                    .position(x: geo.size.width/2, y: geo.size.height/2)
                }
            }
        }
    }

    /// spawn a new blue dot away from center
    private func spawnTarget(in size: CGSize) {
        guard attemptCount < maxAttempts else { return }
        lastPosition = targetPosition
        let pad: CGFloat = 50
        let center = CGPoint(x: size.width/2, y: size.height/2)
        let minDist = (redDotSize + blueDotSize)/2

        var x: CGFloat, y: CGFloat
        repeat {
            x = CGFloat.random(in: pad...(size.width - pad))
            y = CGFloat.random(in: pad...(size.height - pad))
        } while hypot(x - center.x, y - center.y) < minDist

        targetPosition     = CGPoint(x: x, y: y)
        deltaX             = x - lastPosition.x
        deltaY             = y - lastPosition.y
        totalDeltaX       += abs(deltaX)
        totalDeltaY       += abs(deltaY)
        targetAppearedTime = Date()
    }
}

// … your ReflexDotGameView and OptokineticTestView remain unchanged …


