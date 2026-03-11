import SwiftUI
import SpriteKit

struct SwimmingView: View {
    let breed: DogBreed
    @State private var gameResult: GameResult?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            SpriteView(scene: makeScene())
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Label("Menu", systemImage: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.black.opacity(0.4)))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                Spacer()
            }
        }
        .fullScreenCover(item: $gameResult) { result in
            GroomingView(result: result) {
                gameResult = nil
                dismiss()
            }
        }
    }

    @MainActor private func makeScene() -> SwimmingScene {
        let scene = SwimmingScene(size: UIScreen.main.bounds.size, breed: breed)
        scene.scaleMode = .resizeFill
        scene.onCourseComplete = { result in
            DispatchQueue.main.async { self.gameResult = result }
        }
        return scene
    }
}
