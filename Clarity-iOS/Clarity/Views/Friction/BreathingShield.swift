import SwiftUI

/// Layer 2 friction (15 min). Guides the user through one 4-4-4 breathing cycle
/// before allowing them to continue.
struct BreathingShield: View {

    let onComplete: () -> Void
    let onCancel: () -> Void

    // Each phase is 4 seconds; one full cycle = 12s
    private let phaseDuration: Double = 4.0

    @State private var phase: BreathPhase = .inhale
    @State private var cycleComplete = false
    @State private var countdown: Int = 4
    @State private var circleScale: CGFloat = 0.6

    private enum BreathPhase: String {
        case inhale = "BREATHE IN"
        case hold   = "HOLD"
        case exhale = "BREATHE OUT"
    }

    var body: some View {
        VStack(spacing: ClaritySpacing.lg) {
            // Header
            Text("PAUSE AND BREATHE")
                .font(ClarityFonts.mono(size: 10))
                .tracking(3)
                .foregroundStyle(ClarityColors.textMuted)

            Text("Take a moment")
                .font(ClarityFonts.serif(size: 28, weight: .bold))
                .foregroundStyle(ClarityColors.textPrimary)

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
            .padding(.vertical, ClaritySpacing.md)

            // Phase label
            Text(phase.rawValue)
                .font(ClarityFonts.sans(size: 16))
                .tracking(2)
                .foregroundStyle(ClarityColors.textSecondary)

            // Continue button
            ClarityButton("Continue", variant: .primary, fullWidth: true) {
                onComplete()
            }
            .opacity(cycleComplete ? 1.0 : 0.5)
            .disabled(!cycleComplete)

            // Cancel
            Button {
                HapticManager.light()
                onCancel()
            } label: {
                Text("Go back to what I was doing")
                    .font(ClarityFonts.sans(size: 14))
                    .foregroundStyle(ClarityColors.textMuted)
            }
        }
        .onAppear {
            startCycle()
        }
    }

    // MARK: - Breathing Cycle

    private func startCycle() {
        // Phase 1: Inhale (expand over 4s)
        phase = .inhale
        countdown = 4
        startCountdown()

        withAnimation(.easeInOut(duration: phaseDuration)) {
            circleScale = 1.0
        }

        // Phase 2: Hold at 4s
        DispatchQueue.main.asyncAfter(deadline: .now() + phaseDuration) {
            phase = .hold
            countdown = 4
            startCountdown()
        }

        // Phase 3: Exhale at 8s (contract over 4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + phaseDuration * 2) {
            phase = .exhale
            countdown = 4
            startCountdown()

            withAnimation(.easeInOut(duration: phaseDuration)) {
                circleScale = 0.6
            }
        }

        // Cycle complete at 12s
        DispatchQueue.main.asyncAfter(deadline: .now() + phaseDuration * 3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                cycleComplete = true
            }
            HapticManager.success()
        }
    }

    private func startCountdown() {
        for i in 1..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
                countdown = 4 - i
            }
        }
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        BreathingShield(onComplete: {}, onCancel: {})
    }
}
