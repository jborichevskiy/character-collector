import Foundation

enum ReviewRating: Int, CaseIterable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4

    var label: String {
        switch self {
        case .again: return "Again"
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }

    var emoji: String {
        switch self {
        case .again: return "😕"
        case .hard: return "🤔"
        case .good: return "😊"
        case .easy: return "🎉"
        }
    }
}
