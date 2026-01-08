import Foundation

/// SM-2 spaced repetition algorithm implementation
enum SpacedRepetitionService {

    /// Result of applying the SM-2 algorithm
    struct ReviewResult {
        let interval: Int           // Days until next review
        let easeFactor: Double      // Updated ease factor
        let status: CharacterStatus // Updated mastery status
    }

    /// Apply SM-2 algorithm based on user rating
    ///
    /// The SM-2 algorithm adjusts review intervals based on how well
    /// the user remembers each card:
    /// - Again (1): Reset to 1 day, decrease ease
    /// - Hard (2): Small interval increase, slight ease decrease
    /// - Good (3): Normal interval increase using ease factor
    /// - Easy (4): Large interval increase, boost ease factor
    ///
    /// Cards are considered "mastered" when interval reaches 21+ days
    static func calculateNextReview(
        currentInterval: Int,
        currentEaseFactor: Double,
        rating: ReviewRating
    ) -> ReviewResult {
        var interval = currentInterval
        var easeFactor = currentEaseFactor
        var status: CharacterStatus = .learning

        switch rating {
        case .again:
            // Complete reset - user didn't remember
            interval = 1
            easeFactor = max(1.3, easeFactor - 0.2)
            status = .learning

        case .hard:
            // Small increase - user struggled
            interval = max(1, Int(Double(interval) * 1.2))
            easeFactor = max(1.3, easeFactor - 0.15)
            status = .learning

        case .good:
            // Normal progression
            interval = max(1, Int(Double(interval) * easeFactor))
            status = interval >= 21 ? .mastered : .learning

        case .easy:
            // Fast progression - user knew it well
            interval = max(1, Int(Double(interval) * easeFactor * 1.3))
            easeFactor = easeFactor + 0.15
            status = interval >= 21 ? .mastered : .learning
        }

        return ReviewResult(
            interval: interval,
            easeFactor: easeFactor,
            status: status
        )
    }

    /// Apply a review to a character card and update its properties
    static func applyReview(to card: CharacterCard, rating: ReviewRating) {
        let result = calculateNextReview(
            currentInterval: card.interval,
            currentEaseFactor: card.easeFactor,
            rating: rating
        )

        card.interval = result.interval
        card.easeFactor = result.easeFactor
        card.status = result.status
        card.reviewCount += 1

        if rating.rawValue >= 3 {
            card.correctCount += 1
        }

        // Calculate next review date
        card.nextReview = Calendar.current.date(
            byAdding: .day,
            value: result.interval,
            to: Date()
        ) ?? Date()
    }

    /// Check if a card is due for review
    static func isDue(_ card: CharacterCard) -> Bool {
        card.nextReview <= Date()
    }

    /// Get cards due for review from a collection
    static func getDueCards(from cards: [CharacterCard]) -> [CharacterCard] {
        let now = Date()
        return cards.filter { $0.nextReview <= now }
    }

    /// Calculate accuracy percentage for a card
    static func accuracy(for card: CharacterCard) -> Double {
        guard card.reviewCount > 0 else { return 0 }
        return Double(card.correctCount) / Double(card.reviewCount) * 100
    }
}
