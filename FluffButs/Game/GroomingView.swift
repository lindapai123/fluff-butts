import SwiftUI

// MARK: - GroomingView
// Post-run grooming mini-game. Drag a brush over sticks and leaves to groom them out!
struct GroomingView: View {

    let result: GameResult
    var onPlayAgain: () -> Void

    // Debris items tangled in the fur
    @State private var debris: [DebrisItem] = GroomingView.makeDebris(for: .memphis)
    @State private var brushPosition: CGPoint = .zero
    @State private var isBrushing: Bool = false
    @State private var isGroomingDone: Bool = false
    @State private var showResult: Bool = false
    @State private var sparkles: [SparkleParticle] = []

    private var removedCount: Int { debris.filter(\.isRemoved).count }
    private var totalCount: Int { debris.count }
    private var progress: CGFloat { totalCount > 0 ? CGFloat(removedCount) / CGFloat(totalCount) : 0 }

    var body: some View {
        ZStack {
            // Purple grooming room background
            LinearGradient(
                colors: [Color(red: 0.92, green: 0.88, blue: 0.98),
                         Color(red: 0.78, green: 0.70, blue: 0.95)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header ────────────────────────────────────────────
                VStack(spacing: 6) {
                    Text(result.groomingTitle)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.40, green: 0.18, blue: 0.60))
                        .multilineTextAlignment(.center)
                        .padding(.top, 56)

                    // Stars
                    HStack(spacing: 4) {
                        ForEach(1...3, id: \.self) { i in
                            Image(systemName: i <= result.stars ? "star.fill" : "star")
                                .font(.system(size: 26))
                                .foregroundColor(i <= result.stars
                                    ? Color(red: 0.95, green: 0.80, blue: 0.10)
                                    : Color(white: 0.75))
                        }
                    }

                    Text(result.groomingDescription)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 0.42, green: 0.28, blue: 0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 8)
                }

                // ── Grooming canvas ───────────────────────────────────
                ZStack {
                    // Real golden retriever butt photo
                    Image("GoldenRetrieverButt")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 320, height: 340)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color(red: 0.70, green: 0.50, blue: 0.20).opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)

                    // Debris items (sticks & leaves to brush out)
                    ForEach($debris) { $item in
                        DebrisView(item: item)
                    }

                    // Brush cursor — follows drag
                    if isBrushing {
                        BrushView()
                            .position(brushPosition)
                            .allowsHitTesting(false)
                    }

                    // Sparkles
                    ForEach(sparkles) { s in
                        Text("✨")
                            .font(.system(size: s.size))
                            .position(s.position)
                            .opacity(s.opacity)
                            .allowsHitTesting(false)
                    }

                    // Completion glow overlay
                    if isGroomingDone {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.yellow.opacity(0.15))
                            .overlay(
                                Image(systemName: "sparkles")
                                    .font(.system(size: 60))
                                    .foregroundColor(Color(red: 0.95, green: 0.85, blue: 0.20))
                            )
                            .transition(.opacity)
                    }
                }
                .frame(width: 320, height: 340)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            isBrushing = true
                            brushPosition = value.location
                            checkBrushHits(at: value.location)
                        }
                        .onEnded { _ in
                            isBrushing = false
                        }
                )
                .padding(.vertical, 12)

                // ── Progress bar ──────────────────────────────────────
                if !isGroomingDone {
                    VStack(spacing: 6) {
                        Text(removedCount == 0
                             ? "Drag the brush to groom! 🪮"
                             : "\(totalCount - removedCount) more to go…")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.40, green: 0.22, blue: 0.58))

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(white: 0.85))
                                .frame(height: 16)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.75, green: 0.40, blue: 0.90),
                                                 Color(red: 0.52, green: 0.22, blue: 0.78)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .frame(width: max(16, 280 * progress), height: 16)
                                .animation(.spring(response: 0.25), value: progress)
                        }
                        .frame(width: 280)
                    }
                    .padding(.bottom, 8)
                }

                // ── Done message ──────────────────────────────────────
                if showResult {
                    VStack(spacing: 4) {
                        Text("✨ Gorgeous! ✨")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.50, green: 0.20, blue: 0.72))
                        Text("What a fluffy butt! 🐾")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 0.50, green: 0.35, blue: 0.62))
                    }
                    .transition(.scale.combined(with: .opacity))
                    .padding(.vertical, 8)
                }

                Spacer()

                // ── Play Again ────────────────────────────────────────
                if showResult {
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
                                colors: [Color(red: 0.75, green: 0.38, blue: 0.90),
                                         Color(red: 0.52, green: 0.18, blue: 0.75)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: Color(red: 0.52, green: 0.18, blue: 0.75).opacity(0.4),
                                radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            debris = GroomingView.makeDebris(for: result)
        }
    }

    // MARK: - Brush Hit Detection

    private func checkBrushHits(at point: CGPoint) {
        // Canvas is 320×340, centred in parent. Debris positions are relative to canvas top-left.
        // DragGesture with coordinateSpace: .local gives us canvas-local coords.
        let brushRadius: CGFloat = 38
        var didRemove = false
        for i in debris.indices {
            guard !debris[i].isRemoved else { continue }
            let dx = debris[i].position.x - point.x
            let dy = debris[i].position.y - point.y
            if hypot(dx, dy) < brushRadius {
                withAnimation(.spring(response: 0.25)) {
                    debris[i].isRemoved = true
                }
                didRemove = true
                addSparkle(near: point)
            }
        }
        if didRemove { checkCompletion() }
    }

    private func checkCompletion() {
        if debris.allSatisfy(\.isRemoved) && !isGroomingDone {
            withAnimation(.spring(response: 0.4)) { isGroomingDone = true }
            for _ in 0..<10 { addSparkle(near: CGPoint(x: CGFloat.random(in: 60...260),
                                                        y: CGFloat.random(in: 60...280))) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring()) { showResult = true }
            }
        }
    }

    // MARK: - Sparkles

    private func addSparkle(near point: CGPoint) {
        let s = SparkleParticle(
            id: UUID(),
            position: CGPoint(x: point.x + CGFloat.random(in: -30...30),
                              y: point.y + CGFloat.random(in: -30...30)),
            size: CGFloat.random(in: 14...24),
            opacity: 1.0
        )
        sparkles.append(s)
        withAnimation(.easeOut(duration: 0.7)) {
            if let idx = sparkles.firstIndex(where: { $0.id == s.id }) {
                sparkles[idx].opacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            sparkles.removeAll { $0.id == s.id }
        }
    }

    // MARK: - Debris Factory

    static func makeDebris(for result: GameResult) -> [DebrisItem] {
        makeDebris(stars: result.stars, isWet: result.gotWet && result.breed == .lincoln)
    }

    static func makeDebris(for breed: DogBreed) -> [DebrisItem] {
        makeDebris(stars: 2, isWet: false)
    }

    private static func makeDebris(stars: Int, isWet: Bool) -> [DebrisItem] {
        // More debris = worse run
        let stickCount  = isWet ? 5 : max(1, 5 - stars)
        let leafCount   = isWet ? 8 : max(2, 7 - stars)
        let mudCount    = isWet ? 4 : 0

        var items: [DebrisItem] = []

        // Spread within the image canvas (320×340), avoiding edges
        func rpt() -> CGPoint {
            CGPoint(x: CGFloat.random(in: 40...280),
                    y: CGFloat.random(in: 40...300))
        }

        for _ in 0..<stickCount {
            items.append(DebrisItem(type: .stick, position: rpt(),
                                    rotation: .degrees(Double.random(in: -45...45))))
        }
        for _ in 0..<leafCount {
            items.append(DebrisItem(type: .leaf, position: rpt(),
                                    rotation: .degrees(Double.random(in: 0...360))))
        }
        for _ in 0..<mudCount {
            items.append(DebrisItem(type: .mud, position: rpt(), rotation: .zero))
        }
        return items
    }
}

// MARK: - DebrisItem

struct DebrisItem: Identifiable {
    let id = UUID()
    let type: DebrisType
    let position: CGPoint
    let rotation: Angle
    var isRemoved: Bool = false
}

enum DebrisType {
    case stick, leaf, mud
}

// MARK: - DebrisView

private struct DebrisView: View {
    let item: DebrisItem

    var body: some View {
        Group {
            switch item.type {
            case .stick:
                StickView()
            case .leaf:
                LeafView()
            case .mud:
                Circle()
                    .fill(Color(red: 0.35, green: 0.22, blue: 0.10).opacity(0.85))
                    .frame(width: 28, height: 18)
                    .overlay(Circle().fill(Color(red: 0.40, green: 0.28, blue: 0.15).opacity(0.5)).frame(width: 14, height: 10))
            }
        }
        .rotationEffect(item.rotation)
        .position(item.position)
        .scaleEffect(item.isRemoved ? 0.01 : 1.0)
        .opacity(item.isRemoved ? 0 : 1)
        .animation(.spring(response: 0.2), value: item.isRemoved)
    }
}

// MARK: - Stick drawing

private struct StickView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.45, green: 0.28, blue: 0.10))
                .frame(width: 48, height: 7)
            // Bark lines
            ForEach([(-14, 0), (0, 0), (14, 0)], id: \.0) { (ox, _) in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(red: 0.32, green: 0.18, blue: 0.06))
                    .frame(width: 1.5, height: 7)
                    .offset(x: CGFloat(ox))
            }
        }
    }
}

// MARK: - Leaf drawing

private struct LeafView: View {
    var body: some View {
        ZStack {
            // Leaf body
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.58, green: 0.42, blue: 0.12),
                                 Color(red: 0.72, green: 0.55, blue: 0.18)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 30, height: 20)
            // Stem
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(red: 0.40, green: 0.24, blue: 0.08))
                .frame(width: 1.5, height: 12)
                .offset(y: 12)
            // Vein
            RoundedRectangle(cornerRadius: 0.5)
                .fill(Color.white.opacity(0.35))
                .frame(width: 20, height: 1)
        }
    }
}

// MARK: - BrushView
// Visual brush cursor following the drag gesture.
private struct BrushView: View {
    var body: some View {
        ZStack {
            // Brush head
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.85, green: 0.72, blue: 0.45))
                .frame(width: 52, height: 22)
                .overlay(
                    // Bristles
                    HStack(spacing: 3) {
                        ForEach(0..<9, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color(red: 0.65, green: 0.50, blue: 0.25))
                                .frame(width: 3, height: 14)
                                .offset(y: 6)
                        }
                    }
                )
            // Handle stub
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.60, green: 0.38, blue: 0.15))
                .frame(width: 14, height: 38)
                .offset(y: 28)
        }
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}

// MARK: - SparkleParticle

private struct SparkleParticle: Identifiable {
    let id: UUID
    let position: CGPoint
    let size: CGFloat
    var opacity: Double
}
