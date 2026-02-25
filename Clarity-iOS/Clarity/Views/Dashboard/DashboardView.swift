import SwiftUI
import SwiftData

/// Main home tab — greeting, patience score ring, quick stats, countdown status,
/// active challenge, fog level, and session start button.
struct DashboardView: View {

    @Environment(AppState.self) private var appState
    @Environment(SessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext

    @Query private var users: [UserProfile]
    @Query(sort: \FocusSession.startTime, order: .reverse) private var sessions: [FocusSession]
    @Query(
        filter: #Predicate<PatienceChallenge> { !$0.wasCompleted },
        sort: \PatienceChallenge.date,
        order: .reverse
    )
    private var activeChallenges: [PatienceChallenge]
    @Query(sort: \DopamineProgram.startDate, order: .reverse) private var programs: [DopamineProgram]

    @State private var showQuickStart = false

    private var user: UserProfile? { users.first }
    private var countdownManager = CountdownManager.shared
    private var patienceManager = PatienceManager.shared

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: ClaritySpacing.lg) {

                // MARK: - Greeting
                greetingSection

                // MARK: - Patience Score
                HStack {
                    Spacer()
                    PatienceScoreRing(score: patienceScore, delta: scoreDelta)
                    Spacer()
                }

                // MARK: - Quick Stats
                quickStatsRow

                // MARK: - Countdown Status
                countdownStatusCard

                // MARK: - Active Challenge
                activeChallengeCard

                // MARK: - Fog Level
                fogLevelCard

                // MARK: - Daily Budget
                BudgetStatusCard()

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

            // "Train your\npatience" — two-tone serif title
            (Text("Train your\n")
                .font(ClarityFonts.serif(size: 42))
                .foregroundStyle(ClarityColors.textPrimary)
             +
             Text("patience")
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
            statCard(label: "PATIENCE STREAK", value: "\(user?.challengeStreak ?? 0)", unit: "days")
            statCard(label: "OPENS TODAY", value: "\(countdownManager.opensToday)", unit: "")
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

    // MARK: - Countdown Status Card

    private var countdownStatusCard: some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.md) {
            Text("COUNTDOWN ESCALATION")
                .font(ClarityFonts.mono(size: 9))
                .tracking(3)
                .foregroundStyle(ClarityColors.textMuted)

            Text("Next unlock: \(countdownManager.currentDelay)s")
                .font(ClarityFonts.serif(size: 22))
                .foregroundStyle(.white)

            // Escalation sequence preview
            HStack(spacing: ClaritySpacing.xs) {
                ForEach(Array(countdownManager.escalationSequence.enumerated()), id: \.offset) { index, delay in
                    let isCurrent = index == min(countdownManager.opensToday, countdownManager.escalationSequence.count - 1)

                    Text("\(delay)s")
                        .font(ClarityFonts.mono(size: 11))
                        .foregroundStyle(isCurrent ? ClarityColors.primary : .white.opacity(0.3))
                        .padding(.horizontal, ClaritySpacing.sm)
                        .padding(.vertical, ClaritySpacing.xs)
                        .background(isCurrent ? ClarityColors.primaryMuted : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.sm))

                    if index < countdownManager.escalationSequence.count - 1 {
                        Text("\u{2192}")
                            .font(ClarityFonts.sans(size: 10))
                            .foregroundStyle(.white.opacity(0.2))
                    }
                }
            }
        }
        .padding(ClaritySpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: ClarityRadius.xl)
                .stroke(ClarityColors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Active Challenge Card

    private var activeChallengeCard: some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
            Text("TODAY'S CHALLENGE")
                .font(ClarityFonts.mono(size: 9))
                .tracking(3)
                .foregroundStyle(ClarityColors.textMuted)

            if let challenge = activeChallenges.first(where: { Calendar.current.isDateInToday($0.date) }) {
                Text(challenge.challengeText)
                    .font(ClarityFonts.sans(size: 15))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineSpacing(4)

                Text(challenge.challengeType.uppercased())
                    .font(ClarityFonts.mono(size: 9))
                    .tracking(2)
                    .foregroundStyle(ClarityColors.primary)
            } else {
                Text("No active challenge")
                    .font(ClarityFonts.sans(size: 15))
                    .foregroundStyle(.white.opacity(0.4))

                ClarityButton("Generate One", variant: .ghost, size: .sm) {
                    HapticManager.light()
                    // Navigate to patience tab
                    appState.selectedTab = .patience
                }
            }
        }
        .padding(ClaritySpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: ClarityRadius.xl)
                .stroke(ClarityColors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Fog Level Card

    private var fogLevelCard: some View {
        HStack(spacing: ClaritySpacing.md) {
            // Teal dot sized by fog level
            Circle()
                .fill(ClarityColors.teal)
                .frame(
                    width: CGFloat(patienceManager.currentFogLevel) * 6 + 8,
                    height: CGFloat(patienceManager.currentFogLevel) * 6 + 8
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: patienceManager.currentFogLevel)

            VStack(alignment: .leading, spacing: 2) {
                Text("MENTAL CLARITY")
                    .font(ClarityFonts.mono(size: 9))
                    .tracking(3)
                    .foregroundStyle(ClarityColors.textMuted)

                Text(fogLevelText)
                    .font(ClarityFonts.sansMedium(size: 15))
                    .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding(ClaritySpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: ClarityRadius.xl)
                .stroke(ClarityColors.borderSubtle, lineWidth: 1)
        )
    }

    private var fogLevelText: String {
        switch patienceManager.currentFogLevel {
        case 1: return "Heavy fog"
        case 2: return "Foggy"
        case 3: return "Neutral"
        case 4: return "Fairly clear"
        case 5: return "Crystal clear"
        default: return "Neutral"
        }
    }

    // MARK: - Computed Data

    private var patienceScore: Double {
        let programDay = programs.first?.currentDay ?? 0
        let todaysChallenges = activeChallenges.isEmpty ? 0 : (patienceManager.todaysChallengeCompleted ? 1 : 0)
        return Double(patienceManager.calculatePatienceScore(
            frictionCompletions: patienceManager.frictionCompletionsToday,
            challengesDone: todaysChallenges,
            fogEntriesToday: patienceManager.currentFogLevel > 0 ? 1 : 0,
            programDay: programDay
        ))
    }

    private var scoreDelta: Double {
        // Placeholder: compare with a reference score
        guard sessions.count >= 14 else { return 5.0 }
        let recent = sessions.prefix(7).filter(\.wasCompleted).count
        let prev = sessions.dropFirst(7).prefix(7).filter(\.wasCompleted).count
        return Double(recent - prev) / 7.0 * 100
    }

    private var formattedScreenTime: String {
        let todaySessions = sessions.filter { Calendar.current.isDateInToday($0.startTime) }
        let totalMinutes = todaySessions.reduce(0) { $0 + $1.actualDuration }
        let hours = Double(totalMinutes) / 60.0
        return String(format: "%.1f", hours)
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
        .environment(SessionManager())
        .modelContainer(for: [
            UserProfile.self,
            FocusSession.self,
            PatienceChallenge.self,
            DopamineProgram.self,
        ], inMemory: true)
}
