import SwiftUI
import FamilyControls

/// Settings UI for configuring the daily screen time budget.
/// Includes budget time slider, app picker, and emergency unlock settings.
struct BudgetConfigView: View {
    var profile: UserProfile?

    @State private var budgetMinutes: Int = 180
    @State private var maxUnlocks: Int = 2
    @State private var waitMinutes: Int = 5
    @State private var showAppPicker = false
    @State private var budgetSelection = FamilyActivitySelection()

    var body: some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.md) {

            // MARK: - Budget Time
            Text("DAILY LIMIT")
                .font(ClarityFonts.mono(size: 11))
                .tracking(3)
                .foregroundStyle(ClarityColors.textMuted)

            VStack(spacing: ClaritySpacing.sm) {
                HStack {
                    Text("Screen time budget")
                        .font(ClarityFonts.sans(size: 15))
                        .foregroundStyle(ClarityColors.textPrimary)
                    Spacer()
                    Text(formatMinutes(budgetMinutes))
                        .font(ClarityFonts.mono(size: 14))
                        .foregroundStyle(ClarityColors.primary)
                }

                // Slider: 30 min to 8 hours in 15-min steps
                Slider(
                    value: Binding(
                        get: { Double(budgetMinutes) },
                        set: { newVal in
                            HapticManager.light()
                            budgetMinutes = Int(newVal / 15) * 15 // snap to 15
                        }
                    ),
                    in: 30...480,
                    step: 15
                )
                .tint(ClarityColors.primary)

                Text("All budget-controlled apps will be hard-blocked once you exceed this limit.")
                    .font(ClarityFonts.sans(size: 12))
                    .foregroundStyle(ClarityColors.textMuted)
            }
            .padding(ClaritySpacing.md)
            .background(ClarityColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))

            // MARK: - App Selection
            Text("BUDGET APPS")
                .font(ClarityFonts.mono(size: 11))
                .tracking(3)
                .foregroundStyle(ClarityColors.textMuted)

            Button {
                HapticManager.light()
                showAppPicker = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Choose apps under budget")
                            .font(ClarityFonts.sansMedium(size: 15))
                            .foregroundStyle(ClarityColors.textPrimary)

                        let count = budgetSelection.applicationTokens.count
                        Text("\(count) app\(count == 1 ? "" : "s") selected")
                            .font(ClarityFonts.sans(size: 13))
                            .foregroundStyle(ClarityColors.textMuted)
                    }

                    Spacer()

                    Image(systemName: "arrow.right.circle")
                        .foregroundStyle(ClarityColors.primary)
                }
                .padding(ClaritySpacing.md)
                .background(ClarityColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: ClarityRadius.md)
                        .stroke(ClarityColors.borderSubtle, lineWidth: 1)
                )
            }
            .familyActivityPicker(isPresented: $showAppPicker, selection: $budgetSelection)

            // MARK: - Emergency Unlock Settings
            Text("EMERGENCY UNLOCK")
                .font(ClarityFonts.mono(size: 11))
                .tracking(3)
                .foregroundStyle(ClarityColors.textMuted)

            VStack(spacing: ClaritySpacing.sm) {
                // Max unlocks per day
                HStack {
                    Text("Max unlocks per day")
                        .font(ClarityFonts.sans(size: 15))
                        .foregroundStyle(ClarityColors.textPrimary)
                    Spacer()
                    HStack(spacing: ClaritySpacing.md) {
                        Button {
                            HapticManager.light()
                            if maxUnlocks > 1 { maxUnlocks -= 1 }
                        } label: {
                            Image(systemName: "minus.circle")
                                .foregroundStyle(ClarityColors.textSecondary)
                        }
                        Text("\(maxUnlocks)")
                            .font(ClarityFonts.mono(size: 16))
                            .foregroundStyle(ClarityColors.primary)
                            .frame(width: 24)
                        Button {
                            HapticManager.light()
                            if maxUnlocks < 5 { maxUnlocks += 1 }
                        } label: {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(ClarityColors.textSecondary)
                        }
                    }
                }

                Divider().background(ClarityColors.borderSubtle)

                // Wait time
                HStack {
                    Text("Wait time")
                        .font(ClarityFonts.sans(size: 15))
                        .foregroundStyle(ClarityColors.textPrimary)
                    Spacer()
                    HStack(spacing: ClaritySpacing.md) {
                        Button {
                            HapticManager.light()
                            if waitMinutes > 1 { waitMinutes -= 1 }
                        } label: {
                            Image(systemName: "minus.circle")
                                .foregroundStyle(ClarityColors.textSecondary)
                        }
                        Text("\(waitMinutes) min")
                            .font(ClarityFonts.mono(size: 16))
                            .foregroundStyle(ClarityColors.primary)
                            .frame(width: 60)
                        Button {
                            HapticManager.light()
                            if waitMinutes < 15 { waitMinutes += 1 }
                        } label: {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(ClarityColors.textSecondary)
                        }
                    }
                }

                Text("Lower unlocks and longer waits = stronger commitment. Each unlock grants 30 min of access.")
                    .font(ClarityFonts.sans(size: 12))
                    .foregroundStyle(ClarityColors.textMuted)
            }
            .padding(ClaritySpacing.md)
            .background(ClarityColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
        }
        .onAppear {
            if let profile {
                budgetMinutes = profile.dailyBudgetMinutes
                maxUnlocks = profile.maxEmergencyUnlocksPerDay
                waitMinutes = profile.emergencyWaitMinutes
                // Decode stored app selection
                if let data = profile.budgetAppsData,
                   let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                    budgetSelection = selection
                }
            }
        }
        .onChange(of: budgetMinutes) { _, _ in syncToProfile() }
        .onChange(of: maxUnlocks) { _, _ in syncToProfile() }
        .onChange(of: waitMinutes) { _, _ in syncToProfile() }
        .onChange(of: budgetSelection) { _, _ in syncToProfile() }
    }

    private func syncToProfile() {
        profile?.dailyBudgetMinutes = budgetMinutes
        profile?.maxEmergencyUnlocksPerDay = maxUnlocks
        profile?.emergencyWaitMinutes = waitMinutes
        if let encoded = try? JSONEncoder().encode(budgetSelection) {
            profile?.budgetAppsData = encoded
        }

        // Sync max unlocks to shared defaults for the service
        let defaults = UserDefaults(suiteName: "group.com.clarity-focus")
        defaults?.set(maxUnlocks, forKey: "maxEmergencyUnlocks")
        defaults?.set(budgetMinutes, forKey: "budgetMinutes")

        // Restart monitoring with new budget if enabled
        if profile?.dailyBudgetEnabled == true {
            DailyBudgetService.shared.startBudgetMonitoring(
                budgetMinutes: budgetMinutes,
                apps: budgetSelection
            )
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}

#Preview {
    ScrollView {
        BudgetConfigView(profile: nil)
            .padding()
    }
    .background(ClarityColors.background)
}
