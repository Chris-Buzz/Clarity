import SwiftUI

/// Level 5 friction — the doomscroll breaker.
/// Reveals mindful prompts one at a time with 3-second delays,
/// requiring the user to read through all of them before continuing.
struct ScrollFrictionShield: View {

    var onComplete: () -> Void

    @State private var visiblePrompts: Int = 0
    @State private var allRevealed = false

    private let prompts = [
        "You have been scrolling for a while.",
        "What were you originally looking for?",
        "Is this making you feel better or worse?",
        "Take a deep breath.",
        "Ready to be intentional?",
    ]

    var body: some View {
        ZStack {
            // Patience gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.03, green: 0.1, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: ClaritySpacing.xl) {
                Spacer()

                // Prompts revealed one at a time
                VStack(spacing: ClaritySpacing.lg) {
                    ForEach(0..<prompts.count, id: \.self) { index in
                        if index < visiblePrompts {
                            Text(prompts[index])
                                .font(index == prompts.count - 1 ? ClarityFonts.serif(size: 24) : ClarityFonts.sans(size: 18))
                                .foregroundStyle(.white.opacity(index == visiblePrompts - 1 ? 0.9 : 0.5))
                                .multilineTextAlignment(.center)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
                .padding(.horizontal, ClaritySpacing.xl)

                Spacer()

                // Continue button (only after all prompts revealed)
                if allRevealed {
                    ClarityButton("Continue with intention", variant: .primary, size: .lg, fullWidth: true) {
                        HapticManager.success()
                        onComplete()
                    }
                    .padding(.horizontal, ClaritySpacing.xl)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer().frame(height: ClaritySpacing.xxl)
            }
        }
        .onAppear {
            HapticManager.light()
            revealPrompts()
        }
    }

    // MARK: - Prompt Reveal Sequence

    private func revealPrompts() {
        for i in 0..<prompts.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 3.0) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    visiblePrompts = i + 1
                }
                HapticManager.light()
            }
        }

        // Show continue button after all prompts
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(prompts.count) * 3.0) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                allRevealed = true
            }
        }
    }
}

#Preview {
    ScrollFrictionShield(onComplete: {})
}
