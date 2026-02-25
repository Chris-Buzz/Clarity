import SwiftUI

/// Layer 3 friction (30 min). Asks the user to declare their intent for opening the app,
/// requiring at least 10 characters before they can proceed.
struct IntentionCheck: View {

    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var response: String = ""
    @State private var showBrowsingPrompt = false
    @FocusState private var isFocused: Bool

    private let presetIntents = ["Messaging someone", "Checking something specific", "Just browsing", "Work related"]

    private var canContinue: Bool {
        response.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
    }

    var body: some View {
        VStack(spacing: ClaritySpacing.lg) {
            // Header
            Text("INTENT DECLARATION")
                .font(ClarityFonts.mono(size: 10))
                .tracking(3)
                .foregroundStyle(ClarityColors.textMuted)

            // Icon
            Image(systemName: "questionmark.circle")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(ClarityColors.primary)
                .symbolEffect(.pulse, options: .repeating)

            Text("What are you opening this for?")
                .font(ClarityFonts.serif(size: 26, weight: .bold))
                .foregroundStyle(ClarityColors.textPrimary)
                .multilineTextAlignment(.center)

            // Preset intent chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ClaritySpacing.sm) {
                    ForEach(presetIntents, id: \.self) { intent in
                        Button {
                            HapticManager.light()
                            response = intent
                            if intent == "Just browsing" {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    showBrowsingPrompt = true
                                }
                            } else {
                                showBrowsingPrompt = false
                            }
                        } label: {
                            Text(intent)
                                .font(ClarityFonts.sans(size: 13))
                                .foregroundStyle(response == intent ? .white : .white.opacity(0.6))
                                .padding(.horizontal, ClaritySpacing.md)
                                .padding(.vertical, ClaritySpacing.sm)
                                .background(response == intent ? ClarityColors.primaryMuted : ClarityColors.surface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            response == intent ? ClarityColors.primary.opacity(0.5) : ClarityColors.borderSubtle,
                                            lineWidth: 1
                                        )
                                )
                        }
                    }
                }
            }

            // Browsing prompt
            if showBrowsingPrompt {
                Text("Consider doing something analog instead.")
                    .font(ClarityFonts.sans(size: 14))
                    .foregroundStyle(ClarityColors.teal)
                    .transition(.opacity)
            }

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
                Text("I choose to skip this")
                    .font(ClarityFonts.sans(size: 14))
                    .foregroundStyle(ClarityColors.textMuted)
            }
        }
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        IntentionCheck(onComplete: {}, onCancel: {})
            .padding()
    }
}
