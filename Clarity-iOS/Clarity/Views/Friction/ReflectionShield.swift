import SwiftUI

/// Layer 4 friction (45 min). Mood check-in that provides contextual guidance
/// based on how the user is feeling, then offers two clear exit paths.
struct ReflectionShield: View {

    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var selectedMood: (valence: Double, label: String)?
    @State private var showOptions = false

    var body: some View {
        VStack(spacing: ClaritySpacing.lg) {
            // Header
            Text("CHECK IN WITH YOURSELF")
                .font(ClarityFonts.mono(size: 10))
                .tracking(3)
                .foregroundStyle(ClarityColors.textMuted)

            Text("How are you feeling right now?")
                .font(ClarityFonts.serif(size: 24, weight: .bold))
                .foregroundStyle(ClarityColors.textPrimary)
                .multilineTextAlignment(.center)

            // Mood picker (shared component)
            MoodCheckIn { valence, label in
                HapticManager.medium()
                selectedMood = (valence, label)

                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showOptions = true
                }
            }

            // Contextual message + options
            if showOptions, let mood = selectedMood {
                VStack(spacing: ClaritySpacing.md) {
                    contextualMessage(for: mood)
                        .font(ClarityFonts.sans(size: 15))
                        .foregroundStyle(ClarityColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, ClaritySpacing.sm)

                    // Option 1: Leave (encouraged)
                    optionCard(
                        title: "Do something else",
                        icon: "checkmark.circle",
                        tintColor: ClarityColors.success,
                        action: onCancel
                    )

                    // Option 2: Continue anyway
                    optionCard(
                        title: "Continue anyway",
                        icon: "arrow.right.circle",
                        tintColor: ClarityColors.textMuted,
                        action: onComplete
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    // MARK: - Contextual Message

    @ViewBuilder
    private func contextualMessage(for mood: (valence: Double, label: String)) -> some View {
        if mood.valence < 0 {
            Text("It sounds like you're feeling \(mood.label.lowercased()). Scrolling won't help with that.")
        } else {
            Text("You're feeling good! Is this app adding to that?")
        }
    }

    // MARK: - Option Card

    private func optionCard(
        title: String,
        icon: String,
        tintColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            HStack(spacing: ClaritySpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(tintColor)

                Text(title)
                    .font(ClarityFonts.sansMedium(size: 16))
                    .foregroundStyle(ClarityColors.textPrimary)

                Spacer()
            }
            .padding(ClaritySpacing.md)
            .background(ClarityColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: ClarityRadius.lg)
                    .stroke(ClarityColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(ScalePressStyle())
    }
}

/// Press animation reused from ClarityButton.
private struct ScalePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        ReflectionShield(onComplete: {}, onCancel: {})
            .padding()
    }
}
