import SwiftUI
import SwiftData

/// Detailed view of a character with all its information
struct CharacterDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let card: CharacterCard
    var onDelete: (() -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Large character display
                    Text(card.character)
                        .font(.system(size: 120))
                        .foregroundStyle(Color.theme.text)
                        .padding(.top, 20)

                    // Pinyin and meaning
                    VStack(spacing: 8) {
                        Text(card.pinyin)
                            .font(.title2)
                            .foregroundStyle(Color.theme.accent)

                        Text(card.meaning)
                            .font(.title3)
                            .foregroundStyle(Color.theme.text)
                            .multilineTextAlignment(.center)
                    }

                    // Status badge
                    StatusBadge(status: card.status)

                    // Details grid
                    detailsGrid

                    // Examples
                    if !card.examples.isEmpty {
                        examplesSection
                    }

                    // Context (where it was found)
                    if !card.context.isEmpty {
                        contextSection
                    }

                    // Statistics
                    statisticsSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
            }
            .background(Color.theme.background)
            .navigationTitle("Character Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        deleteCard()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var detailsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            DetailCell(title: "Radical", value: card.radical.isEmpty ? "-" : card.radical)
            DetailCell(title: "Next Review", value: formatNextReview())
            DetailCell(title: "Reviews", value: "\(card.reviewCount)")
            DetailCell(title: "Interval", value: "\(card.interval) day\(card.interval == 1 ? "" : "s")")
        }
        .padding()
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatNextReview() -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(card.nextReview) {
            return "Today"
        } else if calendar.isDateInTomorrow(card.nextReview) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: card.nextReview)
        }
    }

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Examples")
                .font(.headline)
                .foregroundStyle(Color.theme.text)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(card.examples, id: \.self) { example in
                    Text("• \(example)")
                        .font(.body)
                        .foregroundStyle(Color.theme.textMuted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Found In")
                .font(.headline)
                .foregroundStyle(Color.theme.text)

            Text(card.context)
                .font(.body)
                .foregroundStyle(Color.theme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Study Statistics")
                .font(.headline)
                .foregroundStyle(Color.theme.text)

            HStack(spacing: 24) {
                StatItem(title: "Reviews", value: "\(card.reviewCount)")
                StatItem(title: "Correct", value: "\(card.correctCount)")
                StatItem(title: "Accuracy", value: String(format: "%.0f%%", SpacedRepetitionService.accuracy(for: card)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func deleteCard() {
        modelContext.delete(card)
        onDelete?()
        dismiss()
    }
}

private struct DetailCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.theme.textMuted)
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(Color.theme.text)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.text)
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.theme.textMuted)
        }
    }
}
