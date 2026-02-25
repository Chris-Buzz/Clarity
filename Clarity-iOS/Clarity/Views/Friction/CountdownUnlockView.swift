import SwiftUI

/// Level 4 friction — the signature countdown unlock.
/// Displays a calm, slow-filling circle that the user must wait through.
/// Timer escalates with each open: 5s → 10s → 20s → 35s → 55s → 60s cap.
/// No skip, no cancel — patience is the only way through.
struct CountdownUnlockView: View {

    let delay: Int
    let openNumber: Int
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var secondsRemaining: Int
    @State private var isComplete = false
    @State private var appeared = false
    @State private var timer: Timer?

    private let ringSize: CGFloat = 220
    private let ringWidth: CGFloat = 8

    private let patiencePrompts = [
        "What are you actually looking for?",
        "This feeling will pass in about 90 seconds.",
        "Your brain is learning to wait.",
        "Boredom is not an emergency.",
        "The urge peaks and fades. Just watch it.",
        "What would you do if your phone didn't exist?",
        "Patience is a muscle. You are training it.",
        "Nothing urgent is happening right now.",
    ]

    @State private var selectedPrompt: String = ""

    init(delay: Int, openNumber: Int, onComplete: @escaping () -> Void) {
        self.delay = delay
        self.openNumber = openNumber
        self.onComplete = onComplete
        self._secondsRemaining = State(initialValue: delay)
    }

    var body: some View {
        ZStack {
            // Patience gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.03, green: 0.1, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: ClaritySpacing.xl) {
                Spacer()

                // Countdown ring
                ZStack {
                    // Track
                    Circle()
                        .stroke(ClarityColors.borderSubtle, lineWidth: ringWidth)
                        .frame(width: ringSize, height: ringSize)

                    // Progress arc
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            ClarityColors.primary,
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                        )
                        .frame(width: ringSize, height: ringSize)
                        .rotationEffect(.degrees(-90))

                    // Center content
                    VStack(spacing: ClaritySpacing.sm) {
                        Text("Open #\(openNumber) today")
                            .font(ClarityFonts.mono(size: 11))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.5))

                        if isComplete {
                            Image(systemName: "checkmark")
                                .font(.system(size: 48, weight: .light))
                                .foregroundStyle(ClarityColors.primary)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Text("\(secondsRemaining)")
                                .font(ClarityFonts.serif(size: 56))
                                .foregroundStyle(.white)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                        }
                    }
                }
                .opacity(appeared ? 1 : 0)

                // Patience prompt
                Text(selectedPrompt)
                    .font(ClarityFonts.sans(size: 16))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ClaritySpacing.xl)
                    .opacity(appeared ? 1 : 0)

                Spacer()
            }
        }
        .onAppear {
            selectedPrompt = patiencePrompts.randomElement() ?? patiencePrompts[0]
            HapticManager.light()

            // Fade in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }

            // Start countdown
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Countdown Logic

    private func startCountdown() {
        // Animate the ring fill linearly over the full duration
        withAnimation(.linear(duration: Double(delay))) {
            progress = 1.0
        }

        // Tick down seconds
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            Task { @MainActor in
                if secondsRemaining > 1 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        secondsRemaining -= 1
                    }
                } else {
                    t.invalidate()
                    completeCountdown()
                }
            }
        }
    }

    private func completeCountdown() {
        HapticManager.success()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isComplete = true
            secondsRemaining = 0
        }

        // Brief pause to show the checkmark, then complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onComplete()
        }
    }
}

#Preview {
    CountdownUnlockView(delay: 10, openNumber: 3, onComplete: {})
}
