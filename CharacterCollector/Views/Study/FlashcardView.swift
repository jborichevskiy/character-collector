import SwiftUI

/// Flippable flashcard showing character on front, details on back
struct FlashcardView: View {
    let card: CharacterCard
    let isFlipped: Bool

    var body: some View {
        ZStack {
            // Front of card (character)
            cardFront
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 0 : 1)

            // Back of card (details)
            cardBack
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.4), value: isFlipped)
    }

    private var cardFront: some View {
        VStack(spacing: 16) {
            Spacer()

            Text(card.character)
                .font(.system(size: 120))
                .foregroundStyle(Color.theme.text)

            Spacer()

            Image(systemName: "hand.tap")
                .font(.title2)
                .foregroundStyle(Color.theme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
        .padding()
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        .padding(.horizontal)
    }

    private var cardBack: some View {
        VStack(spacing: 20) {
            // Character (smaller)
            Text(card.character)
                .font(.system(size: 60))
                .foregroundStyle(Color.theme.text)

            // Pinyin
            Text(card.pinyin)
                .font(.title)
                .foregroundStyle(Color.theme.accent)

            // Meaning
            Text(card.meaning)
                .font(.title3)
                .foregroundStyle(Color.theme.text)
                .multilineTextAlignment(.center)

            Divider()
                .background(Color.theme.textMuted.opacity(0.3))

            // Extra info
            HStack(spacing: 24) {
                if card.hsk > 0 {
                    InfoPill(label: "HSK", value: "\(card.hsk)")
                }
                if card.strokes > 0 {
                    InfoPill(label: "Strokes", value: "\(card.strokes)")
                }
                if !card.radical.isEmpty {
                    InfoPill(label: "Radical", value: card.radical)
                }
            }

            // Context if available
            if !card.context.isEmpty {
                VStack(spacing: 4) {
                    Text("Found in:")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textMuted)
                    Text(card.context)
                        .font(.caption)
                        .foregroundStyle(Color.theme.text)
                        .lineLimit(2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
        .padding()
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        .padding(.horizontal)
    }
}

private struct InfoPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(Color.theme.text)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.theme.textMuted)
        }
    }
}

#Preview("Front") {
    FlashcardView(
        card: {
            let card = CharacterCard(
                character: "好",
                pinyin: "hǎo",
                meaning: "good, well",
                hsk: 1,
                radical: "女",
                strokes: 6
            )
            card.context = "你好世界"
            return card
        }(),
        isFlipped: false
    )
    .background(Color.theme.background)
}

#Preview("Back") {
    FlashcardView(
        card: {
            let card = CharacterCard(
                character: "好",
                pinyin: "hǎo",
                meaning: "good, well",
                hsk: 1,
                radical: "女",
                strokes: 6
            )
            card.context = "你好世界"
            return card
        }(),
        isFlipped: true
    )
    .background(Color.theme.background)
}
