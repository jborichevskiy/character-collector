import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CharacterCard.dateAdded, order: .reverse) private var characters: [CharacterCard]
    @State private var viewModel = LibraryViewModel()
    @State private var selectedCharacter: CharacterCard?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Filter buttons
                FilterBar(
                    selectedFilter: $viewModel.selectedFilter,
                    counts: viewModel.statusCounts(characters)
                )
                .padding(.vertical, 12)

                // Character grid or empty state
                let filtered = viewModel.filteredCharacters(characters)

                if characters.isEmpty {
                    emptyLibraryView
                } else if filtered.isEmpty {
                    noResultsView
                } else {
                    characterGrid(filtered)
                }
            }
            .background(Color.theme.background)
            .navigationTitle("Library")
            .sheet(item: $selectedCharacter) { card in
                CharacterDetailSheet(card: card)
            }
        }
    }

    private func characterGrid(_ cards: [CharacterCard]) -> some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 90, maximum: 120))],
                spacing: 12
            ) {
                ForEach(cards) { card in
                    LibraryGridItem(card: card)
                        .onTapGesture {
                            selectedCharacter = card
                        }
                }
            }
            .padding()
        }
    }

    private var emptyLibraryView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundStyle(Color.theme.textMuted)
            Text("No Characters Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.text)
            Text("Take a photo of Chinese text to start building your library")
                .font(.body)
                .foregroundStyle(Color.theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(Color.theme.textMuted)
            Text("No Results")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.text)
            Button("Clear Filters") {
                viewModel.clearFilters()
            }
            .buttonStyle(.bordered)
            Spacer()
        }
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.theme.textMuted)

            TextField("Search characters, pinyin, or meaning", text: $text)
                .textFieldStyle(.plain)
                .foregroundStyle(Color.theme.text)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.theme.textMuted)
                }
            }
        }
        .padding(12)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct FilterBar: View {
    @Binding var selectedFilter: CharacterStatus?
    let counts: [CharacterStatus: Int]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterButton(
                    title: "All",
                    count: counts.values.reduce(0, +),
                    isSelected: selectedFilter == nil
                ) {
                    selectedFilter = nil
                }

                ForEach(CharacterStatus.allCases, id: \.self) { status in
                    FilterButton(
                        title: status.displayName,
                        count: counts[status] ?? 0,
                        isSelected: selectedFilter == status,
                        color: statusColor(status)
                    ) {
                        selectedFilter = status
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func statusColor(_ status: CharacterStatus) -> Color {
        switch status {
        case .new: return Color.theme.statusNew
        case .learning: return Color.theme.statusLearning
        case .mastered: return Color.theme.statusMastered
        }
    }
}

struct FilterButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    var color: Color = Color.theme.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                Text("(\(count))")
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color.theme.surface)
            .foregroundStyle(isSelected ? .white : Color.theme.text)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: CharacterCard.self, inMemory: true)
}
