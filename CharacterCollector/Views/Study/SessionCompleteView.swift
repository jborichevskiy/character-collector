import SwiftUI

/// View shown when a study session is complete
struct SessionCompleteView: View {
    let stats: SessionStats
    let onStudyAgain: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Celebration
            Text("🎉")
                .font(.system(size: 80))

            Text("Session Complete!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.text)

            // Stats
            HStack(spacing: 40) {
                StatBox(title: "Reviewed", value: "\(stats.reviewed)")
                StatBox(title: "Correct", value: "\(stats.correct)")
                StatBox(title: "Accuracy", value: String(format: "%.0f%%", stats.accuracy))
            }
            .padding()
            .background(Color.theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Encouragement message
            Text(encouragementMessage)
                .font(.body)
                .foregroundStyle(Color.theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            // Study again button
            Button {
                onStudyAgain()
            } label: {
                Label("Study Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.theme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }

    private var encouragementMessage: String {
        let accuracy = stats.accuracy

        if accuracy >= 90 {
            return "Excellent work! You're mastering these characters!"
        } else if accuracy >= 70 {
            return "Great job! Keep practicing to improve further."
        } else if accuracy >= 50 {
            return "Good effort! Regular practice will help these stick."
        } else {
            return "Keep going! Every review helps build memory."
        }
    }
}

private struct StatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.text)

            Text(title)
                .font(.caption)
                .foregroundStyle(Color.theme.textMuted)
        }
    }
}

#Preview {
    SessionCompleteView(
        stats: SessionStats(reviewed: 10, correct: 8),
        onStudyAgain: {}
    )
    .background(Color.theme.background)
}
