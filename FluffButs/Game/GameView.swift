import SwiftUI
import SpriteKit

// MARK: - GameView
// SwiftUI wrapper around the SpriteKit GameScene.
// Presents GroomingView as a full-screen cover when the course is complete.
struct GameView: View {

    let breed: DogBreed
    @Environment(\.dismiss) private var dismiss

    @State private var scene: GameScene
    @State private var gameResult: GameResult? = nil
    @State private var showGrooming = false

    init(breed: DogBreed) {
        self.breed = breed
        let s = GameView.makeScene(breed: breed)
        _scene = State(initialValue: s)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Full-screen SpriteKit canvas
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .onAppear {
                    // Wire the game result callback
                    scene.onCourseComplete = { result in
                        gameResult = result
                        showGrooming = true
                    }
                }

            // Back button
            Button {
                dismiss()
            } label: {
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

            // Title bar
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
        .fullScreenCover(isPresented: $showGrooming) {
            if let result = gameResult {
                GroomingView(result: result) {
                    // Play again — dismiss grooming and reset game
                    showGrooming = false
                    gameResult = nil
                    let newScene = GameView.makeScene(breed: breed)
                    newScene.onCourseComplete = { result in
                        gameResult = result
                        showGrooming = true
                    }
                    scene = newScene
                }
            }
        }
    }

    // MARK: - Scene Factory

    private static func makeScene(breed: DogBreed) -> GameScene {
        let s = GameScene(size: CGSize(width: 393, height: 852), breed: breed)
        s.scaleMode = .resizeFill
        s.backgroundColor = SKColor(red: 0.40, green: 0.68, blue: 0.30, alpha: 1.0)
        return s
    }
}

#Preview {
    GameView(breed: .memphis)
}
