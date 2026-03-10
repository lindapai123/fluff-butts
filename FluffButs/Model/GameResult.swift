import Foundation

// MARK: - GameResult
// Passed from GameScene → GameView → GroomingView after course complete.
struct GameResult: Identifiable {
    let id = UUID()
    let breed: DogBreed
    let bonesCollected: Int
    let totalBones: Int
    let gotWet: Bool       // Lincoln fell in water
    let hitObstacles: Int  // number of rock collisions

    // MARK: - Star Rating

    var stars: Int {
        // Lincoln + water = always 1 star regardless
        if gotWet && breed == .lincoln { return 1 }

        let pct = totalBones > 0 ? Double(bonesCollected) / Double(totalBones) : 0
        switch pct {
        case 0.8...:  return 3
        case 0.5...:  return 2
        default:      return 1
        }
    }

    // MARK: - Grooming Tier

    var groomingTitle: String {
        if gotWet && breed == .lincoln { return "MAXIMUM BLOW DRY!" }
        switch stars {
        case 3: return "Already Fluffy!"
        case 2: return "Needs a Brush"
        default: return "Full Blow Dry!"
        }
    }

    var groomingTitleIcon: String {
        if gotWet && breed == .lincoln { return "drop.fill" }
        switch stars {
        case 3: return "sparkles"
        case 2: return "comb.fill"
        default: return "wind"
        }
    }

    var groomingDescription: String {
        if gotWet && breed == .lincoln {
            return "Lincoln went swimming AGAIN. This is going to take a while…"
        }
        switch stars {
        case 3: return "Wow, \(breed.displayName) ran a perfect course! Look at that fluffy butt!"
        case 2: return "Pretty good run! Just needs a little brushing."
        default: return "Yikes! \(breed.displayName) had a rough time. Time for a full blow dry."
        }
    }

    var groomingTaps: Int {
        if gotWet && breed == .lincoln { return 20 }
        switch stars {
        case 3: return 5
        case 2: return 10
        default: return 15
        }
    }
}
