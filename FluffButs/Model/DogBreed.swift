import UIKit

// MARK: - DogBreed
// Defines each playable dog breed with its visual properties and personality.
enum DogBreed: String, CaseIterable, Identifiable {
    case memphis = "Memphis"
    case lincoln = "Lincoln"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var breedName: String {
        switch self {
        case .memphis: return "Golden Retriever"
        case .lincoln: return "Black Lab"
        }
    }

    var personality: String {
        switch self {
        case .memphis: return "Fun & bouncy • Loves to deer-hop! 🦌"
        case .lincoln: return "Feisty & stubborn • Hates water! 💦"
        }
    }

    var difficulty: String {
        switch self {
        case .memphis: return "Easy"
        case .lincoln: return "Hard"
        }
    }

    var difficultyColor: UIColor {
        switch self {
        case .memphis: return UIColor(red: 0.20, green: 0.70, blue: 0.30, alpha: 1.0)
        case .lincoln: return UIColor(red: 0.85, green: 0.25, blue: 0.15, alpha: 1.0)
        }
    }

    // MARK: - Visual Properties

    var bodyColor: UIColor {
        switch self {
        case .memphis: return UIColor(red: 0.82, green: 0.60, blue: 0.22, alpha: 1.0)
        case .lincoln: return UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
        }
    }

    var strokeColor: UIColor {
        switch self {
        case .memphis: return UIColor(red: 0.58, green: 0.38, blue: 0.08, alpha: 1.0)
        case .lincoln: return UIColor(red: 0.28, green: 0.28, blue: 0.32, alpha: 1.0)
        }
    }

    var earColor: UIColor {
        switch self {
        case .memphis: return UIColor(red: 0.70, green: 0.45, blue: 0.10, alpha: 1.0)
        case .lincoln: return UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
        }
    }

    var snoutColor: UIColor {
        switch self {
        case .memphis: return UIColor(red: 0.90, green: 0.72, blue: 0.35, alpha: 1.0)
        case .lincoln: return UIColor(red: 0.22, green: 0.22, blue: 0.26, alpha: 1.0)
        }
    }

    var cardGradient: (UIColor, UIColor) {
        switch self {
        case .memphis:
            return (UIColor(red: 0.98, green: 0.92, blue: 0.72, alpha: 1.0),
                    UIColor(red: 0.95, green: 0.80, blue: 0.45, alpha: 1.0))
        case .lincoln:
            return (UIColor(red: 0.82, green: 0.88, blue: 0.98, alpha: 1.0),
                    UIColor(red: 0.62, green: 0.72, blue: 0.90, alpha: 1.0))
        }
    }
}
