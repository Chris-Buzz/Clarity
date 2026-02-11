import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \FocusSession.startTime, order: .reverse)
    private var sessions: [FocusSession]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: ClaritySpacing.lg) {

                // MARK: - Title
                Text("Continuity")
                    .font(ClarityFonts.serif(size: 36))
                    .foregroundStyle(ClarityColors.textPrimary)

                // MARK: - Accumulated Stillness
                VStack(alignment: .leading, spacing: ClaritySpacing.xs) {
                    Text("ACCUMULATED STILLNESS")
                        .font(ClarityFonts.mono(size: 10))
                        .tracking(3)
                        .foregroundStyle(ClarityColors.textMuted)

                    Text(totalHoursString)
                        .font(ClarityFonts.serif(size: 48, weight: .bold))
                        .foregroundStyle(ClarityColors.textPrimary)

                    Text("hours")
                        .font(ClarityFonts.sans(size: 14))
                        .foregroundStyle(ClarityColors.textSecondary)
                }

                // MARK: - Stats Row
                HStack(spacing: ClaritySpacing.sm) {
                    StatCard(emoji: "\u{1F525}", value: "\(currentStreak)", label: "day streak")
                    StatCard(emoji: nil, value: "\(completedCount)", label: "completed")
                    StatCard(emoji: "\u{2B50}", value: averageRatingString, label: "avg rating")
                }

                // MARK: - This Week
                SectionLabel("THIS WEEK")
                WeeklyTrendSparkline(sessions: sessionsThisWeek)

                // MARK: - Mood Trend
                MoodTrendChart()

                // MARK: - Weekly Insights
                WeeklyReportView()

                // MARK: - Recent Sessions
                SectionLabel("RECENT SESSIONS")
                SessionHistoryList(sessions: sessions)
            }
            .padding(.horizontal, ClaritySpacing.md)
            .padding(.top, ClaritySpacing.lg)
            .padding(.bottom, ClaritySpacing.xxxl)
        }
        .background(ClarityColors.background)
    }

    // MARK: - Computed Properties

    private var totalHoursString: String {
        let totalMinutes = sessions.reduce(0) { $0 + $1.actualDuration }
        let hours = Double(totalMinutes) / 60.0
        return String(format: "%.1f", hours)
    }

    private var currentStreak: Int {
        // Simple streak: count consecutive days backward from today
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let dayHasSession = sessions.contains { session in
                calendar.isDate(session.startTime, inSameDayAs: checkDate) && session.wasCompleted
            }
            if dayHasSession {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return streak
    }

    private var completedCount: Int {
        sessions.filter(\.wasCompleted).count
    }

    private var averageRatingString: String {
        let rated = sessions.compactMap(\.rating)
        guard !rated.isEmpty else { return "--" }
        let avg = Double(rated.reduce(0, +)) / Double(rated.count)
        return String(format: "%.1f", avg)
    }

    private var sessionsThisWeek: [FocusSession] {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: Date()
        )) else { return [] }
        return sessions.filter { $0.startTime >= weekStart }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let emoji: String?
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: ClaritySpacing.xs) {
            HStack(spacing: 4) {
                if let emoji {
                    Text(emoji).font(.system(size: 14))
                }
                Text(value)
                    .font(ClarityFonts.sansSemiBold(size: 20))
                    .foregroundStyle(ClarityColors.textPrimary)
            }
            Text(label)
                .font(ClarityFonts.sans(size: 12))
                .foregroundStyle(ClarityColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ClaritySpacing.md)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: ClarityRadius.md)
                .stroke(ClarityColors.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Section Label

struct SectionLabel: View {
    let text: String
    var color: Color = ClarityColors.textMuted

    init(_ text: String, color: Color = ClarityColors.textMuted) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(ClarityFonts.mono(size: 11))
            .tracking(3)
            .foregroundStyle(color)
            .textCase(.uppercase)
            .padding(.bottom, ClaritySpacing.xs)
    }
}

// MARK: - Session History List

struct SessionHistoryList: View {
    let sessions: [FocusSession]

    var body: some View {
        if sessions.isEmpty {
            Text("No sessions yet. Start your first focus session.")
                .font(ClarityFonts.sans(size: 14))
                .foregroundStyle(ClarityColors.textMuted)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, ClaritySpacing.xl)
        } else {
            LazyVStack(spacing: ClaritySpacing.sm) {
                ForEach(sessions.prefix(20), id: \.id) { session in
                    SessionCard(session: session)
                }
            }
        }
    }
}

// MARK: - Session Card

private struct SessionCard: View {
    let session: FocusSession

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(session.wasCompleted ? ClarityColors.success : ClarityColors.danger)
                .frame(width: 3)
                .padding(.vertical, ClaritySpacing.sm)

            VStack(alignment: .leading, spacing: ClaritySpacing.xs) {
                HStack {
                    Text(session.task.isEmpty ? "Focus Session" : session.task)
                        .font(ClarityFonts.sansSemiBold(size: 15))
                        .foregroundStyle(ClarityColors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text(session.startTime.relativeDescription)
                        .font(ClarityFonts.mono(size: 11))
                        .foregroundStyle(ClarityColors.textMuted)
                }

                HStack(spacing: ClaritySpacing.md) {
                    Text("\(session.actualDuration) min")
                        .font(ClarityFonts.sans(size: 13))
                        .foregroundStyle(ClarityColors.textSecondary)

                    if session.xpEarned > 0 {
                        Text("+\(session.xpEarned) XP")
                            .font(ClarityFonts.sans(size: 13))
                            .foregroundStyle(ClarityColors.primary)
                    }
                }
            }
            .padding(.leading, ClaritySpacing.sm)
        }
        .padding(ClaritySpacing.md)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: ClarityRadius.lg)
                .stroke(ClarityColors.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Date Helper

private extension Date {
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: [FocusSession.self, MoodEntry.self], inMemory: true)
}
