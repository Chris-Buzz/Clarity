import SwiftUI

/// Health correlation insights card with placeholder insights.
struct WeeklyReportView: View {

    private let insights: [(icon: String, text: String)] = [
        ("moon.zzz.fill", "Sleep and screen time are inversely correlated"),
        ("bed.double.fill", "Your best focus days follow 7+ hours of sleep"),
        ("sunset.fill", "Evening sessions have higher completion rates"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.md) {
            Text("WEEKLY INSIGHTS")
                .font(ClarityFonts.mono(size: 11))
                .tracking(3)
                .foregroundStyle(ClarityColors.textMuted)

            VStack(spacing: ClaritySpacing.sm) {
                ForEach(insights, id: \.text) { insight in
                    HStack(spacing: ClaritySpacing.sm) {
                        Image(systemName: insight.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(ClarityColors.primary)
                            .frame(width: 28, height: 28)

                        Text(insight.text)
                            .font(ClarityFonts.sans(size: 14))
                            .foregroundStyle(ClarityColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(ClaritySpacing.sm + 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ClarityColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                }
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
}

#Preview {
    WeeklyReportView()
        .padding()
        .background(ClarityColors.background)
}
