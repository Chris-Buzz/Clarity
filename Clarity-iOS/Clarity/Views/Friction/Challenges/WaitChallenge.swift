import SwiftUI

/// Challenge: Wait 30 seconds doing nothing. Sit with the discomfort.
struct WaitChallenge: View {

    let onComplete: () -> Void
    let onCancel: () -> Void

    private let waitSeconds = 30

    @State private var secondsLeft: Int = 30
    @State private var timerDone = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        if timerDone {
            // Post-wait decision
            VStack(spacing: ClaritySpacing.lg) {
                Text("Still want to scroll?")
                    .font(ClarityFonts.serif(size: 24, weight: .bold))
                    .foregroundStyle(ClarityColors.textPrimary)

                ClarityButton("Continue", variant: .secondary, fullWidth: true) {
                    onComplete()
                }

                Button {
                    HapticManager.light()
                    onCancel()
                } label: {
                    Text("Actually, I'll do something else")
                        .font(ClarityFonts.sansMedium(size: 15))
                        .foregroundStyle(ClarityColors.success)
                }
            }
            .transition(.opacity)
        } else {
            ChallengeTemplate(
                icon: "hourglass",
                iconColor: ClarityColors.warning,
                category: "Patience",
                title: "Just wait.",
                onCancel: onCancel
            ) {
                Text("Sit with the discomfort.")
                    .font(ClarityFonts.sans(size: 15))
                    .foregroundStyle(ClarityColors.textSecondary)

                // Pulsing countdown circle
                ZStack {
                    Circle()
                        .fill(ClarityColors.warningMuted)
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseScale)

                    Circle()
                        .stroke(ClarityColors.warning, lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseScale)

                    Text("\(secondsLeft)")
                        .font(ClarityFonts.serif(size: 44, weight: .bold))
                        .foregroundStyle(ClarityColors.textPrimary)
                }
                .onAppear { startTimer() }
            }
        }
    }

    // MARK: - Timer

    private func startTimer() {
        // Pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
        }

        // Countdown
        for i in 1...waitSeconds {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
                secondsLeft = waitSeconds - i
                if secondsLeft == 0 {
                    HapticManager.success()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        timerDone = true
                    }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        WaitChallenge(onComplete: {}, onCancel: {})
    }
}
