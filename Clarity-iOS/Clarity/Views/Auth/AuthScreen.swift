import SwiftUI
import SwiftData

/// Name entry screen with breathing orb animation.
/// First screen the user sees — captures their name and creates a UserProfile in SwiftData.
struct AuthScreen: View {

    @Environment(\.modelContext) private var modelContext
    @State private var name: String = ""
    @State private var isFocused: Bool = false
    @State private var orbScale: CGFloat = 1.0
    @State private var navigateToOnboarding: Bool = false

    var body: some View {
        ZStack {
            ClarityColors.background.ignoresSafeArea()

            // Breathing orb — large orange circle pulsing behind content
            Circle()
                .fill(ClarityColors.primary.opacity(0.1))
                .frame(width: 300, height: 300)
                .scaleEffect(orbScale)
                .blur(radius: 60)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 4.0)
                        .repeatForever(autoreverses: true)
                    ) {
                        orbScale = 1.15
                    }
                }

            VStack(spacing: ClaritySpacing.lg) {
                Spacer()

                // Title
                Text("Clarity")
                    .font(ClarityFonts.serifItalic(size: 52))
                    .foregroundStyle(ClarityColors.textPrimary)

                // Tagline
                Text("Break the scroll.\nReclaim your time.")
                    .font(ClarityFonts.sans(size: 15))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Spacer()

                // Form section
                VStack(spacing: ClaritySpacing.md) {
                    // Label
                    Text("WHAT SHOULD WE CALL YOU")
                        .font(ClarityFonts.mono(size: 12))
                        .tracking(4)
                        .foregroundStyle(ClarityColors.textMuted)

                    // Text field
                    TextField("", text: $name, prompt: Text("Your name")
                        .foregroundStyle(Color.white.opacity(0.25)))
                        .font(ClarityFonts.sans(size: 16))
                        .foregroundStyle(ClarityColors.textPrimary)
                        .padding(ClaritySpacing.md)
                        .background(ClarityColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: ClarityRadius.lg)
                                .stroke(
                                    isFocused ? ClarityColors.primary : ClarityColors.border,
                                    lineWidth: 1
                                )
                        )
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .onTapGesture { isFocused = true }
                        .onChange(of: name) { _, _ in
                            // Keep focus state while typing
                            if !isFocused { isFocused = true }
                        }
                        .onSubmit { isFocused = false }

                    // Continue button
                    ClarityButton(
                        "Continue",
                        variant: .primary,
                        size: .lg,
                        fullWidth: true
                    ) {
                        createUserAndContinue()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).count < 2)
                    .opacity(name.trimmingCharacters(in: .whitespaces).count < 2 ? 0.4 : 1.0)
                }
                .padding(.horizontal, ClaritySpacing.xl)

                Spacer()

                // Footer pill
                Text("100% ON-DEVICE")
                    .font(ClarityFonts.mono(size: 9))
                    .tracking(2)
                    .foregroundStyle(ClarityColors.textMuted)
                    .padding(.horizontal, ClaritySpacing.md)
                    .padding(.vertical, ClaritySpacing.sm)
                    .background(ClarityColors.surface)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(ClarityColors.border, lineWidth: 1)
                    )
                    .padding(.bottom, ClaritySpacing.lg)
            }
        }
        .fullScreenCover(isPresented: $navigateToOnboarding) {
            OnboardingFlow()
        }
    }

    // MARK: - Actions

    private func createUserAndContinue() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard trimmedName.count >= 2 else { return }

        let profile = UserProfile(name: trimmedName)
        modelContext.insert(profile)

        HapticManager.success()
        navigateToOnboarding = true
    }
}

#Preview {
    AuthScreen()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
