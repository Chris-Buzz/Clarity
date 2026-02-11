import SwiftUI

/// Challenge: Articulate what you would rather be doing.
struct IntentionChallenge: View {

    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var response: String = ""
    @FocusState private var isFocused: Bool

    private var canSubmit: Bool {
        response.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
    }

    var body: some View {
        ChallengeTemplate(
            icon: "safari",
            iconColor: ClarityColors.primary,
            category: "Intention",
            title: "What would you rather be doing?",
            onCancel: onCancel
        ) {
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

            ClarityButton("Set Intention", variant: .primary, fullWidth: true) {
                onComplete()
            }
            .opacity(canSubmit ? 1.0 : 0.5)
            .disabled(!canSubmit)
        }
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        IntentionChallenge(onComplete: {}, onCancel: {})
    }
}
