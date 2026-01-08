import SwiftUI
import SwiftData

struct StudyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var characters: [CharacterCard]
    @State private var viewModel = FlashcardViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()

                if viewModel.isSessionComplete {
                    SessionCompleteView(
                        stats: viewModel.sessionStats,
                        onStudyAgain: { viewModel.loadDueCards(from: characters) }
                    )
                } else if let card = viewModel.currentCard {
                    studyContent(card)
                } else if characters.isEmpty {
                    emptyLibraryView
                } else {
                    noCardsDueView
                }
            }
            .navigationTitle("Study")
            .onAppear {
                if viewModel.deck.isEmpty {
                    viewModel.loadDueCards(from: characters)
                }
            }
        }
    }

    private func studyContent(_ card: CharacterCard) -> some View {
        VStack(spacing: 24) {
            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: viewModel.progress)
                    .tint(Color.theme.primary)

                Text("\(viewModel.currentIndex + 1) / \(viewModel.deck.count)")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textMuted)
            }
            .padding(.horizontal)

            Spacer()

            // Flashcard
            FlashcardView(card: card, isFlipped: viewModel.isFlipped)
                .onTapGesture {
                    if !viewModel.isFlipped {
                        viewModel.flipCard()
                    }
                }

            Spacer()

            // Rating buttons (shown when flipped)
            if viewModel.isFlipped {
                RatingButtons { rating in
                    viewModel.rateCard(rating)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Text("Tap card to reveal")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textMuted)
            }

            Spacer().frame(height: 20)
        }
        .animation(.easeInOut, value: viewModel.isFlipped)
    }

    private var emptyLibraryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundStyle(Color.theme.textMuted)

            Text("No Cards to Study")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.text)

            Text("Add characters to your library first by taking photos of Chinese text")
                .font(.body)
                .foregroundStyle(Color.theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var noCardsDueView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundStyle(Color.theme.success)

            Text("All Caught Up!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.text)

            Text("No cards due for review. Come back later or add more characters.")
                .font(.body)
                .foregroundStyle(Color.theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Show next review time
            if let nextCard = characters.min(by: { $0.nextReview < $1.nextReview }) {
                Text("Next review: \(nextCard.nextReview.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textMuted)
                    .padding(.top, 8)
            }

            Button("Refresh") {
                viewModel.loadDueCards(from: characters)
            }
            .buttonStyle(.bordered)
            .padding(.top)
        }
    }
}

#Preview {
    StudyView()
        .modelContainer(for: CharacterCard.self, inMemory: true)
}
