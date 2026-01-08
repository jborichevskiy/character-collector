import SwiftUI

/// Grid cell for displaying a character in the library
struct LibraryGridItem: View {
    let card: CharacterCard

    var body: some View {
        VStack(spacing: 4) {
            // Character
            Text(card.character)
                .font(.system(size: 40))
                .foregroundStyle(Color.theme.text)

            // Pinyin
            Text(card.pinyin)
                .font(.caption)
                .foregroundStyle(Color.theme.accent)
                .lineLimit(1)

            // Status dot
            StatusDot(status: card.status)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HStack {
        LibraryGridItem(card: {
            let card = CharacterCard(
                character: "好",
                pinyin: "hǎo",
                meaning: "good",
                hsk: 1
            )
            return card
        }())

        LibraryGridItem(card: {
            let card = CharacterCard(
                character: "学",
                pinyin: "xué",
                meaning: "study"
            )
            card.status = .learning
            return card
        }())

        LibraryGridItem(card: {
            let card = CharacterCard(
                character: "中",
                pinyin: "zhōng",
                meaning: "middle"
            )
            card.status = .mastered
            return card
        }())
    }
    .padding()
    .background(Color.theme.background)
}
