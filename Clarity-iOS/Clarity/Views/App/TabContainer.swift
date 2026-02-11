import SwiftUI

/// Custom tab bar with text-only labels and a sliding orange indicator.
/// Deliberately avoids system TabView for a distinctive, minimal aesthetic.
struct TabContainer: View {

    @Environment(AppState.self) private var appState
    @Namespace private var tabIndicator

    var body: some View {
        @Bindable var state = appState

        VStack(spacing: 0) {
            // MARK: - Content Area

            Group {
                switch appState.selectedTab {
                case .dashboard:
                    DashboardView()
                case .insights:
                    InsightsPlaceholderView()
                case .settings:
                    SettingsPlaceholderView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // MARK: - Custom Tab Bar

            VStack(spacing: 0) {
                // Top border
                Rectangle()
                    .fill(ClarityColors.borderSubtle)
                    .frame(height: 1)

                HStack(spacing: 0) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        tabItem(tab)
                    }
                }
                .padding(.top, ClaritySpacing.sm)
                .padding(.bottom, ClaritySpacing.xs)
            }
            .background(ClarityColors.surface)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: ClarityRadius.xl,
                    topTrailingRadius: ClarityRadius.xl
                )
            )
        }
        .background(ClarityColors.background)
    }

    // MARK: - Tab Item

    @ViewBuilder
    private func tabItem(_ tab: Tab) -> some View {
        let isSelected = appState.selectedTab == tab

        Button {
            guard appState.selectedTab != tab else { return }
            HapticManager.light()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                appState.selectedTab = tab
            }
        } label: {
            VStack(spacing: ClaritySpacing.xs) {
                Text(tab.rawValue)
                    .font(ClarityFonts.sansSemiBold(size: 13))
                    .foregroundStyle(isSelected ? ClarityColors.textPrimary : ClarityColors.textMuted)

                // Sliding indicator bar
                if isSelected {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(ClarityColors.primary)
                        .frame(width: 24, height: 2)
                        .matchedGeometryEffect(id: "tabIndicator", in: tabIndicator)
                } else {
                    // Invisible placeholder to keep layout stable
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.clear)
                        .frame(width: 24, height: 2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ClaritySpacing.sm)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Placeholder Tabs

/// Placeholder for Insights tab — replace with real implementation.
private struct InsightsPlaceholderView: View {
    var body: some View {
        ZStack {
            ClarityColors.background.ignoresSafeArea()
            Text("Insights")
                .font(ClarityFonts.serif(size: 28))
                .foregroundStyle(ClarityColors.textMuted)
        }
    }
}

/// Placeholder for Settings tab — replace with real implementation.
private struct SettingsPlaceholderView: View {
    var body: some View {
        ZStack {
            ClarityColors.background.ignoresSafeArea()
            Text("Settings")
                .font(ClarityFonts.serif(size: 28))
                .foregroundStyle(ClarityColors.textMuted)
        }
    }
}

#Preview {
    TabContainer()
        .environment(AppState())
        .modelContainer(for: [UserProfile.self, FocusSession.self], inMemory: true)
}
