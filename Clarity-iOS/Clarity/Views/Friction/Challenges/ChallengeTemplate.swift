import SwiftUI

/// Shared layout wrapper for all friction challenges. Provides the standard
/// icon circle -> category label -> title -> content -> cancel pattern.
struct ChallengeTemplate<Content: View>: View {

    let icon: String
    let iconColor: Color
    let category: String
    let title: String
    let onCancel: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: ClaritySpacing.lg) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            // Category label
            Text(category.uppercased())
                .font(ClarityFonts.mono(size: 10))
                .tracking(3)
                .foregroundStyle(ClarityColors.textMuted)

            // Title
            Text(title)
                .font(ClarityFonts.serif(size: 24, weight: .bold))
                .foregroundStyle(ClarityColors.textPrimary)
                .multilineTextAlignment(.center)

            // Challenge-specific content
            content()

            // Cancel text
            Button {
                HapticManager.light()
                onCancel()
            } label: {
                Text("Go back to what I was doing")
                    .font(ClarityFonts.sans(size: 14))
                    .foregroundStyle(ClarityColors.textMuted)
            }
        }
    }
}

/// Shared success state shown after completing a challenge.
struct ChallengeSuccess: View {

    let message: String
    let subtitle: String?
    let onDone: () -> Void

    init(_ message: String, subtitle: String? = nil, onDone: @escaping () -> Void) {
        self.message = message
        self.subtitle = subtitle
        self.onDone = onDone
    }

    var body: some View {
        VStack(spacing: ClaritySpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(ClarityColors.success)
                .transition(.scale.combined(with: .opacity))

            Text(message)
                .font(ClarityFonts.serif(size: 22, weight: .bold))
                .foregroundStyle(ClarityColors.textPrimary)
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(ClarityFonts.sans(size: 14))
                    .foregroundStyle(ClarityColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            ClarityButton("Done", variant: .primary, fullWidth: true) {
                onDone()
            }
        }
        .onAppear {
            HapticManager.success()
        }
    }
}
