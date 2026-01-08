import SwiftUI

/// Rating buttons for flashcard review (SM-2 algorithm)
struct RatingButtons: View {
    let onRate: (ReviewRating) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(ReviewRating.allCases, id: \.self) { rating in
                RatingButton(rating: rating) {
                    onRate(rating)
                }
            }
        }
        .padding(.horizontal)
    }
}

private struct RatingButton: View {
    let rating: ReviewRating
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(rating.emoji)
                    .font(.title2)

                Text(rating.label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var backgroundColor: Color {
        switch rating {
        case .again:
            return Color.theme.danger
        case .hard:
            return Color.theme.warning
        case .good:
            return Color.theme.success
        case .easy:
            return Color.theme.secondary
        }
    }
}

#Preview {
    RatingButtons { rating in
        print("Rated: \(rating.label)")
    }
    .padding()
    .background(Color.theme.background)
}
