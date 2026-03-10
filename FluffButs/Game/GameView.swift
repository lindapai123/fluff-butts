import SwiftUI
import SpriteKit

// MARK: - GameView
struct GameView: View {

    let breed: DogBreed
    @Environment(\.dismiss) private var dismiss

    @State private var scene: GameScene
    @State private var gameResult: GameResult? = nil   // drives fullScreenCover(item:)

    init(breed: DogBreed) {
        self.breed = breed
        _scene = State(initialValue: GameView.makeScene(breed: breed))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .onAppear {
                    // Wire callback every time the view appears (also after Play Again)
                    scene.onCourseComplete = { [self] result in
                        DispatchQueue.main.async {
                            gameResult = result
                        }
                    }
                }

            // Back button
            Button { dismiss() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Menu")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.black.opacity(0.35)))
                .padding(.top, 56)
                .padding(.leading, 16)
            }

            // Title
            HStack(spacing: 6) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("Fluff Butts")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            .frame(maxWidth: .infinity)
            .padding(.top, 62)
        }
        // fullScreenCover(item:) — only presents when gameResult is non-nil, never shows blank screen
        .fullScreenCover(item: $gameResult) { result in
            GroomingView(result: result) {
                // Play Again — dismiss grooming by clearing gameResult, then reset scene
                gameResult = nil
                let newScene = GameView.makeScene(breed: breed)
                newScene.onCourseComplete = { r in
                    DispatchQueue.main.async { gameResult = r }
                }
                scene = newScene
            }
        }
    }

    private static func makeScene(breed: DogBreed) -> GameScene {
        let s = GameScene(size: CGSize(width: 393, height: 852), breed: breed)
        s.scaleMode = .resizeFill
        s.backgroundColor = SKColor(red: 0.40, green: 0.68, blue: 0.30, alpha: 1.0)
        return s
    }
}

#Preview { GameView(breed: .memphis) }
