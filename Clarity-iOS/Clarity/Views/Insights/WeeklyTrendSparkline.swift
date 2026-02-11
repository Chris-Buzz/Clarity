import SwiftUI

/// Seven vertical bars showing daily focus minutes for the current week.
struct WeeklyTrendSparkline: View {
    let sessions: [FocusSession]

    var body: some View {
        let dailyMinutes = computeDailyMinutes()
        let maxMinutes = max(dailyMinutes.max() ?? 1, 1)
        let todayIndex = Calendar.current.component(.weekday, from: Date()) - 1 // 0=Sun

        VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
            HStack(alignment: .bottom, spacing: ClaritySpacing.sm) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: ClaritySpacing.xs) {
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                index == todayIndex
                                    ? ClarityColors.primary
                                    : ClarityColors.primary.opacity(0.4)
                            )
                            .frame(
                                height: max(4, CGFloat(dailyMinutes[index]) / CGFloat(maxMinutes) * 100)
                            )

                        // Day label
                        Text(dayLabel(index))
                            .font(ClarityFonts.mono(size: 9))
                            .foregroundStyle(
                                index == todayIndex
                                    ? ClarityColors.textPrimary
                                    : ClarityColors.textMuted
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120, alignment: .bottom)
        }
        .padding(ClaritySpacing.md)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: ClarityRadius.xl)
                .stroke(ClarityColors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    /// Returns an array of 7 total-minute values, indexed by weekday (0=Sun).
    private func computeDailyMinutes() -> [Int] {
        let calendar = Calendar.current
        var result = Array(repeating: 0, count: 7)
        for session in sessions {
            let weekday = calendar.component(.weekday, from: session.startTime) - 1
            if weekday >= 0 && weekday < 7 {
                result[weekday] += session.actualDuration
            }
        }
        return result
    }

    private func dayLabel(_ index: Int) -> String {
        ["S", "M", "T", "W", "T", "F", "S"][index]
    }
}

#Preview {
    WeeklyTrendSparkline(sessions: [])
        .padding()
        .background(ClarityColors.background)
}
