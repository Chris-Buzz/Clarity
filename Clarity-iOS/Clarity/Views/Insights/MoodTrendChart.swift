import SwiftUI
import SwiftData

/// Line chart of mood valence over the last 7 days, built with SwiftUI Path.
struct MoodTrendChart: View {
    @Query(sort: \MoodEntry.timestamp, order: .reverse)
    private var allEntries: [MoodEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.md) {
            Text("MOOD TREND")
                .font(ClarityFonts.mono(size: 11))
                .tracking(3)
                .foregroundStyle(ClarityColors.textMuted)

            if dataPoints.isEmpty {
                Text("Start logging moods to see trends")
                    .font(ClarityFonts.sans(size: 14))
                    .foregroundStyle(ClarityColors.textMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, ClaritySpacing.xl)
            } else {
                chartContent
            }
        }
        .padding(ClaritySpacing.md)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: ClarityRadius.xl)
                .stroke(ClarityColors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Chart

    private var chartContent: some View {
        let points = dataPoints

        return HStack(spacing: 0) {
            // Y-axis emoji labels
            VStack {
                Text("\u{1F60A}").font(.system(size: 14))
                Spacer()
                Text("\u{1F614}").font(.system(size: 14))
            }
            .frame(width: 24)

            // Chart area
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                ZStack {
                    // Neutral dashed line at y=0
                    Path { path in
                        let y = h / 2
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: w, y: y))
                    }
                    .stroke(ClarityColors.textMuted, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                    // Line
                    Path { path in
                        for (i, point) in points.enumerated() {
                            let x = points.count == 1 ? w / 2 : w * CGFloat(i) / CGFloat(points.count - 1)
                            // valence -1..1 maps to h..0
                            let y = h * (1.0 - (point.valence + 1.0) / 2.0)
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(ClarityColors.primary, lineWidth: 2)

                    // Dots
                    ForEach(Array(points.enumerated()), id: \.offset) { i, point in
                        let x = points.count == 1 ? w / 2 : w * CGFloat(i) / CGFloat(points.count - 1)
                        let y = h * (1.0 - (point.valence + 1.0) / 2.0)

                        Circle()
                            .fill(ClarityColors.primary)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                    }
                }
            }
            .frame(height: 120)
        }
    }

    // MARK: - Data

    /// Average mood per day for the last 7 days.
    private var dataPoints: [(day: Date, valence: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) else { return [] }

        let recent = allEntries.filter { $0.timestamp >= weekAgo }
        guard !recent.isEmpty else { return [] }

        // Group by day, average valence
        var grouped: [Date: [Double]] = [:]
        for entry in recent {
            let day = calendar.startOfDay(for: entry.timestamp)
            grouped[day, default: []].append(entry.valence)
        }

        return grouped
            .map { (day: $0.key, valence: $0.value.reduce(0, +) / Double($0.value.count)) }
            .sorted { $0.day < $1.day }
    }
}

#Preview {
    MoodTrendChart()
        .padding()
        .background(ClarityColors.background)
        .modelContainer(for: MoodEntry.self, inMemory: true)
}
