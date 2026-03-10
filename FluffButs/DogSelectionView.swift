import SwiftUI
import SpriteKit

// MARK: - DogSelectionView
struct DogSelectionView: View {

    @Environment(\.dismiss) private var dismiss
    @Binding var selectedBreed: DogBreed?

    @State private var pendingBreed: DogBreed? = nil
    @State private var scene: DogWalkScene = DogWalkScene(
        size: CGSize(width: 390, height: 260),
        breed: .memphis
    )
    @State private var sceneReady = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.94, blue: 0.84),
                    Color(red: 0.93, green: 0.82, blue: 0.60)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {

                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 0.55, green: 0.35, blue: 0.10))
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.08)))
                    }
                    Spacer()
                    Text("Choose Your Dog")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.55, green: 0.32, blue: 0.08))
                    Spacer()
                    // Balance the back button
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 8)

                // Dog preview area
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(red: 0.53, green: 0.82, blue: 0.93).opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(red: 0.40, green: 0.65, blue: 0.80).opacity(0.4), lineWidth: 1.5)
                        )

                    if let breed = pendingBreed {
                        VStack(spacing: 4) {
                            SpriteView(scene: scene, options: [.allowsTransparency])
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                            Text("\(breed.displayName) is ready to play!")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 0.35, green: 0.55, blue: 0.75))
                                .padding(.bottom, 8)
                        }
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 44))
                                .foregroundColor(Color(red: 0.72, green: 0.50, blue: 0.20).opacity(0.5))
                            Text("Pick a dog below!")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 0.55, green: 0.38, blue: 0.15).opacity(0.7))
                        }
                        .frame(height: 180)
                    }
                }
                .frame(height: pendingBreed != nil ? 240 : 180)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .animation(.spring(response: 0.4), value: pendingBreed != nil)

                // Dog cards
                HStack(spacing: 14) {
                    ForEach(DogBreed.allCases) { breed in
                        DogCard(
                            breed: breed,
                            isSelected: pendingBreed == breed,
                            onTap: { selectBreed(breed) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                Spacer()

                // Play button
                Button {
                    selectedBreed = pendingBreed
                    dismiss()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("Let's Play!")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Group {
                            if pendingBreed != nil {
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.85, green: 0.48, blue: 0.10),
                                        Color(red: 0.70, green: 0.33, blue: 0.05)
                                    ],
                                    startPoint: .top, endPoint: .bottom
                                )
                            } else {
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(
                        color: pendingBreed != nil
                            ? Color(red: 0.70, green: 0.33, blue: 0.05).opacity(0.4)
                            : .clear,
                        radius: 10, x: 0, y: 5
                    )
                }
                .disabled(pendingBreed == nil)
                .padding(.horizontal, 40)
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Actions

    private func selectBreed(_ breed: DogBreed) {
        if pendingBreed == breed { return }

        if pendingBreed == nil {
            // First selection — configure scene
            scene = DogWalkScene(size: CGSize(width: 350, height: 200), breed: breed)
            scene.scaleMode = .resizeFill
            scene.backgroundColor = .clear
        } else {
            // Switch breed in existing scene
            scene.switchBreed(to: breed)
        }

        withAnimation(.spring(response: 0.3)) {
            pendingBreed = breed
        }
    }
}

// MARK: - DogCard

private struct DogCard: View {
    let breed: DogBreed
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Dog icon (SF Symbol as placeholder — real dog drawn in SpriteKit)
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: breed == .memphis
                                    ? [Color(red: 0.98, green: 0.92, blue: 0.72),
                                       Color(red: 0.92, green: 0.78, blue: 0.42)]
                                    : [Color(red: 0.80, green: 0.86, blue: 0.96),
                                       Color(red: 0.62, green: 0.72, blue: 0.90)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)

                    Image(systemName: "dog.fill")
                        .font(.system(size: 34))
                        .foregroundColor(
                            breed == .memphis
                                ? Color(red: 0.72, green: 0.46, blue: 0.10)
                                : Color(red: 0.15, green: 0.15, blue: 0.20)
                        )
                }

                Text(breed.displayName)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.40, green: 0.22, blue: 0.05))

                Text(breed.breedName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.55, green: 0.38, blue: 0.15))

                // Difficulty badge
                Text(breed.difficulty)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(
                            breed == .memphis
                                ? Color(red: 0.20, green: 0.70, blue: 0.30)
                                : Color(red: 0.85, green: 0.25, blue: 0.15)
                        )
                    )

                Text(breed.personality)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(Color(red: 0.45, green: 0.30, blue: 0.10))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(isSelected ? 0.95 : 0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                isSelected
                                    ? Color(red: 0.85, green: 0.48, blue: 0.10)
                                    : Color.clear,
                                lineWidth: 3
                            )
                    )
                    .shadow(
                        color: isSelected
                            ? Color(red: 0.85, green: 0.48, blue: 0.10).opacity(0.3)
                            : Color.black.opacity(0.08),
                        radius: isSelected ? 10 : 4,
                        x: 0, y: 2
                    )
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
