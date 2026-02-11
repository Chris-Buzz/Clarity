import SwiftUI
import SwiftData

/// 9-step onboarding coordinator with animated progress bar and page transitions.
struct OnboardingFlow: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @State private var currentStep: Int = 0

    /// Total number of onboarding steps
    private let totalSteps = 9

    var body: some View {
        ZStack {
            ClarityColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: back button + progress + step counter
                topBar
                    .padding(.horizontal, ClaritySpacing.lg)
                    .padding(.top, ClaritySpacing.sm)
                    .padding(.bottom, ClaritySpacing.md)

                // Step content with slide transition
                ZStack {
                    stepView(for: currentStep)
                        .id(currentStep) // Force re-render on step change
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: currentStep)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: ClaritySpacing.sm) {
            HStack {
                // Back button (visible on steps > 0)
                Button {
                    HapticManager.light()
                    withAnimation { currentStep -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(ClarityColors.textSecondary)
                        .frame(width: 32, height: 32)
                }
                .opacity(currentStep > 0 ? 1 : 0)
                .disabled(currentStep == 0)

                Spacer()

                // Step counter
                Text("STEP \(currentStep + 1) OF \(totalSteps)")
                    .font(ClarityFonts.mono(size: 11))
                    .tracking(2)
                    .foregroundStyle(ClarityColors.textMuted)

                Spacer()

                // Spacer to balance back button
                Color.clear.frame(width: 32, height: 32)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ClarityColors.surface)
                        .frame(height: 3)

                    // Fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ClarityColors.primary)
                        .frame(
                            width: geo.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps),
                            height: 3
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                }
            }
            .frame(height: 3)
        }
    }

    // MARK: - Step Router

    @ViewBuilder
    private func stepView(for step: Int) -> some View {
        switch step {
        case 0:
            WelcomeStep { advanceStep() }
        case 1:
            AssessmentStep { advanceStep() }
        case 2:
            HealthPermissionStep { advanceStep() }
        case 3:
            AppSelectionStep { advanceStep() }
        case 4:
            ImportantPeopleStep { advanceStep() }
        case 5:
            HomeBaseStep { advanceStep() }
        case 6:
            GoalSettingStep { advanceStep() }
        case 7:
            IntentionBuilderStep { advanceStep() }
        case 8:
            ReadyStep { completeOnboarding() }
        default:
            EmptyView()
        }
    }

    // MARK: - Navigation

    private func advanceStep() {
        guard currentStep < totalSteps - 1 else { return }
        HapticManager.light()
        withAnimation { currentStep += 1 }
    }

    private func completeOnboarding() {
        if let profile = profiles.first {
            profile.isOnboarded = true
        }
        HapticManager.success()
        dismiss()
    }
}

#Preview {
    OnboardingFlow()
        .modelContainer(for: [UserProfile.self, ImplementationIntention.self, ImportantContact.self, WiFiGateConfig.self], inMemory: true)
}
