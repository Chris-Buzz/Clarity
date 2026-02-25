import SwiftUI

/// Step 0: Dramatic hero screen about patience training, with concentric pulsing rings.
struct WelcomeStep: View {

    let onContinue: () -> Void

    // Ring pulse animations (staggered)
    @State private var ring1Scale: CGFloat = 0.8
    @State private var ring2Scale: CGFloat = 0.8
    @State private var ring3Scale: CGFloat = 0.8
    @State private var ring1Opacity: Double = 0.15
    @State private var ring2Opacity: Double = 0.1
    @State private var ring3Opacity: Double = 0.05

    // Breathing core
    @State private var coreScale: CGFloat = 0.95

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ClaritySpacing.xl) {
                Spacer().frame(height: ClaritySpacing.xl)

                // Hero orb with concentric rings
                heroOrb
                    .frame(height: 220)

                // Headline
                VStack(spacing: ClaritySpacing.xs) {
                    Text("Your brain forgot")
                        .font(ClarityFonts.sans(size: 18))
                        .foregroundStyle(ClarityColors.textSecondary)

                    Text("how to wait")
                        .font(ClarityFonts.serif(size: 48, weight: .bold))
                        .foregroundStyle(ClarityColors.primary)

                    Text("Clarity teaches your brain to be patient again")
                        .font(ClarityFonts.sans(size: 16))
                        .foregroundStyle(ClarityColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, ClaritySpacing.xs)
                }

                // Three numbered steps
                VStack(spacing: ClaritySpacing.sm) {
                    stepCard(number: "01", text: "Choose apps to train with")
                    stepCard(number: "02", text: "Friction that builds patience")
                    stepCard(number: "03", text: "Rewire your dopamine system")
                }
                .padding(.horizontal, ClaritySpacing.lg)

                // CTA
                ClarityButton(
                    "Start training",
                    variant: .primary,
                    size: .lg,
                    fullWidth: true
                ) {
                    onContinue()
                }
                .padding(.horizontal, ClaritySpacing.lg)
                .padding(.bottom, ClaritySpacing.xl)
            }
        }
        .onAppear { startAnimations() }
    }

    // MARK: - Hero Orb

    private var heroOrb: some View {
        ZStack {
            // Ring 3 (outermost)
            Circle()
                .stroke(ClarityColors.primary.opacity(ring3Opacity), lineWidth: 1.5)
                .frame(width: 200, height: 200)
                .scaleEffect(ring3Scale)

            // Ring 2
            Circle()
                .stroke(ClarityColors.primary.opacity(ring2Opacity), lineWidth: 1.5)
                .frame(width: 150, height: 150)
                .scaleEffect(ring2Scale)

            // Ring 1
            Circle()
                .stroke(ClarityColors.primary.opacity(ring1Opacity), lineWidth: 1.5)
                .frame(width: 100, height: 100)
                .scaleEffect(ring1Scale)

            // Breathing core
            Circle()
                .fill(ClarityColors.primary.opacity(0.2))
                .frame(width: 80, height: 80)
                .scaleEffect(coreScale)
        }
    }

    // MARK: - Step Card

    private func stepCard(number: String, text: String) -> some View {
        HStack(spacing: ClaritySpacing.md) {
            Text(number)
                .font(ClarityFonts.mono(size: 14))
                .foregroundStyle(ClarityColors.primary)
                .frame(width: 32)

            Text(text)
                .font(ClarityFonts.sans(size: 15))
                .foregroundStyle(ClarityColors.textSecondary)

            Spacer()
        }
        .padding(ClaritySpacing.md)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
    }

    // MARK: - Animations

    private func startAnimations() {
        // Concentric ring pulses — staggered outward expansion with fade
        let ringAnimation = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)

        withAnimation(ringAnimation) {
            ring1Scale = 1.4
            ring1Opacity = 0.0
        }
        withAnimation(ringAnimation.delay(0.3)) {
            ring2Scale = 1.4
            ring2Opacity = 0.0
        }
        withAnimation(ringAnimation.delay(0.6)) {
            ring3Scale = 1.4
            ring3Opacity = 0.0
        }

        // Core breathing
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            coreScale = 1.05
        }
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        WelcomeStep {}
    }
}
