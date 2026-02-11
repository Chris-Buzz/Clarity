import SwiftUI

/// Step 7: Final "You're Ready" screen with pulsing flame and feature summary.
struct ReadyStep: View {

    let onComplete: () -> Void

    @State private var flameGlow: CGFloat = 0.4
    @State private var flameScale: CGFloat = 0.95
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: ClaritySpacing.xl) {
            Spacer()

            // Pulsing flame
            ZStack {
                // Glow ring
                Circle()
                    .fill(ClarityColors.primary.opacity(flameGlow * 0.3))
                    .frame(width: 120, height: 120)
                    .scaleEffect(flameScale)
                    .blur(radius: 20)

                Image(systemName: "flame.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(ClarityColors.primary)
                    .scaleEffect(flameScale)
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                ) {
                    flameGlow = 0.8
                    flameScale = 1.08
                }
            }

            // Title
            Text("You're Ready")
                .font(ClarityFonts.serif(size: 36, weight: .bold))
                .foregroundStyle(ClarityColors.textPrimary)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

            // Mini feature icons row
            HStack(spacing: ClaritySpacing.lg) {
                featureMini(icon: "timer", label: "Set Timer")
                featureMini(icon: "shield.fill", label: "Friction On")
                featureMini(icon: "arrow.up.circle", label: "Level Up")
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)

            Spacer()

            // CTA with glow
            Button {
                HapticManager.heavy()
                onComplete()
            } label: {
                Text("Light the Flame")
                    .font(ClarityFonts.sansSemiBold(size: 18))
                    .foregroundStyle(.white)
                    .padding(.vertical, ClaritySpacing.md)
                    .frame(maxWidth: .infinity)
                    .background(ClarityColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                    .shadow(color: ClarityColors.primaryGlow, radius: 16, y: 4)
                    .shadow(color: ClarityColors.primary.opacity(0.2), radius: 32, y: 8)
            }
            .buttonStyle(ScalePressStyle())
            .padding(.horizontal, ClaritySpacing.lg)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer().frame(height: ClaritySpacing.xl)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                appeared = true
            }
        }
    }

    // MARK: - Feature Mini Card

    private func featureMini(icon: String, label: String) -> some View {
        VStack(spacing: ClaritySpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(ClarityColors.primary)

            Text(label)
                .font(ClarityFonts.mono(size: 10))
                .foregroundStyle(ClarityColors.textMuted)
        }
        .frame(width: 80)
        .padding(.vertical, ClaritySpacing.md)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
    }
}

/// Press animation reused from ClarityButton pattern.
private struct ScalePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        ReadyStep {}
    }
}
