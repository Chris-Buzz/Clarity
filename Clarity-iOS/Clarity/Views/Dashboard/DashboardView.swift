import SwiftUI
import SwiftData

/// Main home tab — greeting, clarity score ring, quick stats, intention card,
/// and session start button.
struct DashboardView: View {

    @Environment(AppState.self) private var appState
    @Environment(SessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext

    @Query private var users: [UserProfile]
    @Query(sort: \FocusSession.startTime, order: .reverse) private var sessions: [FocusSession]
    @Query(filter: #Predicate<ImplementationIntention> { $0.isActive })
    private var activeIntentions: [ImplementationIntention]

    @State private var showQuickStart = false

    private var user: UserProfile? { users.first }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: ClaritySpacing.lg) {

                // MARK: - Greeting

                greetingSection

                // MARK: - Clarity Score

                HStack {
                    Spacer()
                    ClarityScoreRing(score: clarityScore, delta: scoreDelta)
                    Spacer()
                }

                // MARK: - Daily Budget

                BudgetStatusCard()

                // MARK: - Quick Stats

                quickStatsRow

                // MARK: - Connection Stats

                ConnectionStatsCard()

                // MARK: - Important People

                ImportantPeopleStrip()

                // MARK: - Health Correlation (placeholder)

                healthCard

                // MARK: - Intention

                if let intention = activeIntentions.first {
                    intentionCard(intention)
                }

                // MARK: - Begin Session

                ClarityButton("Begin Session", variant: .primary, size: .lg, fullWidth: true) {
                    showQuickStart = true
                }

                // MARK: - Footer

                HStack(spacing: ClaritySpacing.sm) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 12))
                    Text("\(user?.frictionThresholds.count ?? 0) apps will be blocked")
                        .font(ClarityFonts.sans(size: 13))
                }
                .foregroundStyle(ClarityColors.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.bottom, ClaritySpacing.lg)
            }
            .padding(.horizontal, ClaritySpacing.lg)
            .padding(.top, ClaritySpacing.md)
        }
        .background(ClarityColors.background)
        .sheet(isPresented: $showQuickStart) {
            QuickStartButton()
        }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
            Text("WELCOME BACK")
                .font(ClarityFonts.mono(size: 10))
                .tracking(3)
                .foregroundStyle(ClarityColors.textMuted)

            // "Find your\nclarity" — two-tone serif title
            (Text("Find your\n")
                .font(ClarityFonts.serif(size: 42))
                .foregroundStyle(ClarityColors.textPrimary)
             +
             Text("clarity")
                .font(ClarityFonts.serif(size: 42))
                .foregroundStyle(ClarityColors.primary)
            )
            .lineSpacing(4)

            if let name = user?.name {
                Text(name)
                    .font(ClarityFonts.sansMedium(size: 16))
                    .foregroundStyle(ClarityColors.textSecondary)
            }
        }
    }

    // MARK: - Quick Stats Row

    private var quickStatsRow: some View {
        HStack(spacing: ClaritySpacing.sm) {
            statCard(label: "SCREEN TIME", value: formattedScreenTime, unit: "h")
            statCard(label: "STREAK", value: "\(user?.streak ?? 0)", unit: "days")
            statCard(label: "PICKUPS", value: "\(todayPickups)", unit: "")
        }
    }

    private func statCard(label: String, value: String, unit: String) -> some View {
        VStack(spacing: ClaritySpacing.xs) {
            Text(label)
                .font(ClarityFonts.mono(size: 9))
                .tracking(2)
                .foregroundStyle(ClarityColors.textMuted)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(ClarityFonts.serif(size: 24))
                    .foregroundStyle(ClarityColors.textPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(ClarityFonts.sans(size: 12))
                        .foregroundStyle(ClarityColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ClaritySpacing.md)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: ClarityRadius.lg)
                .stroke(ClarityColors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Health Correlation Card

    private var healthCard: some View {
        HStack(spacing: ClaritySpacing.md) {
            Image(systemName: "moon.fill")
                .font(.system(size: 20))
                .foregroundStyle(ClarityColors.primary)

            VStack(alignment: .leading, spacing: ClaritySpacing.xs) {
                Text("You slept 7.2h")
                    .font(ClarityFonts.sansMedium(size: 15))
                    .foregroundStyle(ClarityColors.textPrimary)

                Text("Better sleep correlates with 23% less screen time")
                    .font(ClarityFonts.sans(size: 13))
                    .foregroundStyle(ClarityColors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(ClaritySpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: ClarityRadius.xl)
                .stroke(ClarityColors.border, lineWidth: 1)
        )
    }

    // MARK: - Intention Card

    private func intentionCard(_ intention: ImplementationIntention) -> some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
            Text("TODAY'S INTENTION")
                .font(ClarityFonts.mono(size: 10))
                .tracking(3)
                .foregroundStyle(ClarityColors.textMuted)

            Text("If \(intention.triggerCondition), then \(intention.intendedAction)")
                .font(ClarityFonts.sans(size: 15))
                .foregroundStyle(ClarityColors.textSecondary)
                .lineSpacing(4)
        }
        .padding(ClaritySpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
    }

    // MARK: - Computed Data

    /// Placeholder clarity score based on recent session completion rate.
    private var clarityScore: Double {
        guard !sessions.isEmpty else { return 0 }
        let recent = Array(sessions.prefix(10))
        let completed = recent.filter(\.wasCompleted).count
        return Double(completed) / Double(recent.count) * 100
    }

    private var scoreDelta: Double {
        // Placeholder: compare last 7 sessions vs previous 7
        guard sessions.count >= 14 else { return 5.0 }
        let recent = sessions.prefix(7).filter(\.wasCompleted).count
        let prev = sessions.dropFirst(7).prefix(7).filter(\.wasCompleted).count
        return Double(recent - prev) / 7.0 * 100
    }

    private var formattedScreenTime: String {
        // Sum today's completed session durations as a proxy
        let todaySessions = sessions.filter { Calendar.current.isDateInToday($0.startTime) }
        let totalMinutes = todaySessions.reduce(0) { $0 + $1.actualDuration }
        let hours = Double(totalMinutes) / 60.0
        return String(format: "%.1f", hours)
    }

    private var todayPickups: Int {
        // Placeholder — real value would come from ScreenTime API
        12
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
        .environment(SessionManager())
        .modelContainer(for: [UserProfile.self, FocusSession.self, ImplementationIntention.self, ConnectionLog.self, ImportantContact.self], inMemory: true)
}
