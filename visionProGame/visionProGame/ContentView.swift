import SwiftUI

struct ReactionGameView: View {
    // MARK: – Screen toggles
    @State private var showStartScreen = true
    @State private var showFixationTest = false
    @State private var showOptokineticTest = false
    @State private var showReflexDotGame = false

    // MARK: – Game state
    @State private var targetPosition: CGPoint = .zero
    @State private var lastPosition: CGPoint = .zero
    @State private var deltaX: CGFloat = 0
    @State private var deltaY: CGFloat = 0
    @State private var reactionTime: TimeInterval = 0
    @State private var totalReactionTime: TimeInterval = 0
    @State private var targetAppearedTime: Date?
    @State private var attemptCount: Int = 0
    @State private var redDotX: CGFloat = 0.0
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
                    Circle()
                        .fill(Color.red)
                        .frame(width: 50, height: 50)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                animateFixationDot(width: geometry.size.width, duration: 13) {
                                    animateFixationDot(width: geometry.size.width, duration: 5) {
                                        showFixationTest = false
                                        spawnTarget(in: geometry.size)
                                    }
                                }
                            }
                        }

                } else if attemptCount < maxAttempts && !showOptokineticTest {
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
                            } else {
                                showOptokineticTest = true
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

                } else if showOptokineticTest {
                    OptokineticTestView(isShowing: $showOptokineticTest, showReflexDotGame: $showReflexDotGame)
                        .ignoresSafeArea()

                } else if showReflexDotGame {
                    ReflexDotGameView(isShowing: $showReflexDotGame)

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
                    .frame(width: geometry.size.width * 0.8)
                    .position(x: geometry.size.width / 2,
                              y: geometry.size.height / 2)
                }
            }
        }
    }

    private func animateFixationDot(width: CGFloat, duration: TimeInterval, completion: @escaping () -> Void) {
        let gap: CGFloat = 20
        let left = gap
        let right = width - gap
        let segment = duration / 3

        withAnimation(.easeInOut(duration: segment)) {}
        DispatchQueue.main.asyncAfter(deadline: .now() + segment) {
            withAnimation(.easeInOut(duration: segment)) {}
            DispatchQueue.main.asyncAfter(deadline: .now() + segment) {
                withAnimation(.easeInOut(duration: segment)) {}
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
}

struct OptokineticTestView: View {
    @Binding var isShowing: Bool
    @Binding var showReflexDotGame: Bool
    @State private var phase: Int = 0
    @State private var offset: CGFloat = 0
    @State private var stripes: [CGFloat] = []

    let redDotSize: CGFloat = 20

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
                            let totalWidth = geo.size.width * 2
                            stripes = generateStripes(totalWidth: totalWidth)
                            offset = 0

                            withAnimation(.linear(duration: 7)) {
                                offset = -2 * geo.size.width
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                                isShowing = false
                                showReflexDotGame = true
                            }
                        }

                        Circle()
                            .fill(Color.red)
                            .frame(width: redDotSize, height: redDotSize)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
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

struct ReflexDotGameView: View {
    @Binding var isShowing: Bool

    private let totalCircles = 12
    private let highlightDuration = 0.4
    private let maxCycles = 3

    @State private var highlightedIndex = 0
    @State private var forward = true
    @State private var hitCount = 0
    @State private var missCount = 0
    @State private var cycleCount = 0
    @State private var isRunning = true

    var body: some View {
        VStack(spacing: 30) {
            Text("Tap the red circle!")
                .font(.title)
                .foregroundColor(.white)

            Text("Hit Rate: \(hitPercentage, specifier: "%.0f")%")
                .font(.headline)
                .foregroundColor(.yellow)

            HStack(spacing: 15) {
                ForEach(0..<totalCircles, id: \.self) { i in
                    Circle()
                        .fill(i == highlightedIndex ? .red : .gray)
                        .frame(width: 30, height: 30)
                        .scaleEffect(i == highlightedIndex ? 1.2 : 0.7)
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
            startHighlighting()
        }
        .background(Color.black.ignoresSafeArea())
    }

    private var hitPercentage: Double {
        let total = hitCount + missCount
        return total == 0 ? 0 : Double(hitCount) / Double(total) * 100
    }

    private func startHighlighting() {
        Timer.scheduledTimer(withTimeInterval: highlightDuration, repeats: true) { timer in
            if !isRunning { timer.invalidate(); return }

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
            }
        }
    }
}

struct ReactionGameView_Previews: PreviewProvider {
    static var previews: some View {
        ReactionGameView()
    }
}
