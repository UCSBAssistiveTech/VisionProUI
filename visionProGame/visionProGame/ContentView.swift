import SwiftUI

struct ReactionGameView: View {
    // ── State flags
    @State private var showStartScreen       = true
    @State private var showReflexDotGame     = false
    @State private var showOptokineticTest   = false

    // ── Reaction‑time game state
    @State private var targetPosition: CGPoint?
    @State private var lastPosition: CGPoint = .zero
    @State private var deltaX: CGFloat = 0
    @State private var deltaY: CGFloat = 0
    @State private var reactionTime: TimeInterval = 0
    @State private var totalReactionTime: TimeInterval = 0
    @State private var targetAppearedTime: Date?
    @State private var attemptCount: Int = 0

    private let maxAttempts   = 5
    private let blueDotSize  : CGFloat = 100
    private let redDotSize    : CGFloat = 20

    private var averageReactionTime: TimeInterval {
        guard attemptCount > 0 else { return 0 }
        return totalReactionTime / Double(attemptCount)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                // ───── 1) Start Screen ─────────────────────────────────────
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
                            // reset everything
                            attemptCount        = 0
                            reactionTime        = 0
                            totalReactionTime   = 0
                            deltaX              = 0
                            deltaY              = 0
                            lastPosition        = .zero
                            showStartScreen     = false
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

                // ───── 2) Reaction‑time gameplay ───────────────────────────
                } else if attemptCount < maxAttempts && !showReflexDotGame && !showOptokineticTest {
                    // red fixation dot
                    Circle()
                        .fill(Color.red)
                        .frame(width: redDotSize, height: redDotSize)
                        .position(x: geo.size.width/2, y: geo.size.height/2)

                    // blue target
                    if let pos = targetPosition {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: blueDotSize, height: blueDotSize)
                            .position(pos)
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
                                    // finished reaction game → go to reflex dot
                                    showReflexDotGame = true
                                }
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

                // ───── 3) Reflex‑dot game ────────────────────────────────────
                } else if showReflexDotGame {
                    ReflexDotGameView(isShowing: $showReflexDotGame)
                        .onChange(of: showReflexDotGame) { stillShowing in
                            // user tapped Finish → start optokinetic
                            if !stillShowing {
                                showOptokineticTest = true
                            }
                        }

                // ───── 4) Optokinetic test ─────────────────────────────────
                } else if showOptokineticTest {
                    OptokineticTestView(isShowing: $showOptokineticTest)

                // ───── 5) Final end screen ─────────────────────────────────
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

    // ── picks a new random blue‐dot
    private func spawnTarget(in size: CGSize) {
        guard attemptCount < maxAttempts else { return }
        lastPosition = targetPosition ?? .zero
        let pad : CGFloat = 50
        let center = CGPoint(x: size.width/2, y: size.height/2)
        let minDist = (redDotSize+blueDotSize)/2

        var x,y: CGFloat
        repeat {
            x = CGFloat.random(in: pad...(size.width-pad))
            y = CGFloat.random(in: pad...(size.height-pad))
        } while hypot(x-center.x, y-center.y) < minDist

        targetPosition     = CGPoint(x: x, y: y)
        deltaX             = x - lastPosition.x
        deltaY             = y - lastPosition.y
        targetAppearedTime = Date()
    }
}

// ─────────────────── your existing ReflexDotGameView ─────────────
// (unchanged)

struct ReflexDotGameView: View {
    @Binding var isShowing: Bool
    // … your logic here …
}

// ─────────────────── your OptokineticTestView ─────────────────────
// (make sure this is in the same file or imported)

struct OptokineticTestView: View {
    @Binding var isShowing: Bool
    @State private var phase: Int   = 0
    @State private var offset: CGFloat = 0
    @State private var stripes: [CGFloat] = []

    let redDotSize: CGFloat = 40

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if phase == 0 {
                Text("Optokinetic")
                    .font(.largeTitle)
                    .foregroundColor(.black)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            phase = 1
                        }
                    }

            } else {
                GeometryReader { geo in
                    ZStack {
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
                            // slide twice‐screen in 7s
                            withAnimation(.linear(duration: 7)) {
                                offset = -2 * geo.size.width
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                                isShowing = false
                            }
                        }

                        Circle()
                            .fill(Color.red)
                            .frame(width: redDotSize, height: redDotSize)
                            .position(x: geo.size.width/2,
                                      y: geo.size.height/2)
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

struct ReactionGameView_Previews: PreviewProvider {
    static var previews: some View {
        ReactionGameView()
    }
}

