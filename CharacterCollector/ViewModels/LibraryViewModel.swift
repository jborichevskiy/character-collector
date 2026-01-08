import SwiftUI
import SwiftData

/// ViewModel for library filtering and search
@Observable
final class LibraryViewModel {
    var searchText = ""
    var selectedFilter: CharacterStatus? = nil

    /// Filter characters based on search and status filter
    func filteredCharacters(_ characters: [CharacterCard]) -> [CharacterCard] {
        var result = characters

        // Apply status filter
        if let filter = selectedFilter {
            result = result.filter { $0.status == filter }
        }

        // Apply search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { card in
                card.character.contains(query) ||
                card.pinyin.lowercased().contains(query) ||
                card.meaning.lowercased().contains(query)
            }
        }

        // Sort by date added (newest first)
        return result.sorted { $0.dateAdded > $1.dateAdded }
    }

    /// Get count for each status
    func statusCounts(_ characters: [CharacterCard]) -> [CharacterStatus: Int] {
        var counts: [CharacterStatus: Int] = [:]
        for status in CharacterStatus.allCases {
            counts[status] = characters.filter { $0.status == status }.count
        }
        return counts
    }

    /// Clear all filters
    func clearFilters() {
        searchText = ""
        selectedFilter = nil
    }
}
