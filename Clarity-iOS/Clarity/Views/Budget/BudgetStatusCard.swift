import SwiftUI
import SwiftData

/// Dashboard card showing daily budget progress as a circular ring.
/// Orange when under budget, transitions to red as approaching/exceeding the limit.
/// Shows an "Emergency Unlock" button when locked.
struct BudgetStatusCard: View {

    @Query private var profiles: [UserProfile]

    @State private var showEmergencyUnlock = false

    private var profile: UserProfile? { profiles.first }
    private var budgetService: DailyBudgetService { .shared }

    private var budgetMinutes: Int { profile?.dailyBudgetMinutes ?? 180 }
    private var isEnabled: Bool { profile?.dailyBudgetEnabled ?? false }
    private var isLocked: Bool { budgetService.isLocked }
    private var emergencyActive: Bool { budgetService.emergencyUnlockActive }

    // Placeholder: real value would come from DeviceActivity reports
    private var minutesUsedToday: Int {
        let defaults = UserDefaults(suiteName: "group.com.clarity-focus")
        return defaults?.integer(forKey: "minutesUsedToday") ?? 0
    }

    private var minutesRemaining: Int {
        max(budgetMinutes - minutesUsedToday, 0)
    }

    private var progress: Double {
        guard budgetMinutes > 0 else { return 0 }
        return min(Double(minutesUsedToday) / Double(budgetMinutes), 1.0)
    }

    /// Ring color shifts from orange to red as usage approaches the limit
    private var ringColor: Color {
        if isLocked { return ClarityColors.danger }
        if progress > 0.85 { return ClarityColors.danger }
        if progress > 0.65 { return Color(red: 1.0, green: 0.6, blue: 0.0) } // amber
        return ClarityColors.primary
    }

    var body: some View {
        if !isEnabled { return AnyView(EmptyView()) }

        return AnyView(
            VStack(spacing: ClaritySpacing.md) {
                HStack(spacing: ClaritySpacing.lg) {
                    // Mini progress ring
                    ZStack {
                        Circle()
                            .stroke(ClarityColors.surface, lineWidth: 5)
                            .frame(width: 56, height: 56)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(ringColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .frame(width: 56, height: 56)
                            .rotationEffect(.degrees(-90))

                        if isLocked && !emergencyActive {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(ClarityColors.danger)
                        } else {
                            Text("\(Int(progress * 100))%")
                                .font(ClarityFonts.mono(size: 11))
                                .foregroundStyle(ClarityColors.textPrimary)
                        }
                    }

                    // Budget info
                    VStack(alignment: .leading, spacing: ClaritySpacing.xs) {
                        Text("DAILY BUDGET")
                            .font(ClarityFonts.mono(size: 9))
                            .tracking(2)
                            .foregroundStyle(ClarityColors.textMuted)

                        if isLocked && !emergencyActive {
                            Text("Budget Reached")
                                .font(ClarityFonts.sansSemiBold(size: 16))
                                .foregroundStyle(ClarityColors.danger)
                        } else if emergencyActive, let expires = budgetService.emergencyUnlockExpiresAt {
                            let remaining = Int(expires.timeIntervalSinceNow / 60)
                            Text("Unlocked — \(remaining)m left")
                                .font(ClarityFonts.sansSemiBold(size: 16))
                                .foregroundStyle(ClarityColors.primary)
                        } else {
                            Text("\(formatMinutes(minutesUsedToday)) / \(formatMinutes(budgetMinutes))")
                                .font(ClarityFonts.sansSemiBold(size: 16))
                                .foregroundStyle(ClarityColors.textPrimary)
                        }

                        if !isLocked {
                            Text("\(formatMinutes(minutesRemaining)) remaining")
                                .font(ClarityFonts.sans(size: 13))
                                .foregroundStyle(ClarityColors.textTertiary)
                        }
                    }

                    Spacer()
                }

                // Emergency unlock button when locked
                if isLocked && !emergencyActive {
                    ClarityButton("Emergency Unlock", variant: .ghost, size: .sm, fullWidth: true) {
                        HapticManager.warning()
                        showEmergencyUnlock = true
                    }
                }
            }
            .padding(ClaritySpacing.md)
            .background(ClarityColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: ClarityRadius.xl)
                    .stroke(isLocked ? ClarityColors.danger.opacity(0.4) : ClarityColors.borderSubtle, lineWidth: 1)
            )
            .sheet(isPresented: $showEmergencyUnlock) {
                EmergencyUnlockView(
                    budgetService: budgetService,
                    waitMinutes: profile?.emergencyWaitMinutes ?? 5,
                    remainingUnlocks: budgetService.remainingUnlocks,
                    minutesUsedToday: minutesUsedToday,
                    budgetMinutes: budgetMinutes
                )
            }
        )
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

#Preview {
    VStack {
        BudgetStatusCard()
    }
    .padding()
    .background(ClarityColors.background)
    .modelContainer(for: [UserProfile.self], inMemory: true)
}
