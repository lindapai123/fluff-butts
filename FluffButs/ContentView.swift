import SwiftUI

struct ContentView: View {
    @State private var isAnimating = false
    @State private var selectedBreed: DogBreed? = nil
    @State private var selectedCourse: CourseType = .park
    @State private var showDogSelection = false
    @State private var showCourseSelection = false
    @State private var showGame = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.92, blue: 0.80),
                    Color(red: 0.95, green: 0.78, blue: 0.60)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Paw icon
                Image(systemName: "pawprint.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.80, green: 0.45, blue: 0.10),
                                Color(red: 0.60, green: 0.28, blue: 0.04)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 0.60, green: 0.28, blue: 0.04).opacity(0.25),
                            radius: 8, x: 0, y: 4)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                    .padding(.bottom, 28)

                // Title
                VStack(spacing: 8) {
                    Text("Fluff Butts")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.70, green: 0.40, blue: 0.10),
                                    Color(red: 0.90, green: 0.55, blue: 0.15)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)

                    Text("Train your dog. Earn a fluffy butt!")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 0.55, green: 0.38, blue: 0.15))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Selected dog badge
                if let breed = selectedBreed {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(red: 0.20, green: 0.70, blue: 0.30))
                        Text("\(breed.displayName) is ready!")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.35, green: 0.55, blue: 0.15))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(Color(red: 0.85, green: 0.96, blue: 0.82))
                    )
                    .padding(.top, 16)
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer()

                VStack(spacing: 14) {
                    // Change Course box
                    Button {
                        showCourseSelection = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: selectedCourse.icon)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(red: 0.15, green: 0.50, blue: 0.85))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Change Course")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(red: 0.40, green: 0.40, blue: 0.55))
                                Text(selectedCourse.rawValue)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.15, green: 0.35, blue: 0.70))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.70))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(red: 0.88, green: 0.92, blue: 1.0))
                                .shadow(color: Color(red: 0.15, green: 0.35, blue: 0.70).opacity(0.18),
                                        radius: 6, x: 0, y: 3)
                        )
                    }

                    // Choose Dog button
                    Button {
                        showDogSelection = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "dog.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text(selectedBreed == nil ? "Choose Your Dog" : "Change Dog")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(Color(red: 0.55, green: 0.32, blue: 0.05))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.99, green: 0.88, blue: 0.60),
                                    Color(red: 0.97, green: 0.78, blue: 0.38)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: Color(red: 0.80, green: 0.55, blue: 0.10).opacity(0.35),
                                radius: 8, x: 0, y: 4)
                    }

                    // Play Now button — disabled until dog chosen
                    Button {
                        showGame = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text("Play Now")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            Group {
                                if selectedBreed != nil {
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.85, green: 0.48, blue: 0.10),
                                            Color(red: 0.70, green: 0.33, blue: 0.05)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                } else {
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.45), Color.gray.opacity(0.35)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(
                            color: selectedBreed != nil
                                ? Color(red: 0.70, green: 0.33, blue: 0.05).opacity(0.4)
                                : .clear,
                            radius: 10, x: 0, y: 5
                        )
                    }
                    .disabled(selectedBreed == nil)

                    // Helper text when no dog selected
                    if selectedBreed == nil {
                        Text("Choose your dog first to unlock Play!")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 0.60, green: 0.42, blue: 0.18).opacity(0.8))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 52)
                .animation(.spring(response: 0.4), value: selectedBreed != nil)
            }
        }
        .onAppear { isAnimating = true }
        .fullScreenCover(isPresented: $showDogSelection) {
            DogSelectionView(selectedBreed: $selectedBreed)
        }
        .fullScreenCover(isPresented: $showGame) {
            if selectedCourse == .swimming {
                SwimmingView(breed: selectedBreed ?? .memphis)
            } else {
                GameView(breed: selectedBreed ?? .memphis)
            }
        }
        .sheet(isPresented: $showCourseSelection) {
            CourseSelectionSheet(selectedCourse: $selectedCourse)
                .presentationDetents([.fraction(0.45)])
        }
    }
}

#Preview {
    ContentView()
}
