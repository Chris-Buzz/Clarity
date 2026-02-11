import SwiftUI

/// Challenge: Put the phone down and go drink water.
struct DrinkWaterChallenge: View {

    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var completed = false

    var body: some View {
        if completed {
            ChallengeSuccess("Body over screen", onDone: onComplete)
        } else {
            ChallengeTemplate(
                icon: "drop.fill",
                iconColor: .blue,
                category: "Hydration",
                title: "Drink a glass of water",
                onCancel: onCancel
            ) {
                Text("Put the phone down. Go get water.")
                    .font(ClarityFonts.sans(size: 15))
                    .foregroundStyle(ClarityColors.textSecondary)
                    .multilineTextAlignment(.center)

                ClarityButton("I Drank Water", variant: .primary, fullWidth: true) {
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
        DrinkWaterChallenge(onComplete: {}, onCancel: {})
    }
}
