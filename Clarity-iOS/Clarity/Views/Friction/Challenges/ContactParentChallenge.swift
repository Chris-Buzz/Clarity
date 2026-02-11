import SwiftUI

/// Challenge: Call or text your parents.
struct ContactParentChallenge: View {

    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var isCallVariant: Bool = Bool.random()
    @State private var completed = false

    var body: some View {
        if completed {
            ChallengeSuccess(
                "Family first",
                subtitle: "They won't be around forever.",
                onDone: onComplete
            )
        } else {
            ChallengeTemplate(
                icon: "house.fill",
                iconColor: ClarityColors.warning,
                category: "Family",
                title: isCallVariant ? "Call Mom or Dad" : "Text your parents",
                onCancel: onCancel
            ) {
                Text("The people who matter most.")
                    .font(ClarityFonts.sans(size: 15))
                    .foregroundStyle(ClarityColors.textSecondary)

                HStack(spacing: ClaritySpacing.md) {
                    ClarityButton("Call", variant: .primary) {
                        if let url = URL(string: "tel://"), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            completed = true
                        }
                    }

                    ClarityButton("Text", variant: .secondary) {
                        if let url = URL(string: "sms://"), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            completed = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        ContactParentChallenge(onComplete: {}, onCancel: {})
    }
}
