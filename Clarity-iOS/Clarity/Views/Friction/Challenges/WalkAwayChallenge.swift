import SwiftUI

/// Challenge: Walk to another room before continuing.
struct WalkAwayChallenge: View {

    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var completed = false

    var body: some View {
        if completed {
            ChallengeSuccess("Movement over stagnation", onDone: onComplete)
        } else {
            ChallengeTemplate(
                icon: "figure.walk",
                iconColor: ClarityColors.success,
                category: "Movement",
                title: "Walk to another room",
                onCancel: onCancel
            ) {
                Text("Change your environment. Move your body.")
                    .font(ClarityFonts.sans(size: 15))
                    .foregroundStyle(ClarityColors.textSecondary)
                    .multilineTextAlignment(.center)

                ClarityButton("I Moved", variant: .primary, fullWidth: true) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        completed = true
                    }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        WalkAwayChallenge(onComplete: {}, onCancel: {})
    }
}
