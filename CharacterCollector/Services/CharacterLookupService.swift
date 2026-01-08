import Foundation

/// Result of analyzing Chinese text - includes both words and characters
struct TextAnalysisResult: Sendable {
    let words: [WordInfo]
    let characters: [String: CharacterInfo]
}

/// Service for looking up Chinese character information
/// Uses local dictionary first, falls back to Claude API for unknown characters
actor CharacterLookupService {

    private let apiKey = anthropicAPIKey
    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!

    // Cache for API results to avoid repeated lookups
    private var cache: [String: CharacterInfo] = [:]
    private var wordCache: [String: [WordInfo]] = [:]

    /// Analyze text to get both word groupings and character definitions
    func analyzeText(_ text: String, characters: [String]) async -> TextAnalysisResult {
        // Get character definitions (uses local + API)
        let charResults = await lookup(characters)

        // Get word groupings from Claude
        let words = await detectWords(in: text)

        return TextAnalysisResult(words: words, characters: charResults)
    }

    /// Detect compound words in text using Claude
    private func detectWords(in text: String) async -> [WordInfo] {
        // Check cache
        let cacheKey = text.filter { $0.isChineseCharacter }
        if let cached = wordCache[cacheKey] {
            return cached
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let prompt = """
        Analyze this Chinese text and break it into compound words (词语). For each word, give pinyin and English meaning.

        Text: \(text)

        Return JSON only:
        {
          "words": [
            {"word": "注意", "pinyin": "zhùyì", "meaning": "to pay attention, caution"},
            {"word": "安全", "pinyin": "ānquán", "meaning": "safety, safe"}
          ]
        }

        Rules:
        - Group characters into meaningful words (usually 2-4 characters)
        - Keep words in the order they appear in the text
        - Include ALL Chinese characters from the text in some word
        - Single characters that stand alone should be their own "word"
        """

        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "messages": [["role": "user", "content": prompt]]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return []
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]],
                  let firstContent = content.first,
                  let responseText = firstContent["text"] as? String else {
                return []
            }

            let jsonString = extractJSON(from: responseText)
            guard let jsonData = jsonString.data(using: .utf8),
                  let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let wordsArray = parsed["words"] as? [[String: Any]] else {
                return []
            }

            let words = wordsArray.compactMap { dict -> WordInfo? in
                guard let word = dict["word"] as? String,
                      let pinyin = dict["pinyin"] as? String,
                      let meaning = dict["meaning"] as? String else {
                    return nil
                }
                return WordInfo(word: word, pinyin: pinyin, meaning: meaning)
            }

            // Cache result
            wordCache[cacheKey] = words
            return words

        } catch {
            print("Word detection error: \(error)")
            return []
        }
    }

    /// Look up a character - tries local dictionary first, then API fallback
    func lookup(_ character: String) async -> CharacterInfo {
        // Try local dictionary first
        if let info = CharacterDictionary.lookup(character) {
            return info
        }

        // Check cache
        if let cached = cache[character] {
            return cached
        }

        // Fall back to API for unknown characters
        let results = await fetchFromClaude([character])
        if let info = results[character] {
            cache[character] = info
            return info
        }

        // Return unknown placeholder if all else fails
        return CharacterInfo.unknown(character: character)
    }

    /// Look up multiple characters efficiently
    func lookup(_ characters: [String]) async -> [String: CharacterInfo] {
        var results: [String: CharacterInfo] = [:]
        var unknownCharacters: [String] = []

        // First pass: get all local results and cached results
        for char in characters {
            if let info = CharacterDictionary.lookup(char) {
                results[char] = info
            } else if let cached = cache[char] {
                results[char] = cached
            } else {
                unknownCharacters.append(char)
            }
        }

        // Second pass: batch API lookup for unknowns
        if !unknownCharacters.isEmpty {
            let apiResults = await fetchFromClaude(unknownCharacters)
            for (char, info) in apiResults {
                results[char] = info
                cache[char] = info
            }

            // Fill in any remaining unknowns with placeholder
            for char in unknownCharacters where results[char] == nil {
                results[char] = CharacterInfo.unknown(character: char)
            }
        }

        return results
    }

    // MARK: - Claude API

    /// Fetch character definitions from Claude API
    private func fetchFromClaude(_ characters: [String]) async -> [String: CharacterInfo] {
        guard !characters.isEmpty else { return [:] }

        let charList = characters.joined(separator: ", ")

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let prompt = """
        For each of these Chinese characters, provide: pinyin (with tone marks), English meaning, HSK level (1-6, or 0 if not in HSK), radical, stroke count, 2 example words, and component characters (simpler characters that make up this one).

        Characters: \(charList)

        Respond in this exact JSON format (no other text):
        {
          "characters": [
            {
              "character": "落",
              "pinyin": "luò",
              "meaning": "to fall, to drop",
              "hsk": 2,
              "radical": "艹",
              "strokes": 12,
              "examples": ["落下 (fall down)", "降落 (descend)"],
              "components": [
                {"char": "艹", "pinyin": "cǎo", "meaning": "grass radical", "type": "semantic"},
                {"char": "洛", "pinyin": "luò", "meaning": "name of a river", "type": "phonetic"}
              ]
            }
          ]
        }

        Rules for components:
        - Only include meaningful sub-characters that are real Chinese characters
        - Simple characters (like 一, 人, 大) may have empty components []
        - Mark each component as "semantic" (contributes to meaning), "phonetic" (contributes to pronunciation), or "both"
        - Most characters are phono-semantic compounds: one semantic radical + one phonetic component
        """

        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 2048,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Claude API error: HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return [:]
            }

            // Parse Claude's response
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]],
                  let firstContent = content.first,
                  let text = firstContent["text"] as? String else {
                print("Failed to parse Claude response")
                return [:]
            }

            // Extract JSON from response (Claude might include markdown code blocks)
            let jsonString = extractJSON(from: text)

            guard let jsonData = jsonString.data(using: .utf8),
                  let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let charactersArray = parsed["characters"] as? [[String: Any]] else {
                print("Failed to parse character JSON")
                return [:]
            }

            // Convert to CharacterInfo
            var results: [String: CharacterInfo] = [:]
            for charDict in charactersArray {
                guard let char = charDict["character"] as? String else { continue }

                // Parse components
                var components: [ComponentInfo] = []
                if let componentsArray = charDict["components"] as? [[String: Any]] {
                    components = componentsArray.compactMap { compDict -> ComponentInfo? in
                        guard let compChar = compDict["char"] as? String,
                              let compPinyin = compDict["pinyin"] as? String,
                              let compMeaning = compDict["meaning"] as? String else {
                            return nil
                        }
                        let typeStr = compDict["type"] as? String ?? "semantic"
                        let compType: ComponentType = switch typeStr {
                            case "phonetic": .phonetic
                            case "both": .both
                            default: .semantic
                        }
                        return ComponentInfo(character: compChar, pinyin: compPinyin, meaning: compMeaning, type: compType)
                    }
                }

                let info = CharacterInfo(
                    pinyin: charDict["pinyin"] as? String ?? "",
                    meaning: charDict["meaning"] as? String ?? "Unknown",
                    hsk: charDict["hsk"] as? Int ?? 0,
                    radical: charDict["radical"] as? String ?? "",
                    strokes: charDict["strokes"] as? Int ?? 0,
                    examples: charDict["examples"] as? [String] ?? [],
                    components: components
                )
                results[char] = info
            }

            return results

        } catch {
            print("Claude API error: \(error)")
            return [:]
        }
    }

    /// Extract JSON from Claude's response (handles markdown code blocks)
    private func extractJSON(from text: String) -> String {
        // Try to find JSON in code blocks first
        if let start = text.range(of: "```json"),
           let end = text.range(of: "```", range: start.upperBound..<text.endIndex) {
            return String(text[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Try plain code blocks
        if let start = text.range(of: "```"),
           let end = text.range(of: "```", range: start.upperBound..<text.endIndex) {
            return String(text[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Try to find raw JSON
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }

        return text
    }
}
