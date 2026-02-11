import SwiftUI
import SwiftData

/// Step 6: Build 1-3 if-then implementation intentions and save to SwiftData.
struct IntentionBuilderStep: View {

    let onContinue: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var intentions: [IntentionDraft] = [IntentionDraft()]

    private let triggers = ["bored", "stressed", "lonely", "restless", "can't sleep"]

    /// Suggested actions mapped by trigger keyword
    private let actionSuggestions: [String: [String]] = [
        "bored": ["take a walk", "read a page", "do a pushup", "drink water"],
        "stressed": ["do breathing", "journal", "stretch", "listen to music"],
        "lonely": ["call a friend", "write a letter", "visit a neighbor", "go outside"],
        "restless": ["take a walk", "do pushups", "clean something", "cook a meal"],
        "can't sleep": ["do breathing", "read a book", "drink tea", "write thoughts down"],
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ClaritySpacing.lg) {
                // Header
                VStack(spacing: ClaritySpacing.sm) {
                    Text("Build Your Intentions")
                        .font(ClarityFonts.serif(size: 28, weight: .bold))
                        .foregroundStyle(ClarityColors.textPrimary)

                    Text("If-then plans have 84% follow-through")
                        .font(ClarityFonts.sans(size: 15))
                        .foregroundStyle(ClarityColors.textTertiary)
                }
                .padding(.top, ClaritySpacing.lg)

                // Template hint
                Text("If I feel the urge to open [app], I will [action] instead")
                    .font(ClarityFonts.sansLight(size: 13))
                    .foregroundStyle(ClarityColors.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ClaritySpacing.xl)

                // Intention cards
                ForEach(Array(intentions.enumerated()), id: \.element.id) { index, _ in
                    intentionCard(index: index)
                }
                .padding(.horizontal, ClaritySpacing.lg)

                // Add another (max 3)
                if intentions.count < 3 {
                    ClarityButton(
                        "Add another intention",
                        variant: .ghost,
                        size: .sm
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            intentions.append(IntentionDraft())
                        }
                        HapticManager.light()
                    }
                }

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
    }

    // MARK: - Intention Card

    private func intentionCard(index: Int) -> some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.md) {
            // "When I feel..."
            Text("WHEN I FEEL")
                .font(ClarityFonts.mono(size: 10))
                .tracking(2)
                .foregroundStyle(ClarityColors.textMuted)

            // Trigger picker — horizontal scroll of chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ClaritySpacing.sm) {
                    ForEach(triggers, id: \.self) { trigger in
                        chipButton(
                            label: trigger,
                            isSelected: intentions[index].trigger == trigger
                        ) {
                            intentions[index].trigger = trigger
                            // Reset action when trigger changes
                            intentions[index].action = ""
                        }
                    }
                }
            }

            // "I will..."
            Text("I WILL")
                .font(ClarityFonts.mono(size: 10))
                .tracking(2)
                .foregroundStyle(ClarityColors.textMuted)

            // Action suggestions (based on selected trigger)
            let suggestions = actionSuggestions[intentions[index].trigger] ?? []
            if !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ClaritySpacing.sm) {
                        ForEach(suggestions, id: \.self) { action in
                            chipButton(
                                label: action,
                                isSelected: intentions[index].action == action
                            ) {
                                intentions[index].action = action
                            }
                        }
                    }
                }
            }

            // Custom action input
            TextField("", text: $intentions[index].customAction, prompt: Text("Or type your own...")
                .foregroundStyle(ClarityColors.textMuted))
                .font(ClarityFonts.sans(size: 14))
                .foregroundStyle(ClarityColors.textPrimary)
                .padding(ClaritySpacing.sm)
                .background(ClarityColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.sm))
        }
        .padding(ClaritySpacing.md)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.lg))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Chip Button

    private func chipButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            withAnimation(.spring(response: 0.25)) { action() }
        } label: {
            Text(label)
                .font(ClarityFonts.sans(size: 13))
                .foregroundStyle(isSelected ? ClarityColors.primary : ClarityColors.textSecondary)
                .padding(.horizontal, ClaritySpacing.md)
                .padding(.vertical, ClaritySpacing.sm)
                .background(isSelected ? ClarityColors.primaryMuted : ClarityColors.surfaceElevated)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        isSelected ? ClarityColors.primary.opacity(0.5) : Color.clear,
                        lineWidth: 1
                    )
                )
        }
    }

    // MARK: - Actions

    private func saveAndContinue() {
        for draft in intentions {
            let resolvedAction = draft.customAction.trimmingCharacters(in: .whitespaces).isEmpty
                ? draft.action
                : draft.customAction.trimmingCharacters(in: .whitespaces)

            guard !draft.trigger.isEmpty, !resolvedAction.isEmpty else { continue }

            let intention = ImplementationIntention(
                triggerCondition: draft.trigger,
                intendedAction: resolvedAction
            )
            modelContext.insert(intention)
        }

        onContinue()
    }
}

// MARK: - Draft Model

/// Ephemeral model for building an intention before persisting.
private struct IntentionDraft: Identifiable {
    let id = UUID()
    var trigger: String = ""
    var action: String = ""
    var customAction: String = ""
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        IntentionBuilderStep {}
    }
    .modelContainer(for: ImplementationIntention.self, inMemory: true)
}
