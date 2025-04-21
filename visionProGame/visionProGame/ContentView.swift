import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: – Main View orchestrating all three tests
// ─────────────────────────────────────────────────────────────────────────────
struct ReactionGameView: View {
    // which screen is active
    @State private var showStartScreen     = true
    @State private var showReflexDotGame   = false
    @State private var showOptokineticTest = false

    // reaction‑time game state
    @State private var targetPosition: CGPoint = .zero
    @State private var lastPosition: CGPoint   = .zero
    @State private var deltaX: CGFloat         = 0
    @State private var deltaY: CGFloat         = 0
    @State private var reactionTime: TimeInterval = 0
    @State private var totalReactionTime: TimeInterval = 0
    @State private var targetAppearedTime: Date?
    @State private var attemptCount: Int       = 0

    private let maxAttempts   = 5
    private let blueDotSize: CGFloat = 100
    private let redDotSize:  CGFloat = 20

    private var averageReactionTime: TimeInterval {
        guard attemptCount > 0 else { return 0 }
        return totalReactionTime / Double(attemptCount)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                // ─── 1) Start Screen ─────────────────────────────────────
                if showStartScreen {
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
                            // reset reaction game
                            attemptCount      = 0
                            reactionTime      = 0
                            totalReactionTime = 0
                            deltaX            = 0
                            deltaY            = 0
                            lastPosition      = .zero
                            showStartScreen   = false
                            spawnTarget(in: geo.size)
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

                // ─── 2) Reaction‑Time Gameplay ───────────────────────────
                } else if attemptCount < maxAttempts
                         && !showReflexDotGame
                         && !showOptokineticTest
                {
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
                        .onAppear {
                            spawnTarget(in: geo.size)
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
                                    spawnTarget(in: geo.size)
                                }
                            } else {
                                // go to reflex‑dot game
                                showReflexDotGame = true
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

                // ─── 3) Reflex‑Dot Game ───────────────────────────────────
                } else if showReflexDotGame {
                    ReflexDotGameView(isShowing: $showReflexDotGame)
                        .onChange(of: showReflexDotGame) { stillShowing in
                            // when user taps Finish, launch optokinetic
                            if !stillShowing {
                                showOptokineticTest = true
                            }
                        }

                // ─── 4) Optokinetic Test ──────────────────────────────────
                } else if showOptokineticTest {
                    OptokineticTestView(isShowing: $showOptokineticTest)

                // ─── 5) Final End Screen ──────────────────────────────────
                } else {
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
        targetAppearedTime = Date()
    }
}


// ─────────────────────────────────────────────────────────────────────────────
// MARK: – Reflex‑Dot Game (unchanged logic)
// ─────────────────────────────────────────────────────────────────────────────
struct ReflexDotGameView: View {
    @Binding var isShowing: Bool

    private let totalCircles = 5
    private let maxCycles     = 3
    private let speedUpFactor : Double = 0.95
    private let initialDelay  : Double = 1.0

    @State private var currentDelay   : Double = 1.0
    @State private var highlightedIndex = 0
    @State private var forward       = true
    @State private var hitCount      = 0
    @State private var missCount     = 0
    @State private var cycleCount    = 0
    @State private var isRunning     = true

    var body: some View {
        VStack(spacing: 30) {
            Text("Tap the red circle!")
                .font(.title)
                .foregroundColor(.white)

            Text("Hit Rate: \(hitPercentage, specifier: "%.0f")%")
                .font(.headline)
                .foregroundColor(.yellow)

            HStack(spacing: 30) {
                ForEach(0..<totalCircles, id: \.self) { i in
                    Circle()
                        .fill(i == highlightedIndex ? .red : .gray)
                        .frame(width: 100, height: 100)
                        .scaleEffect(i == highlightedIndex ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 0.2), value: highlightedIndex)
                        .onTapGesture {
                            if i == highlightedIndex {
                                hitCount += 1
                            } else {
                                missCount += 1
                            }
                        }
                }
            }

            if !isRunning {
                Button("Finish") {
                    isShowing = false
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .onAppear {
            currentDelay = initialDelay
            startHighlighting()
        }
        .background(Color.black.ignoresSafeArea())
    }

    private var hitPercentage: Double {
        let total = hitCount + missCount
        return total == 0 ? 0 : Double(hitCount) / Double(total) * 100
    }

    private func startHighlighting() {
        Timer.scheduledTimer(withTimeInterval: currentDelay, repeats: false) { _ in
            guard isRunning else { return }

            if forward {
                highlightedIndex += 1
                if highlightedIndex == totalCircles - 1 {
                    forward = false
                    cycleCount += 1
                }
            } else {
                highlightedIndex -= 1
                if highlightedIndex == 0 {
                    forward = true
                    cycleCount += 1
                }
            }

            if cycleCount >= maxCycles {
                isRunning = false
                return
            }

            currentDelay *= speedUpFactor
            startHighlighting()
        }
    }
}


// ─────────────────────────────────────────────────────────────────────────────
// MARK: – Optokinetic Test View
// ─────────────────────────────────────────────────────────────────────────────
struct OptokineticTestView: View {
    @Binding var isShowing: Bool
    @State private var phase: Int = 0
    @State private var offset: CGFloat = 0
    @State private var stripes: [CGFloat] = []

    // larger red dot (~fixation size)
    let redDotSize: CGFloat = 40

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if phase == 0 {
                Text("Optokinetic")
                    .font(.largeTitle)
                    .foregroundColor(.black)
                    .onAppear {
                        // show label for 2s
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            phase = 1
                        }
                    }

            } else {
                GeometryReader { geo in
                    ZStack {
                        // darker gray barcode strips
                        HStack(spacing: 20) {
                            ForEach(stripes.indices, id: \.self) { i in
                                Rectangle()
                                    .fill(Color(.darkGray))
                                    .frame(width: stripes[i], height: geo.size.height)
                            }
                        }
                        .offset(x: offset)
                        .onAppear {
                            let totalW = geo.size.width * 2
                            stripes = generateStripes(totalWidth: totalW)
                            offset = 0
                            // slide two screen‐widths in 7s
                            withAnimation(.linear(duration: 7)) {
                                offset = -2 * geo.size.width
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                                isShowing = false
                            }
                        }

                        // larger red dot centered
                        Circle()
                            .fill(Color.red)
                            .frame(width: redDotSize, height: redDotSize)
                            .position(x: geo.size.width/2, y: geo.size.height/2)
                    }
                }
            }
        }
    }

    private func generateStripes(totalWidth: CGFloat) -> [CGFloat] {
        var arr: [CGFloat] = []
        var sum: CGFloat = 0
        while sum < totalWidth {
            let w = CGFloat.random(in: 20...80)
            arr.append(w)
            sum += w + 20
        }
        return arr
    }
}


// ─────────────────────────────────────────────────────────────────────────────
// MARK: – Preview
// ─────────────────────────────────────────────────────────────────────────────
struct ReactionGameView_Previews: PreviewProvider {
    static var previews: some View {
        ReactionGameView()
    }
}
