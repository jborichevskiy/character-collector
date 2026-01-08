import Foundation

extension Character {
    /// Check if this character is a Chinese character (CJK Unified Ideographs)
    var isChineseCharacter: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        let code = scalar.value

        // CJK Unified Ideographs
        if code >= 0x4E00 && code <= 0x9FFF { return true }
        // CJK Unified Ideographs Extension A
        if code >= 0x3400 && code <= 0x4DBF { return true }
        // CJK Unified Ideographs Extension B
        if code >= 0x20000 && code <= 0x2A6DF { return true }

        return false
    }
}

extension String {
    /// Extract all Chinese characters from this string
    var chineseCharacters: [Character] {
        filter { $0.isChineseCharacter }
    }

    /// Extract unique Chinese characters from this string
    var uniqueChineseCharacters: [String] {
        var seen = Set<Character>()
        var result: [String] = []
        for char in self where char.isChineseCharacter {
            if !seen.contains(char) {
                seen.insert(char)
                result.append(String(char))
            }
        }
        return result
    }
}
