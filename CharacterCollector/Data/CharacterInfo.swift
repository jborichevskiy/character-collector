import Foundation

/// Type of component in a Chinese character
enum ComponentType: String, Sendable {
    case semantic  // Contributes to meaning
    case phonetic  // Contributes to pronunciation
    case both      // Rare cases where it's both
}

/// A component/subpart of a Chinese character
struct ComponentInfo: Sendable, Identifiable {
    let id = UUID()
    let character: String
    let pinyin: String
    let meaning: String
    let type: ComponentType  // semantic or phonetic
}

/// Information about a Chinese character from the dictionary
struct CharacterInfo: Sendable {
    let pinyin: String
    let meaning: String
    let hsk: Int          // HSK level 1-6, or 0 if not in HSK
    let radical: String
    let strokes: Int
    let examples: [String]
    let components: [ComponentInfo]  // Subcomponents that make up this character

    init(pinyin: String, meaning: String, hsk: Int = 0, radical: String = "", strokes: Int = 0, examples: [String] = [], components: [ComponentInfo] = []) {
        self.pinyin = pinyin
        self.meaning = meaning
        self.hsk = hsk
        self.radical = radical
        self.strokes = strokes
        self.examples = examples
        self.components = components
    }

    /// Create a placeholder for unknown characters
    nonisolated static func unknown(character: String) -> CharacterInfo {
        CharacterInfo(
            pinyin: "",
            meaning: "Not in dictionary",
            hsk: 0,
            radical: "",
            strokes: 0,
            examples: [],
            components: []
        )
    }
}

/// Information about a common Chinese phrase
struct PhraseInfo: Sendable {
    let pinyin: String
    let meaning: String
}

/// Information about a compound word (2+ characters that form a unit)
struct WordInfo: Sendable, Identifiable {
    let id = UUID()
    let word: String
    let pinyin: String
    let meaning: String

    // The individual characters that make up this word
    var characters: [String] {
        word.map { String($0) }
    }
}
