import Foundation
import SwiftData

@Model
final class CharacterCard {
    @Attribute(.unique) var character: String
    var pinyin: String
    var meaning: String
    var hsk: Int
    var radical: String
    var strokes: Int
    var examples: [String]
    var context: String

    // Status tracking
    var statusRaw: String
    var dateAdded: Date

    // SM-2 spaced repetition fields
    var nextReview: Date
    var interval: Int
    var easeFactor: Double
    var reviewCount: Int
    var correctCount: Int

    // Relationship to source photos
    @Relationship var sourcePhotos: [CapturedPhoto] = []

    var status: CharacterStatus {
        get { CharacterStatus(rawValue: statusRaw) ?? .new }
        set { statusRaw = newValue.rawValue }
    }

    init(
        character: String,
        pinyin: String = "",
        meaning: String = "",
        hsk: Int = 0,
        radical: String = "",
        strokes: Int = 0,
        examples: [String] = [],
        context: String = ""
    ) {
        self.character = character
        self.pinyin = pinyin
        self.meaning = meaning
        self.hsk = hsk
        self.radical = radical
        self.strokes = strokes
        self.examples = examples
        self.context = context
        self.statusRaw = CharacterStatus.new.rawValue
        self.dateAdded = Date()
        self.nextReview = Date()
        self.interval = 1
        self.easeFactor = 2.5
        self.reviewCount = 0
        self.correctCount = 0
    }

    /// Create a CharacterCard from dictionary lookup
    static func from(character: String, info: CharacterInfo?, context: String = "") -> CharacterCard {
        CharacterCard(
            character: character,
            pinyin: info?.pinyin ?? "",
            meaning: info?.meaning ?? "Not in dictionary",
            hsk: info?.hsk ?? 0,
            radical: info?.radical ?? "",
            strokes: info?.strokes ?? 0,
            examples: info?.examples ?? [],
            context: context
        )
    }

    /// Create a CharacterCard from a component
    static func from(component: ComponentInfo, context: String = "") -> CharacterCard {
        CharacterCard(
            character: component.character,
            pinyin: component.pinyin,
            meaning: component.meaning,
            hsk: 0,
            radical: "",
            strokes: 0,
            examples: [],
            context: context
        )
    }
}

enum CharacterStatus: String, Codable, CaseIterable {
    case new
    case learning
    case mastered

    var displayName: String {
        switch self {
        case .new: return "New"
        case .learning: return "Learning"
        case .mastered: return "Mastered"
        }
    }
}
