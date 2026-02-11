import SwiftUI

/// Challenge: Step outside for 1 minute.
struct GoOutsideChallenge: View {

    let onComplete: () -> Void
    let onCancel: () -> Void

    private let totalSeconds = 60

    @State private var secondsLeft: Int = 60
    @State private var timerStarted = false
    @State private var completed = false

    var body: some View {
        if completed {
            ChallengeSuccess("Fresh air hits different", onDone: onComplete)
        } else {
            ChallengeTemplate(
                icon: "leaf.fill",
                iconColor: ClarityColors.success,
                category: "Nature",
                title: "Step outside for 1 minute",
                onCancel: onCancel
            ) {
                if timerStarted {
                    // Countdown
                    ZStack {
                        Circle()
                            .stroke(ClarityColors.border, lineWidth: 4)
                            .frame(width: 100, height: 100)

                        Circle()
                            .trim(from: 0, to: CGFloat(totalSeconds - secondsLeft) / CGFloat(totalSeconds))
                            .stroke(ClarityColors.success, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))

                        Text("\(secondsLeft)s")
                            .font(ClarityFonts.serif(size: 32, weight: .bold))
                            .foregroundStyle(ClarityColors.textPrimary)
                    }
                } else {
                    Text("Fresh air and sunlight reset your brain.")
                        .font(ClarityFonts.sans(size: 15))
                        .foregroundStyle(ClarityColors.textSecondary)
                        .multilineTextAlignment(.center)

                    ClarityButton("I'm Outside", variant: .primary, fullWidth: true) {
                        HapticManager.medium()
                        timerStarted = true
                        startTimer()
                    }
                }
            }
        }
    }

    private func startTimer() {
        for i in 1...totalSeconds {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
                secondsLeft = totalSeconds - i
                if secondsLeft == 0 {
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
        GoOutsideChallenge(onComplete: {}, onCancel: {})
    }
}
