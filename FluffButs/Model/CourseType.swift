import Foundation

enum CourseType: String, CaseIterable {
    case park     = "Park Run"
    case swimming = "Swimming"

    var icon: String {
        switch self {
        case .park:     return "leaf.fill"
        case .swimming: return "drop.fill"
        }
    }

    var description: String {
        switch self {
        case .park:     return "Rocks, puddles & bones"
        case .swimming: return "Coming soon!"
        }
    }

    var isAvailable: Bool {
        switch self {
        case .park:     return true
        case .swimming: return false
        }
    }
}
