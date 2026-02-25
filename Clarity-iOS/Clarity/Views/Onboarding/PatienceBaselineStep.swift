import SwiftUI
import SwiftData

/// Onboarding step 5: Establishes a patience baseline score (1-10).
/// Slider with haptic ticks and teal intensity that increases with score.
struct PatienceBaselineStep: View {

    let onContinue: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var patienceScore: Double = 5.0

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        VStack(spacing: ClaritySpacing.xl) {
            Spacer()

            // Question
            Text("How patient do you\nfeel today?")
                .font(ClarityFonts.serif(size: 34))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // Score display with teal intensity
            ZStack {
                Circle()
                    .fill(ClarityColors.teal.opacity(Double(patienceScore) / 15.0))
                    .frame(width: 120, height: 120)

                Circle()
                    .stroke(ClarityColors.teal.opacity(0.4), lineWidth: 2)
                    .frame(width: 120, height: 120)

                Text("\(Int(patienceScore))")
                    .font(ClarityFonts.serif(size: 48))
                    .foregroundStyle(.white)
            }

            // Slider
            VStack(spacing: ClaritySpacing.md) {
                Slider(
                    value: $patienceScore,
                    in: 1...10,
                    step: 1
                )
                .tint(ClarityColors.teal)
                .onChange(of: patienceScore) { _, _ in
                    HapticManager.light()
                }

                // Labels
                HStack {
                    Text("Not at all")
                        .font(ClarityFonts.sans(size: 13))
                        .foregroundStyle(.white.opacity(0.4))

                    Spacer()

                    Text("Average")
                        .font(ClarityFonts.sans(size: 13))
                        .foregroundStyle(.white.opacity(0.4))

                    Spacer()

                    Text("Very patient")
                        .font(ClarityFonts.sans(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, ClaritySpacing.xl)

            Spacer()

            // Continue
            ClarityButton("Next", variant: .primary, size: .lg, fullWidth: true) {
                saveBaseline()
                onContinue()
            }
            .padding(.horizontal, ClaritySpacing.lg)
            .padding(.bottom, ClaritySpacing.xl)
        }
    }

    private func saveBaseline() {
        HapticManager.success()
        profile?.patienceBaselineScore = Int(patienceScore)
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        PatienceBaselineStep {}
    }
    .modelContainer(for: [UserProfile.self], inMemory: true)
}
