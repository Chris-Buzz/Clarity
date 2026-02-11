import SwiftUI
import SwiftData

/// Full-screen overlay for prosocial challenges.
/// Cycles through states: prompt -> waiting -> verified/failed.
struct ProsocialChallengeView: View {
    let challenge: ProsocialChallenge
    @Bindable var engine: ProsocialChallengeEngine
    let onComplete: () -> Void
    let onCancel: () -> Void
    let onSkip: () -> Void

    @State private var appeared = false
    @State private var pulseScale: CGFloat = 1.0

    // Contact avatar color from name hash
    private var avatarColor: Color {
        let name = challenge.suggestedContactName ?? "?"
        let hash = abs(name.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }

    private var contactInitial: String {
        let name = challenge.suggestedContactName ?? "?"
        return String(name.prefix(1)).uppercased()
    }

    var body: some View {
        ZStack {
            ClarityColors.overlayHeavy
                .ignoresSafeArea()
                .onTapGesture { /* block pass-through taps */ }

            VStack(spacing: ClaritySpacing.lg) {
                // Contact avatar
                ZStack {
                    Circle()
                        .fill(avatarColor)
                        .frame(width: 72, height: 72)

                    Text(contactInitial)
                        .font(ClarityFonts.serif(size: 32))
                        .foregroundStyle(.white)
                }

                // Content based on verification state
                switch engine.verificationStatus {
                case .idle:
                    initialPromptView
                case .waitingForAction:
                    waitingView
                case .verified:
                    verifiedView
                case .failed:
                    failedView
                case .callAttempted:
                    callAttemptedView
                case .autoVerified:
                    autoVerifiedView
                }
            }
            .padding(ClaritySpacing.xl)
            .frame(maxWidth: 360)
            .background(ClarityColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xxl))
            .overlay(
                RoundedRectangle(cornerRadius: ClarityRadius.xxl)
                    .stroke(ClarityColors.border, lineWidth: 1)
            )
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    // MARK: - Initial Prompt

    private var initialPromptView: some View {
        VStack(spacing: ClaritySpacing.md) {
            if let name = challenge.suggestedContactName {
                Text(name)
                    .font(ClarityFonts.serif(size: 28))
                    .foregroundStyle(ClarityColors.textPrimary)
            }

            Text(ProsocialResponses.prompt(for: challenge.type, contactName: challenge.suggestedContactName))
                .font(ClarityFonts.sans(size: 16))
                .foregroundStyle(ClarityColors.textSecondary)
                .multilineTextAlignment(.center)

            if challenge.type == "callSomeone" {
                ClarityButton("Call", variant: .primary, size: .lg, fullWidth: true) {
                    HapticManager.medium()
                    engine.deepLinkToPhone(phone: challenge.suggestedContactPhone)
                }
            } else {
                ClarityButton("Text", variant: .primary, size: .lg, fullWidth: true) {
                    HapticManager.medium()
                    engine.deepLinkToMessages(phone: challenge.suggestedContactPhone)
                }
            }

            ClarityButton("Skip", variant: .ghost, size: .sm) {
                HapticManager.light()
                engine.skipChallenge()
                onSkip()
            }

            Button {
                HapticManager.light()
                onCancel()
            } label: {
                Text("Go back to what I was doing")
                    .font(ClarityFonts.sans(size: 13))
                    .foregroundStyle(ClarityColors.textMuted)
            }
        }
    }

    // MARK: - Waiting State

    private var waitingView: some View {
        VStack(spacing: ClaritySpacing.md) {
            Circle()
                .fill(ClarityColors.primary)
                .frame(width: 12, height: 12)
                .scaleEffect(pulseScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        pulseScale = 1.5
                    }
                }

            Text("Take your time")
                .font(ClarityFonts.serif(size: 22))
                .foregroundStyle(ClarityColors.textPrimary)

            Text("We'll know when you're done")
                .font(ClarityFonts.sans(size: 15))
                .foregroundStyle(ClarityColors.textTertiary)
        }
    }

    // MARK: - Verified

    private var verifiedView: some View {
        VStack(spacing: ClaritySpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(ClarityColors.success)

            Text(engine.lastVerificationMessage ?? "Connection made")
                .font(ClarityFonts.sansMedium(size: 16))
                .foregroundStyle(ClarityColors.textPrimary)
                .multilineTextAlignment(.center)

            if let challenge = engine.currentChallenge, challenge.xpEarned > 0 {
                Text("+\(challenge.xpEarned) XP")
                    .font(ClarityFonts.mono(size: 14))
                    .foregroundStyle(ClarityColors.primary)
            }

            ClarityButton("Continue", variant: .primary, size: .lg, fullWidth: true) {
                HapticManager.success()
                onComplete()
            }
        }
        .onAppear { HapticManager.success() }
    }

    // MARK: - Failed

    private var failedView: some View {
        VStack(spacing: ClaritySpacing.md) {
            Text(engine.lastVerificationMessage ?? "...nice try")
                .font(ClarityFonts.sansMedium(size: 16))
                .foregroundStyle(ClarityColors.primary)
                .multilineTextAlignment(.center)

            ClarityButton("Try Again", variant: .primary, size: .lg, fullWidth: true) {
                HapticManager.medium()
                engine.verificationStatus = .idle
            }

            ClarityButton("Skip", variant: .ghost, size: .sm) {
                HapticManager.light()
                engine.skipChallenge()
                onSkip()
            }
        }
        .onAppear { HapticManager.warning() }
    }

    // MARK: - Call Attempted

    private var callAttemptedView: some View {
        VStack(spacing: ClaritySpacing.md) {
            Image(systemName: "phone.arrow.up.right")
                .font(.system(size: 36))
                .foregroundStyle(ClarityColors.success.opacity(0.8))

            Text(engine.lastVerificationMessage ?? "They didn't pick up, but you tried!")
                .font(ClarityFonts.sansMedium(size: 16))
                .foregroundStyle(ClarityColors.textPrimary)
                .multilineTextAlignment(.center)

            if let challenge = engine.currentChallenge, challenge.xpEarned > 0 {
                Text("+\(challenge.xpEarned) XP")
                    .font(ClarityFonts.mono(size: 14))
                    .foregroundStyle(ClarityColors.primary)
            }

            ClarityButton("Continue", variant: .primary, size: .lg, fullWidth: true) {
                HapticManager.success()
                onComplete()
            }
        }
        .onAppear { HapticManager.light() }
    }

    // MARK: - Auto Verified

    private var autoVerifiedView: some View {
        VStack(spacing: ClaritySpacing.md) {
            Image(systemName: "star.fill")
                .font(.system(size: 36))
                .foregroundStyle(ClarityColors.primary)

            Text(ProsocialResponses.alreadyConnected.randomElement() ?? "You've earned it")
                .font(ClarityFonts.sansMedium(size: 16))
                .foregroundStyle(ClarityColors.textPrimary)
                .multilineTextAlignment(.center)

            ClarityButton("Continue", variant: .primary, size: .lg, fullWidth: true) {
                HapticManager.success()
                onComplete()
            }
        }
        .onAppear { HapticManager.success() }
    }
}
