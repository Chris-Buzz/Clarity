import SwiftUI

/// Challenge: Send a meaningful text to someone instead of scrolling.
struct TextLovedOneChallenge: View {

    let onComplete: () -> Void
    let onCancel: () -> Void

    private static let prompts = [
        "Tell someone you're thinking of them",
        "Ask a friend how they're doing",
        "Send a compliment to someone",
        "Check in on a family member",
        "Thank someone who helped you recently",
    ]

    @State private var prompt: String = prompts.randomElement()!
    @State private var completed = false

    var body: some View {
        if completed {
            ChallengeSuccess("Connection sent", onDone: onComplete)
        } else {
            ChallengeTemplate(
                icon: "bubble.left.fill",
                iconColor: .blue,
                category: "Connection",
                title: prompt,
                onCancel: onCancel
            ) {
                Text("Real connection is one message away.")
                    .font(ClarityFonts.sans(size: 15))
                    .foregroundStyle(ClarityColors.textSecondary)
                    .multilineTextAlignment(.center)

                ClarityButton("Open Messages", variant: .primary, fullWidth: true) {
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

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        TextLovedOneChallenge(onComplete: {}, onCancel: {})
    }
}
