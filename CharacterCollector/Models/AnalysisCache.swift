import Foundation

/// Codable version of WordInfo for JSON storage
struct CachedWordInfo: Codable {
    let word: String
    let pinyin: String
    let meaning: String

    init(from wordInfo: WordInfo) {
        self.word = wordInfo.word
        self.pinyin = wordInfo.pinyin
        self.meaning = wordInfo.meaning
    }

    func toWordInfo() -> WordInfo {
        WordInfo(word: word, pinyin: pinyin, meaning: meaning)
    }
}

/// Codable version of ComponentInfo for JSON storage
struct CachedComponentInfo: Codable {
    let character: String
    let pinyin: String
    let meaning: String
    let typeRaw: String

    init(from component: ComponentInfo) {
        self.character = component.character
        self.pinyin = component.pinyin
        self.meaning = component.meaning
        self.typeRaw = component.type.rawValue
    }

    func toComponentInfo() -> ComponentInfo {
        ComponentInfo(
            character: character,
            pinyin: pinyin,
            meaning: meaning,
            type: ComponentType(rawValue: typeRaw) ?? .semantic
        )
    }
}

/// Codable version of AnalyzedCharacter for JSON storage
struct CachedAnalyzedCharacter: Codable {
    let character: String
    let pinyin: String
    let meaning: String
    let hsk: Int
    let radical: String
    let strokes: Int
    let examples: [String]
    let components: [CachedComponentInfo]
    var isSaved: Bool

    init(from analyzed: AnalyzedCharacter) {
        self.character = analyzed.character
        self.pinyin = analyzed.info.pinyin
        self.meaning = analyzed.info.meaning
        self.hsk = analyzed.info.hsk
        self.radical = analyzed.info.radical
        self.strokes = analyzed.info.strokes
        self.examples = analyzed.info.examples
        self.components = analyzed.info.components.map { CachedComponentInfo(from: $0) }
        self.isSaved = analyzed.isSaved
    }

    func toAnalyzedCharacter() -> AnalyzedCharacter {
        let info = CharacterInfo(
            pinyin: pinyin,
            meaning: meaning,
            hsk: hsk,
            radical: radical,
            strokes: strokes,
            examples: examples,
            components: components.map { $0.toComponentInfo() }
        )
        var analyzed = AnalyzedCharacter(character: character, info: info)
        analyzed.isSaved = isSaved
        return analyzed
    }
}

/// Helper for serializing/deserializing analysis data
enum AnalysisCacheHelper {
    static func serializeWords(_ words: [WordInfo]) -> String {
        let cached = words.map { CachedWordInfo(from: $0) }
        guard let data = try? JSONEncoder().encode(cached),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    static func deserializeWords(_ json: String) -> [WordInfo] {
        guard let data = json.data(using: .utf8),
              let cached = try? JSONDecoder().decode([CachedWordInfo].self, from: data) else {
            return []
        }
        return cached.map { $0.toWordInfo() }
    }

    static func serializeCharacters(_ characters: [AnalyzedCharacter]) -> String {
        let cached = characters.map { CachedAnalyzedCharacter(from: $0) }
        guard let data = try? JSONEncoder().encode(cached),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    static func deserializeCharacters(_ json: String) -> [AnalyzedCharacter] {
        guard let data = json.data(using: .utf8),
              let cached = try? JSONDecoder().decode([CachedAnalyzedCharacter].self, from: data) else {
            return []
        }
        return cached.map { $0.toAnalyzedCharacter() }
    }
}
