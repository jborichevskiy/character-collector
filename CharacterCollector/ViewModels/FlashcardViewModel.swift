import SwiftUI
import SwiftData

/// Statistics for a study session
struct SessionStats {
    var reviewed: Int = 0
    var correct: Int = 0

    var accuracy: Double {
        guard reviewed > 0 else { return 0 }
        return Double(correct) / Double(reviewed) * 100
    }
}

/// ViewModel for flashcard study sessions
@Observable
final class FlashcardViewModel {
    // Deck state
    private(set) var deck: [CharacterCard] = []
    private(set) var currentIndex = 0
    var isFlipped = false

    // Session tracking
    var sessionStats = SessionStats()
    var isSessionComplete = false

    /// Current card being studied
    var currentCard: CharacterCard? {
        guard currentIndex < deck.count else { return nil }
        return deck[currentIndex]
    }

    /// Progress through the deck (0.0 to 1.0)
    var progress: Double {
        guard !deck.isEmpty else { return 0 }
        return Double(currentIndex) / Double(deck.count)
    }

    /// Number of cards remaining
    var cardsRemaining: Int {
        max(0, deck.count - currentIndex)
    }

    /// Load cards that are due for review
    func loadDueCards(from characters: [CharacterCard]) {
        deck = SpacedRepetitionService.getDueCards(from: characters).shuffled()
        currentIndex = 0
        isFlipped = false
        sessionStats = SessionStats()
        isSessionComplete = false
    }

    /// Flip the current card to show the answer
    func flipCard() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isFlipped = true
        }
    }

    /// Rate the current card and move to next
    func rateCard(_ rating: ReviewRating) {
        guard let card = currentCard else { return }

        // Update session stats
        sessionStats.reviewed += 1
        if rating.rawValue >= 3 {
            sessionStats.correct += 1
        }

        // Apply SM-2 algorithm
        SpacedRepetitionService.applyReview(to: card, rating: rating)

        // Move to next card
        currentIndex += 1
        isFlipped = false

        // Check if session is complete
        if currentIndex >= deck.count {
            isSessionComplete = true
        }
    }

    /// Start a new session with the same cards
    func restartSession() {
        deck.shuffle()
        currentIndex = 0
        isFlipped = false
        sessionStats = SessionStats()
        isSessionComplete = false
    }
}
