import SwiftUI

// MARK: - GroomingView
// The post-run grooming mini-game. Tap/swipe to groom your dog!
// Required taps scale with star rating; Lincoln + wet = MAXIMUM BLOW DRY.
struct GroomingView: View {

    let result: GameResult
    var onPlayAgain: () -> Void

    @State private var tapCount = 0
    @State private var isGroomingDone = false
    @State private var fluffScale: CGFloat = 0.5
    @State private var shakeOffset: CGFloat = 0
    @State private var sparkles: [SparkleParticle] = []
    @State private var groomProgress: CGFloat = 0
    @State private var showResult = false

    private var totalTaps: Int { result.groomingTaps }
    private var progressPct: CGFloat { min(CGFloat(tapCount) / CGFloat(totalTaps), 1.0) }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.90, blue: 0.98),
                    Color(red: 0.85, green: 0.78, blue: 0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {

                // Header
                VStack(spacing: 6) {
                    Text(result.groomingTitle)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.45, green: 0.20, blue: 0.60))
                        .multilineTextAlignment(.center)
                        .padding(.top, 60)

                    // Star rating
                    HStack(spacing: 4) {
                        ForEach(1...3, id: \.self) { i in
                            Image(systemName: i <= result.stars ? "star.fill" : "star")
                                .font(.system(size: 26))
                                .foregroundColor(i <= result.stars
                                    ? Color(red: 0.95, green: 0.78, blue: 0.10)
                                    : Color(white: 0.75))
                                .scaleEffect(i <= result.stars ? 1.1 : 1.0)
                        }
                    }
                    .padding(.bottom, 4)

                    Text(result.groomingDescription)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 0.45, green: 0.30, blue: 0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // MAIN GROOMING AREA — tap here!
                ZStack {
                    // Glow background
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.88, green: 0.82, blue: 0.98),
                                    Color(red: 0.78, green: 0.68, blue: 0.95).opacity(0.3)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 140
                            )
                        )
                        .frame(width: 280, height: 280)

                    // The fluffy butt! (drawn shapes)
                    FluffyButtView(
                        fluffScale: fluffScale,
                        isDone: isGroomingDone,
                        breed: result.breed,
                        isWet: result.gotWet && result.breed == .lincoln
                    )
                    .frame(width: 220, height: 220)
                    .offset(x: shakeOffset)

                    // Sparkles overlay
                    ForEach(sparkles) { sparkle in
                        Text("✨")
                            .font(.system(size: sparkle.size))
                            .position(sparkle.position)
                            .opacity(sparkle.opacity)
                    }

                    if !isGroomingDone {
                        // Tool icon hint
                        VStack {
                            Spacer()
                            Text(groomingToolIcon)
                                .font(.system(size: 32))
                                .opacity(0.6)
                        }
                        .frame(height: 280)
                    }
                }
                .onTapGesture { handleGroomTap() }

                // Progress bar
                if !isGroomingDone {
                    VStack(spacing: 8) {
                        Text(tapCount == 0 ? "Tap to groom!" : "Keep going! \(totalTaps - tapCount) more…")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.45, green: 0.25, blue: 0.60))

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(white: 0.88))
                                .frame(height: 18)

                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.75, green: 0.40, blue: 0.90),
                                                 Color(red: 0.55, green: 0.25, blue: 0.80)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(18, 260 * progressPct), height: 18)
                                .animation(.spring(response: 0.3), value: progressPct)
                        }
                        .frame(width: 260)
                    }
                    .padding(.top, 16)
                } else if showResult {
                    // Done!
                    VStack(spacing: 6) {
                        Text("✨ Beautiful! ✨")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.55, green: 0.25, blue: 0.75))
                        Text("What a fluffy butt! 🐾")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 0.55, green: 0.38, blue: 0.65))
                    }
                    .padding(.top, 16)
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer()

                // Buttons
                if isGroomingDone && showResult {
                    VStack(spacing: 12) {
                        Button(action: onPlayAgain) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 18, weight: .bold))
                                Text("Play Again!")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.75, green: 0.40, blue: 0.90),
                                             Color(red: 0.55, green: 0.20, blue: 0.75)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: Color(red: 0.55, green: 0.20, blue: 0.75).opacity(0.4),
                                    radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 48)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Helpers

    private var groomingToolIcon: String {
        if result.gotWet && result.breed == .lincoln { return "💨" }
        switch result.stars {
        case 3: return "✨"
        case 2: return "🪮"
        default: return "💨"
        }
    }

    private func handleGroomTap() {
        guard !isGroomingDone else { return }
        tapCount += 1

        // Animate scale growth
        let newScale = 0.5 + (progressPct * 0.5)
        withAnimation(.spring(response: 0.2)) {
            fluffScale = newScale
        }

        // Add a sparkle
        addSparkle()

        // Shake effect for Lincoln wet
        if result.gotWet && result.breed == .lincoln {
            withAnimation(.easeInOut(duration: 0.05).repeatCount(4)) {
                shakeOffset = CGFloat.random(in: -8...8)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                shakeOffset = 0
            }
        }

        // Check completion
        if tapCount >= totalTaps {
            completeGrooming()
        }
    }

    private func addSparkle() {
        let s = SparkleParticle(
            id: UUID(),
            position: CGPoint(
                x: CGFloat.random(in: 60...220),
                y: CGFloat.random(in: 60...220)
            ),
            size: CGFloat.random(in: 14...28),
            opacity: 1.0
        )
        sparkles.append(s)

        withAnimation(.easeOut(duration: 0.8)) {
            if let idx = sparkles.firstIndex(where: { $0.id == s.id }) {
                sparkles[idx].opacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            sparkles.removeAll { $0.id == s.id }
        }
    }

    private func completeGrooming() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            isGroomingDone = true
            fluffScale = 1.0
        }
        // Burst of sparkles
        for _ in 0..<8 { addSparkle() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring()) {
                showResult = true
            }
        }
    }
}

// MARK: - FluffyButtView
// A cute drawn dog butt that grows fluffier as you groom!
private struct FluffyButtView: View {
    let fluffScale: CGFloat
    let isDone: Bool
    let breed: DogBreed
    let isWet: Bool

    var bodyColor: Color {
        breed == .memphis
            ? Color(red: 0.82, green: 0.60, blue: 0.22)
            : Color(red: 0.15, green: 0.15, blue: 0.18)
    }

    var body: some View {
        ZStack {
            if isWet {
                // Water drops dripping off the butt
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(Color(red: 0.30, green: 0.65, blue: 0.95).opacity(0.7))
                        .frame(width: 8, height: 8)
                        .offset(
                            x: CGFloat(i - 2) * 18,
                            y: 30 + CGFloat(i % 2) * 12
                        )
                }
            }

            // Main butt body
            Ellipse()
                .fill(bodyColor)
                .frame(width: 100, height: 80)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

            // Fluffy tail poof — grows with grooming
            Circle()
                .fill(
                    RadialGradient(
                        colors: [bodyColor.opacity(0.9), bodyColor.opacity(0.4)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60 * fluffScale
                    )
                )
                .frame(
                    width: 60 + 60 * fluffScale,
                    height: 60 + 60 * fluffScale
                )
                .offset(y: -10)

            // Fluffy fur wisps (more appear as grooming progresses)
            if fluffScale > 0.4 {
                ForEach(0..<5, id: \.self) { i in
                    Ellipse()
                        .fill(bodyColor.opacity(0.75))
                        .frame(width: 24 + CGFloat(i) * 4, height: 18)
                        .offset(
                            x: cos(CGFloat(i) / 5.0 * .pi * 2) * 45 * fluffScale,
                            y: sin(CGFloat(i) / 5.0 * .pi * 2) * 35 * fluffScale - 10
                        )
                }
            }

            // Sparkle on done
            if isDone {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(Color(red: 0.95, green: 0.85, blue: 0.20))
                    .offset(y: -50)
            }
        }
    }
}

// MARK: - SparkleParticle
private struct SparkleParticle: Identifiable {
    let id: UUID
    let position: CGPoint
    let size: CGFloat
    var opacity: Double
}
