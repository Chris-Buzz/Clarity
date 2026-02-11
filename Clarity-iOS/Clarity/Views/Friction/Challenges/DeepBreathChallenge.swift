import SwiftUI

/// Standalone breathing challenge for focus session friction.
/// 2 cycles of 4-7-8 breathing (inhale 4s, hold 7s, exhale 8s = 19s per cycle).
struct DeepBreathChallenge: View {

    let onComplete: () -> Void
    let onCancel: () -> Void

    private let inhaleDuration: Double = 4
    private let holdDuration: Double = 7
    private let exhaleDuration: Double = 8
    private var cycleDuration: Double { inhaleDuration + holdDuration + exhaleDuration }
    private let totalCycles = 2

    @State private var phase: String = "BREATHE IN"
    @State private var countdown: Int = 4
    @State private var circleScale: CGFloat = 0.5
    @State private var currentCycle = 1
    @State private var completed = false

    var body: some View {
        if completed {
            ChallengeSuccess("Centered", onDone: onComplete)
        } else {
            ChallengeTemplate(
                icon: "wind",
                iconColor: ClarityColors.primary,
                category: "Breathing",
                title: "4-7-8 Breathing",
                onCancel: onCancel
            ) {
                VStack(spacing: ClaritySpacing.md) {
                    // Breathing circle
                    ZStack {
                        Circle()
                            .fill(ClarityColors.primaryMuted)
                            .frame(width: 160, height: 160)
                            .scaleEffect(circleScale)

                        Circle()
                            .stroke(ClarityColors.primary, lineWidth: 3)
                            .frame(width: 160, height: 160)
                            .scaleEffect(circleScale)

                        Text("\(countdown)")
                            .font(ClarityFonts.serif(size: 48, weight: .bold))
                            .foregroundStyle(ClarityColors.textPrimary)
                    }

                    Text(phase)
                        .font(ClarityFonts.sans(size: 16))
                        .tracking(2)
                        .foregroundStyle(ClarityColors.textSecondary)

                    Text("Cycle \(currentCycle) of \(totalCycles)")
                        .font(ClarityFonts.sans(size: 13))
                        .foregroundStyle(ClarityColors.textTertiary)
                }
            }
            .onAppear { startCycle() }
        }
    }

    // MARK: - Cycle Logic

    private func startCycle() {
        // Inhale
        phase = "BREATHE IN"
        countdown = Int(inhaleDuration)
        runCountdown(from: Int(inhaleDuration), duration: inhaleDuration)

        withAnimation(.easeInOut(duration: inhaleDuration)) {
            circleScale = 1.0
        }

        // Hold
        DispatchQueue.main.asyncAfter(deadline: .now() + inhaleDuration) {
            phase = "HOLD"
            countdown = Int(holdDuration)
            runCountdown(from: Int(holdDuration), duration: holdDuration)
        }

        // Exhale
        DispatchQueue.main.asyncAfter(deadline: .now() + inhaleDuration + holdDuration) {
            phase = "BREATHE OUT"
            countdown = Int(exhaleDuration)
            runCountdown(from: Int(exhaleDuration), duration: exhaleDuration)

            withAnimation(.easeInOut(duration: exhaleDuration)) {
                circleScale = 0.5
            }
        }

        // End of cycle
        DispatchQueue.main.asyncAfter(deadline: .now() + cycleDuration) {
            if currentCycle < totalCycles {
                currentCycle += 1
                startCycle()
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    completed = true
                }
            }
        }
    }

    private func runCountdown(from start: Int, duration: Double) {
        let interval = duration / Double(start)
        for i in 1..<start {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                countdown = start - i
            }
        }
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        DeepBreathChallenge(onComplete: {}, onCancel: {})
            .padding()
    }
}
