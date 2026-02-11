import SwiftUI
import SwiftData

/// Dashboard card showing today's prosocial connection stats.
struct ConnectionStatsCard: View {
    @Query(sort: \ConnectionLog.timestamp, order: .reverse)
    private var allLogs: [ConnectionLog]

    private var todayLogs: [ConnectionLog] {
        let todayStart = Calendar.current.startOfDay(for: Date())
        return allLogs.filter { $0.timestamp > todayStart }
    }

    private var connectionCount: Int {
        Set(todayLogs.compactMap { $0.contactName }).count
    }

    private var totalMinutes: Int {
        todayLogs.reduce(0) { $0 + $1.durationSeconds } / 60
    }

    private var contactNames: [String] {
        Array(Set(todayLogs.compactMap { $0.contactName })).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.md) {
            Text("CONNECTIONS")
                .font(ClarityFonts.mono(size: 11))
                .tracking(3)
                .foregroundStyle(ClarityColors.textMuted)

            if connectionCount > 0 {
                HStack(alignment: .lastTextBaseline, spacing: ClaritySpacing.xs) {
                    Text("\(connectionCount)")
                        .font(ClarityFonts.serif(size: 36))
                        .foregroundStyle(ClarityColors.textPrimary)

                    Text(connectionCount == 1 ? "person today" : "people today")
                        .font(ClarityFonts.sans(size: 15))
                        .foregroundStyle(ClarityColors.textSecondary)
                }

                if totalMinutes > 0 {
                    Text("\(totalMinutes) minutes of real conversation")
                        .font(ClarityFonts.sans(size: 14))
                        .foregroundStyle(ClarityColors.textTertiary)
                }

                // Contact name pills
                if !contactNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: ClaritySpacing.xs) {
                            ForEach(contactNames, id: \.self) { name in
                                Text(name)
                                    .font(ClarityFonts.sansMedium(size: 12))
                                    .foregroundStyle(ClarityColors.primary)
                                    .padding(.horizontal, ClaritySpacing.sm)
                                    .padding(.vertical, ClaritySpacing.xs)
                                    .background(ClarityColors.primaryMuted)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            } else {
                Text("No real connections yet today.")
                    .font(ClarityFonts.sans(size: 15))
                    .foregroundStyle(ClarityColors.textMuted)

                Text("Your people miss you.")
                    .font(ClarityFonts.sans(size: 14))
                    .foregroundStyle(ClarityColors.textTertiary)
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
}
