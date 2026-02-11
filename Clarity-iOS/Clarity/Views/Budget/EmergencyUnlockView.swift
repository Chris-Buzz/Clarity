import SwiftUI

/// Multi-step emergency unlock designed to prevent impulsive phone use.
/// The process is deliberately slow and tedious — that's the entire point.
///
/// Step 1: Type a specific phrase exactly ("I am choosing to unlock my phone...")
/// Step 2: Wait 5 minutes while staring at a progress ring
/// Step 3: Confirm with remaining unlock count
///
/// If the user leaves the screen, the wait timer resets.
struct EmergencyUnlockView: View {

    @Environment(\.dismiss) private var dismiss

    let budgetService: DailyBudgetService
    let waitMinutes: Int
    let remainingUnlocks: Int
    let minutesUsedToday: Int
    let budgetMinutes: Int

    @State private var step: UnlockStep = .typePhrase
    @State private var typedPhrase: String = ""
    @State private var waitSecondsRemaining: Int = 0
    @State private var waitTimer: Timer?
    @State private var unlockSucceeded = false

    private let requiredPhrase = "I am choosing to unlock my phone. This is a conscious decision."

    enum UnlockStep {
        case typePhrase
        case waiting
        case confirm
        case done
    }

    var body: some View {
        ZStack {
            ClarityColors.background.ignoresSafeArea()

            VStack(spacing: ClaritySpacing.xl) {
                // Header
                VStack(spacing: ClaritySpacing.sm) {
                    Text("EMERGENCY UNLOCK")
                        .font(ClarityFonts.mono(size: 11))
                        .tracking(3)
                        .foregroundStyle(ClarityColors.danger)

                    Text(stepTitle)
                        .font(ClarityFonts.serif(size: 28))
                        .foregroundStyle(ClarityColors.textPrimary)
                        .multilineTextAlignment(.center)
                }

                // Step content
                switch step {
                case .typePhrase:
                    typePhraseStep
                case .waiting:
                    waitingStep
                case .confirm:
                    confirmStep
                case .done:
                    doneStep
                }

                Spacer()

                // Cancel button (always available)
                if step != .done {
                    Button {
                        HapticManager.light()
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(ClarityFonts.sans(size: 15))
                            .foregroundStyle(ClarityColors.textMuted)
                    }
                }
            }
            .padding(.horizontal, ClaritySpacing.lg)
            .padding(.top, ClaritySpacing.xxl)
            .padding(.bottom, ClaritySpacing.lg)
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(step == .waiting) // Can't swipe away during wait
    }

    // MARK: - Step Title

    private var stepTitle: String {
        switch step {
        case .typePhrase: return "Prove you\nmean it"
        case .waiting:    return "Now wait"
        case .confirm:    return "One more\ntime"
        case .done:       return "Unlocked"
        }
    }

    // MARK: - Step 1: Type Phrase

    private var typePhraseStep: some View {
        VStack(spacing: ClaritySpacing.lg) {
            // Show the required phrase
            Text("\"\(requiredPhrase)\"")
                .font(ClarityFonts.sans(size: 15))
                .foregroundStyle(ClarityColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ClaritySpacing.md)

            // Text input
            TextField("Type the phrase exactly...", text: $typedPhrase, axis: .vertical)
                .font(ClarityFonts.sans(size: 15))
                .foregroundStyle(ClarityColors.textPrimary)
                .padding(ClaritySpacing.md)
                .background(ClarityColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: ClarityRadius.md)
                        .stroke(phraseMatches ? ClarityColors.success : ClarityColors.border, lineWidth: 1)
                )
                .lineLimit(3...5)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            // Status indicator
            if !typedPhrase.isEmpty && !phraseMatches {
                Text("Doesn't match yet. Type it exactly as shown.")
                    .font(ClarityFonts.sans(size: 13))
                    .foregroundStyle(ClarityColors.danger)
            }

            // Continue button
            ClarityButton("Continue", variant: phraseMatches ? .primary : .ghost, size: .lg, fullWidth: true) {
                guard phraseMatches else { return }
                HapticManager.medium()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    step = .waiting
                    startWaitTimer()
                }
            }
            .disabled(!phraseMatches)
        }
    }

    private var phraseMatches: Bool {
        typedPhrase.trimmingCharacters(in: .whitespacesAndNewlines) == requiredPhrase
    }

    // MARK: - Step 2: Wait

    private var waitingStep: some View {
        VStack(spacing: ClaritySpacing.xl) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(ClarityColors.surface, lineWidth: 6)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: waitProgress)
                    .stroke(ClarityColors.primary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: waitProgress)

                VStack(spacing: 4) {
                    Text(formatWaitTime(waitSecondsRemaining))
                        .font(ClarityFonts.serif(size: 36))
                        .foregroundStyle(ClarityColors.textPrimary)

                    Text("remaining")
                        .font(ClarityFonts.mono(size: 10))
                        .tracking(2)
                        .foregroundStyle(ClarityColors.textMuted)
                }
            }

            // Usage stats during the wait
            VStack(spacing: ClaritySpacing.sm) {
                Text("TODAY'S USAGE")
                    .font(ClarityFonts.mono(size: 10))
                    .tracking(2)
                    .foregroundStyle(ClarityColors.textMuted)

                Text("\(formatMinutes(minutesUsedToday)) / \(formatMinutes(budgetMinutes))")
                    .font(ClarityFonts.sansMedium(size: 18))
                    .foregroundStyle(ClarityColors.textPrimary)

                Text("You set this limit for a reason.")
                    .font(ClarityFonts.sans(size: 14))
                    .foregroundStyle(ClarityColors.textTertiary)
            }
            .padding(ClaritySpacing.lg)
            .frame(maxWidth: .infinity)
            .background(ClarityColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
        }
        .onDisappear {
            // If user leaves this screen, reset the timer
            waitTimer?.invalidate()
            waitTimer = nil
        }
    }

    private var waitProgress: CGFloat {
        let total = Double(waitMinutes * 60)
        let elapsed = total - Double(waitSecondsRemaining)
        return CGFloat(elapsed / total)
    }

    private func startWaitTimer() {
        waitSecondsRemaining = waitMinutes * 60
        waitTimer?.invalidate()
        waitTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if waitSecondsRemaining > 0 {
                waitSecondsRemaining -= 1
            } else {
                waitTimer?.invalidate()
                waitTimer = nil
                HapticManager.success()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    step = .confirm
                }
            }
        }
    }

    // MARK: - Step 3: Confirm

    private var confirmStep: some View {
        VStack(spacing: ClaritySpacing.lg) {
            VStack(spacing: ClaritySpacing.md) {
                Text("You have \(remainingUnlocks) emergency unlock\(remainingUnlocks == 1 ? "" : "s") left today.")
                    .font(ClarityFonts.sans(size: 16))
                    .foregroundStyle(ClarityColors.textSecondary)
                    .multilineTextAlignment(.center)

                Text("This will give you 30 minutes of access. After that, apps will be blocked again until midnight.")
                    .font(ClarityFonts.sans(size: 14))
                    .foregroundStyle(ClarityColors.textTertiary)
                    .multilineTextAlignment(.center)
            }

            ClarityButton("Yes, unlock for 30 minutes", variant: .primary, size: .lg, fullWidth: true) {
                HapticManager.warning()
                let success = budgetService.performEmergencyUnlock()
                unlockSucceeded = success
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    step = .done
                }
            }
        }
    }

    // MARK: - Step 4: Done

    private var doneStep: some View {
        VStack(spacing: ClaritySpacing.lg) {
            if unlockSucceeded {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(ClarityColors.primary)

                Text("Apps unlocked for 30 minutes. Use them wisely.")
                    .font(ClarityFonts.sans(size: 16))
                    .foregroundStyle(ClarityColors.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(ClarityColors.danger)

                Text("No emergency unlocks remaining today. Try again tomorrow.")
                    .font(ClarityFonts.sans(size: 16))
                    .foregroundStyle(ClarityColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            ClarityButton("Done", variant: .primary, size: .lg, fullWidth: true) {
                HapticManager.light()
                dismiss()
            }
        }
    }

    // MARK: - Formatters

    private func formatWaitTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m"
    }
}

#Preview {
    EmergencyUnlockView(
        budgetService: .shared,
        waitMinutes: 1,
        remainingUnlocks: 2,
        minutesUsedToday: 195,
        budgetMinutes: 180
    )
}
