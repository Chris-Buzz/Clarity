import SwiftUI

/// Emoji-based mood picker that returns a valence (-1..1) and label.
struct MoodCheckIn: View {

    struct Mood: Identifiable {
        let id = UUID()
        let emoji: String
        let label: String
        let valence: Double
    }

    static let moods: [Mood] = [
        Mood(emoji: "😊", label: "Content",  valence:  0.8),
        Mood(emoji: "😐", label: "Neutral",  valence:  0.0),
        Mood(emoji: "😔", label: "Sad",      valence: -0.6),
        Mood(emoji: "😤", label: "Stressed", valence: -0.4),
        Mood(emoji: "😰", label: "Anxious",  valence: -0.8),
    ]

    /// Called when the user taps a mood.
    var onSelect: ((_ valence: Double, _ label: String) -> Void)?

    @State private var selectedID: UUID?

    var body: some View {
        VStack(spacing: ClaritySpacing.md) {
            Text("How are you feeling?")
                .font(ClarityFonts.sansMedium(size: 18))
                .foregroundStyle(ClarityColors.textPrimary)

            HStack(spacing: ClaritySpacing.md) {
                ForEach(Self.moods) { mood in
                    moodButton(mood)
                }
            }

            // Show label of selected mood
            if let selected = Self.moods.first(where: { $0.id == selectedID }) {
                Text(selected.label)
                    .font(ClarityFonts.sans(size: 14))
                    .foregroundStyle(ClarityColors.textSecondary)
                    .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private func moodButton(_ mood: Mood) -> some View {
        let isSelected = mood.id == selectedID

        Button {
            HapticManager.light()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                selectedID = mood.id
            }
            onSelect?(mood.valence, mood.label)
        } label: {
            Text(mood.emoji)
                .font(.system(size: 36))
                .scaleEffect(isSelected ? 1.25 : 1.0)
                .padding(ClaritySpacing.sm)
                .background(
                    Circle()
                        .fill(isSelected ? ClarityColors.primaryMuted : Color.clear)
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? ClarityColors.primary : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isSelected)
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        MoodCheckIn { valence, label in
            print("\(label): \(valence)")
        }
    }
}
