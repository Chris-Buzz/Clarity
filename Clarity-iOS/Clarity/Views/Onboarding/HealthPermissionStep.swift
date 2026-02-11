import SwiftUI

/// Step 3: Request HealthKit permissions for sleep, activity, and heart rate.
struct HealthPermissionStep: View {

    let onContinue: () -> Void

    @State private var sleepEnabled: Bool = false
    @State private var activityEnabled: Bool = false
    @State private var heartRateEnabled: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ClaritySpacing.lg) {
                // Header
                VStack(spacing: ClaritySpacing.sm) {
                    Text("Health Integration")
                        .font(ClarityFonts.serif(size: 28, weight: .bold))
                        .foregroundStyle(ClarityColors.textPrimary)

                    Text("Understanding your body helps break the scroll")
                        .font(ClarityFonts.sans(size: 15))
                        .foregroundStyle(ClarityColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, ClaritySpacing.lg)

                // Permission cards
                VStack(spacing: ClaritySpacing.sm) {
                    permissionCard(
                        icon: "moon.stars.fill",
                        title: "Sleep",
                        subtitle: "See how phone use affects rest",
                        isOn: $sleepEnabled
                    )
                    permissionCard(
                        icon: "figure.walk",
                        title: "Activity",
                        subtitle: "Movement reduces cravings",
                        isOn: $activityEnabled
                    )
                    permissionCard(
                        icon: "heart.fill",
                        title: "Heart Rate",
                        subtitle: "Track stress patterns",
                        isOn: $heartRateEnabled
                    )
                }
                .padding(.horizontal, ClaritySpacing.lg)

                Spacer().frame(height: ClaritySpacing.xl)

                // Buttons
                VStack(spacing: ClaritySpacing.sm) {
                    ClarityButton(
                        "Continue",
                        variant: .primary,
                        size: .lg,
                        fullWidth: true
                    ) {
                        // In production: call HealthManager.requestAuthorization()
                        onContinue()
                    }

                    ClarityButton(
                        "Skip for now",
                        variant: .ghost,
                        size: .md,
                        fullWidth: true
                    ) {
                        onContinue()
                    }
                }
                .padding(.horizontal, ClaritySpacing.lg)
                .padding(.bottom, ClaritySpacing.xl)
            }
        }
    }

    // MARK: - Permission Card

    private func permissionCard(
        icon: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: ClaritySpacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(ClarityColors.primary)
                .frame(width: 44, height: 44)
                .background(ClarityColors.primaryMuted)
                .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ClarityFonts.sansMedium(size: 15))
                    .foregroundStyle(ClarityColors.textPrimary)

                Text(subtitle)
                    .font(ClarityFonts.sans(size: 13))
                    .foregroundStyle(ClarityColors.textMuted)
            }

            Spacer()

            // Custom toggle
            customToggle(isOn: isOn)
        }
        .padding(ClaritySpacing.md)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: ClarityRadius.xl)
                .stroke(ClarityColors.border, lineWidth: 1)
        )
    }

    // MARK: - Custom Toggle

    /// Orange pill toggle matching the app's design language.
    private func customToggle(isOn: Binding<Bool>) -> some View {
        Button {
            HapticManager.light()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.wrappedValue.toggle()
            }
        } label: {
            ZStack(alignment: isOn.wrappedValue ? .trailing : .leading) {
                Capsule()
                    .fill(isOn.wrappedValue ? ClarityColors.primary : ClarityColors.surfaceElevated)
                    .frame(width: 48, height: 28)

                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                    .padding(3)
            }
        }
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        HealthPermissionStep {}
    }
}
