import SwiftUI

/// Challenge: Call someone you care about instead of scrolling.
struct CallSomeoneChallenge: View {

    let onComplete: () -> Void
    let onCancel: () -> Void

    /// Placeholder contact name (could be injected from contacts in future).
    var contactName: String = "someone you care about"

    @State private var completed = false

    var body: some View {
        if completed {
            ChallengeSuccess("Real connection made", onDone: onComplete)
        } else {
            ChallengeTemplate(
                icon: "phone.fill",
                iconColor: ClarityColors.success,
                category: "Connection",
                title: "Call \(contactName)",
                onCancel: onCancel
            ) {
                Text("A real conversation beats any feed.")
                    .font(ClarityFonts.sans(size: 15))
                    .foregroundStyle(ClarityColors.textSecondary)
                    .multilineTextAlignment(.center)

                ClarityButton("Make the Call", variant: .primary, fullWidth: true) {
                    // Open phone dialer
                    if let url = URL(string: "tel://"), UIApplication.shared.canOpenURL(url) {
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

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        CallSomeoneChallenge(onComplete: {}, onCancel: {})
    }
}
