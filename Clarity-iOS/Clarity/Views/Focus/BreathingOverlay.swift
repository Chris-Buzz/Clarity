import SwiftUI

/// 4-7-8 breathing exercise overlay — 2 full cycles before auto-dismiss.
/// Acts as a friction barrier when the user tries to exit a focus session.
struct BreathingOverlay: View {

    /// Called when all cycles are complete.
    let onComplete: () -> Void

    // MARK: - Phase Model

    private enum Phase: String {
        case inhale  = "BREATHE IN"
        case hold    = "HOLD"
        case exhale  = "BREATHE OUT"

        var duration: Int {
            switch self {
            case .inhale: return 4
            case .hold:   return 7
            case .exhale: return 8
            }
        }

        var next: Phase {
            switch self {
            case .inhale: return .hold
            case .hold:   return .exhale
            case .exhale: return .inhale
            }
        }
    }

    @State private var phase: Phase = .inhale
    @State private var countdown: Int = 4
    @State private var cyclesRemaining: Int = 2
    @State private var circleScale: CGFloat = 0.6
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            // Heavy overlay background
            ClarityColors.overlayHeavy.ignoresSafeArea()

            VStack(spacing: ClaritySpacing.xl) {
                Spacer()

                // MARK: - Breathing Circle

                ZStack {
                    Circle()
                        .fill(ClarityColors.primary.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .scaleEffect(circleScale)

                    Circle()
                        .stroke(ClarityColors.primary, lineWidth: 2)
                        .frame(width: 200, height: 200)
                        .scaleEffect(circleScale)

                    // Countdown number
                    Text("\(countdown)")
                        .font(ClarityFonts.serif(size: 48))
                        .foregroundStyle(ClarityColors.textPrimary)
                        .contentTransition(.numericText())
                }

                // MARK: - Phase Label

                Text(phase.rawValue)
                    .font(ClarityFonts.sans(size: 16))
                    .tracking(4)
                    .foregroundStyle(ClarityColors.textSecondary)

                // MARK: - Cycle Counter

                Text("\(cyclesRemaining) cycles remaining")
                    .font(ClarityFonts.mono(size: 12))
                    .foregroundStyle(ClarityColors.textMuted)

                Spacer()
            }
        }
        .onAppear {
            startPhase(.inhale)
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Phase Logic

    private func startPhase(_ newPhase: Phase) {
        phase = newPhase
        countdown = newPhase.duration

        // Animate circle based on phase
        let targetScale: CGFloat
        switch newPhase {
        case .inhale: targetScale = 1.0
        case .hold:   targetScale = 1.0  // Stay expanded
        case .exhale: targetScale = 0.6
        }

        withAnimation(.easeInOut(duration: Double(newPhase.duration))) {
            circleScale = targetScale
        }

        // Tick the countdown
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            tick()
        }
    }

    private func tick() {
        countdown -= 1

        if countdown <= 0 {
            timer?.invalidate()

            let next = phase.next

            // If exhale just ended, that's one full cycle
            if phase == .exhale {
                cyclesRemaining -= 1

                if cyclesRemaining <= 0 {
                    // Done — dismiss
                    HapticManager.success()
                    onComplete()
                    return
                }
            }

            startPhase(next)
        }
    }
}

#Preview {
    BreathingOverlay {
        print("Done")
    }
}
