import SwiftUI

/// Badge showing character mastery status
struct StatusBadge: View {
    let status: CharacterStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch status {
        case .new:
            return Color.theme.statusNew
        case .learning:
            return Color.theme.statusLearning
        case .mastered:
            return Color.theme.statusMastered
        }
    }
}

/// Small dot indicator for status
struct StatusDot: View {
    let status: CharacterStatus

    var body: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 8, height: 8)
    }

    private var dotColor: Color {
        switch status {
        case .new:
            return Color.theme.statusNew
        case .learning:
            return Color.theme.statusLearning
        case .mastered:
            return Color.theme.statusMastered
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ForEach(CharacterStatus.allCases, id: \.self) { status in
            HStack {
                StatusBadge(status: status)
                StatusDot(status: status)
            }
        }
    }
    .padding()
    .background(Color.theme.background)
}
