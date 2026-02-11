import SwiftUI
import SwiftData

/// Step 4: Grid of common time-wasting apps for the user to "shield."
/// In production this would use FamilyActivityPicker; this is a manual fallback.
struct AppSelectionStep: View {

    let onContinue: () -> Void

    @State private var selectedApps: Set<String> = []
    @State private var bounceCount: Int = 0

    private let apps: [(name: String, icon: String)] = [
        ("Instagram", "camera.fill"),
        ("TikTok", "play.fill"),
        ("Twitter/X", "bubble.left.fill"),
        ("Facebook", "person.2.fill"),
        ("YouTube", "play.rectangle.fill"),
        ("Snapchat", "ghost.fill"),
        ("Reddit", "text.bubble.fill"),
        ("Netflix", "tv.fill"),
        ("Safari", "safari.fill"),
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: ClaritySpacing.sm), count: 3)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ClaritySpacing.lg) {
                // Header
                VStack(spacing: ClaritySpacing.sm) {
                    Text("Shield Your Apps")
                        .font(ClarityFonts.serif(size: 28, weight: .bold))
                        .foregroundStyle(ClarityColors.textPrimary)

                    Text("Choose apps that steal your time")
                        .font(ClarityFonts.sans(size: 15))
                        .foregroundStyle(ClarityColors.textTertiary)
                }
                .padding(.top, ClaritySpacing.lg)

                // Selection counter pill
                if !selectedApps.isEmpty {
                    Text("\(selectedApps.count) app\(selectedApps.count == 1 ? "" : "s") shielded")
                        .font(ClarityFonts.mono(size: 12))
                        .foregroundStyle(ClarityColors.primary)
                        .padding(.horizontal, ClaritySpacing.md)
                        .padding(.vertical, ClaritySpacing.sm)
                        .background(ClarityColors.primaryMuted)
                        .clipShape(Capsule())
                        .transition(.scale.combined(with: .opacity))
                        .id(bounceCount) // Trigger bounce on change
                }

                // App grid
                LazyVGrid(columns: columns, spacing: ClaritySpacing.sm) {
                    ForEach(apps, id: \.name) { app in
                        appTile(name: app.name, icon: app.icon)
                    }
                }
                .padding(.horizontal, ClaritySpacing.lg)

                // Continue
                ClarityButton(
                    "Continue",
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
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedApps)
    }

    // MARK: - App Tile

    private func appTile(name: String, icon: String) -> some View {
        let isSelected = selectedApps.contains(name)

        return Button {
            HapticManager.light()
            if isSelected {
                selectedApps.remove(name)
            } else {
                selectedApps.insert(name)
            }
            bounceCount += 1
        } label: {
            VStack(spacing: ClaritySpacing.sm) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? ClarityColors.primary : ClarityColors.textSecondary)
                        .frame(width: 48, height: 48)

                    // Checkmark overlay
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(ClarityColors.primary)
                            .offset(x: 4, y: -4)
                            .transition(.scale)
                    }
                }

                Text(name)
                    .font(ClarityFonts.sans(size: 12))
                    .foregroundStyle(
                        isSelected ? ClarityColors.textPrimary : ClarityColors.textMuted
                    )
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ClaritySpacing.md)
            .background(isSelected ? ClarityColors.primaryMuted : ClarityColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: ClarityRadius.lg)
                    .stroke(
                        isSelected ? ClarityColors.primary.opacity(0.5) : ClarityColors.border,
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.0 : 1.0) // Spring handled by button style
        }
        .buttonStyle(AppTileButtonStyle())
    }
}

/// Bounce effect when tapping an app tile.
private struct AppTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        AppSelectionStep {}
    }
}
