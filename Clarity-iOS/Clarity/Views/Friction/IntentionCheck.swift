import SwiftUI

/// Layer 3 friction (30 min). Asks the user to articulate what they are
/// hoping to find, requiring at least 10 characters before they can proceed.
struct IntentionCheck: View {

    let onComplete: () -> Void
    let onCancel: () -> Void

    /// Optional implementation intention to remind the user of (e.g. from settings).
    var implementationIntention: String? = nil

    @State private var response: String = ""
    @FocusState private var isFocused: Bool

    private var canContinue: Bool {
        response.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
    }

    var body: some View {
        VStack(spacing: ClaritySpacing.lg) {
            // Header
            Text("INTENTION CHECK")
                .font(ClarityFonts.mono(size: 10))
                .tracking(3)
                .foregroundStyle(ClarityColors.textMuted)

            // Icon
            Image(systemName: "questionmark.circle")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(ClarityColors.primary)
                .symbolEffect(.pulse, options: .repeating)

            Text("What are you hoping to find?")
                .font(ClarityFonts.serif(size: 26, weight: .bold))
                .foregroundStyle(ClarityColors.textPrimary)
                .multilineTextAlignment(.center)

            // Text input
            TextEditor(text: $response)
                .font(ClarityFonts.sans(size: 16))
                .foregroundStyle(ClarityColors.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(ClaritySpacing.sm)
                .frame(minHeight: 100)
                .background(ClarityColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: ClarityRadius.lg)
                        .stroke(isFocused ? ClarityColors.primary : ClarityColors.border, lineWidth: 1)
                )
                .focused($isFocused)

            // Implementation intention reminder
            if let intention = implementationIntention, !intention.isEmpty {
                HStack(spacing: ClaritySpacing.sm) {
                    Image(systemName: "lightbulb")
                        .foregroundStyle(ClarityColors.primary)
                        .font(.system(size: 14))

                    Text("Remember: \(intention)")
                        .font(ClarityFonts.sans(size: 13))
                        .foregroundStyle(ClarityColors.textSecondary)
                }
                .padding(ClaritySpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ClarityColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
            }

            // Continue
            ClarityButton("Continue", variant: .primary, fullWidth: true) {
                onComplete()
            }
            .opacity(canContinue ? 1.0 : 0.5)
            .disabled(!canContinue)

            // Cancel
            Button {
                HapticManager.light()
                onCancel()
            } label: {
                Text("Go back to what I was doing")
                    .font(ClarityFonts.sans(size: 14))
                    .foregroundStyle(ClarityColors.textMuted)
            }
        }
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        IntentionCheck(
            onComplete: {},
            onCancel: {},
            implementationIntention: "If I feel bored -> read a book instead"
        )
        .padding()
    }
}
