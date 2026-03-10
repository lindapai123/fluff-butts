import SwiftUI
import SpriteKit

// MARK: - GameView
// SwiftUI wrapper around the SpriteKit GameScene.
// Uses @State so the scene is created only once per view lifecycle —
// SwiftUI View structs are re-initialised on every render pass, but
// @State storage persists across renders.
struct GameView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var scene: SKScene = GameView.makeScene()

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Full-screen SpriteKit canvas
            SpriteView(scene: scene)
                .ignoresSafeArea()

            // Back button overlay
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
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.35))
                )
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
    }

    // MARK: - Scene Factory

    private static func makeScene() -> SKScene {
        let s = GameScene(size: CGSize(width: 393, height: 852))
        s.scaleMode = .resizeFill
        s.backgroundColor = SKColor(red: 0.40, green: 0.68, blue: 0.30, alpha: 1.0)
        return s
    }
}

#Preview {
    GameView()
}
