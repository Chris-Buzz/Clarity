import SwiftUI
import SwiftData

/// Step 5: Multi-select goal cards with optional custom text input.
struct GoalSettingStep: View {

    let onContinue: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var selectedGoals: Set<String> = []
    @State private var customGoal: String = ""

    private let goals: [(title: String, icon: String)] = [
        ("Reduce mindless scrolling", "hand.raised.fill"),
        ("Better sleep", "moon.fill"),
        ("More real connection", "person.2.fill"),
        ("Be more present", "eye.fill"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ClaritySpacing.lg) {
                // Header
                VStack(spacing: ClaritySpacing.sm) {
                    Text("What's Your Goal?")
                        .font(ClarityFonts.serif(size: 28, weight: .bold))
                        .foregroundStyle(ClarityColors.textPrimary)

                    Text("No judgment. Just clarity.")
                        .font(ClarityFonts.sans(size: 15))
                        .foregroundStyle(ClarityColors.textTertiary)
                }
                .padding(.top, ClaritySpacing.lg)

                // Goal cards
                VStack(spacing: ClaritySpacing.sm) {
                    ForEach(goals, id: \.title) { goal in
                        goalCard(title: goal.title, icon: goal.icon)
                    }
                }
                .padding(.horizontal, ClaritySpacing.lg)

                // Custom input
                HStack(spacing: ClaritySpacing.sm) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                        .foregroundStyle(ClarityColors.textMuted)

                    TextField("", text: $customGoal, prompt: Text("Something else...")
                        .foregroundStyle(ClarityColors.textMuted))
                        .font(ClarityFonts.sans(size: 15))
                        .foregroundStyle(ClarityColors.textPrimary)
                }
                .padding(ClaritySpacing.md)
                .background(ClarityColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.lg))
                .padding(.horizontal, ClaritySpacing.lg)

                // Continue
                ClarityButton(
                    "Continue",
                    variant: .primary,
                    size: .lg,
                    fullWidth: true
                ) {
                    saveAndContinue()
                }
                .padding(.horizontal, ClaritySpacing.lg)
                .padding(.bottom, ClaritySpacing.xl)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedGoals)
    }

    // MARK: - Goal Card

    private func goalCard(title: String, icon: String) -> some View {
        let isSelected = selectedGoals.contains(title)

        return Button {
            HapticManager.light()
            if isSelected {
                selectedGoals.remove(title)
            } else {
                selectedGoals.insert(title)
            }
        } label: {
            HStack(spacing: ClaritySpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? ClarityColors.primary : ClarityColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(isSelected ? ClarityColors.primaryMuted : ClarityColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.sm))

                Text(title)
                    .font(ClarityFonts.sansMedium(size: 15))
                    .foregroundStyle(ClarityColors.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(ClarityColors.primary)
                        .transition(.scale)
                }
            }
            .padding(ClaritySpacing.md)
            .background(isSelected ? ClarityColors.primaryMuted.opacity(0.5) : ClarityColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: ClarityRadius.lg)
                    .stroke(
                        isSelected ? ClarityColors.primary : ClarityColors.border,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Actions

    private func saveAndContinue() {
        var allGoals = Array(selectedGoals)
        let trimmed = customGoal.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            allGoals.append(trimmed)
        }

        if let profile = profiles.first {
            profile.goals = allGoals
        }

        onContinue()
    }
}

/// Subtle press scale for cards.
private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        GoalSettingStep {}
    }
    .modelContainer(for: UserProfile.self, inMemory: true)
}
