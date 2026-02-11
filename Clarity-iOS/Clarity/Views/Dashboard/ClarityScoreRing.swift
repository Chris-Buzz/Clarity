import SwiftUI

/// Animated circular score indicator with an orange gradient arc.
/// Displays the clarity score (0-100) with a delta comparison.
struct ClarityScoreRing: View {

    let score: Double
    let delta: Double

    @State private var animatedTrim: CGFloat = 0

    private let ringSize: CGFloat = 200
    private let ringWidth: CGFloat = 8

    var body: some View {
        ZStack {
            // Track (background ring)
            Circle()
                .stroke(ClarityColors.borderSubtle, lineWidth: ringWidth)
                .frame(width: ringSize, height: ringSize)

            // Filled arc — orange gradient
            Circle()
                .trim(from: 0, to: animatedTrim)
                .stroke(
                    AngularGradient(
                        colors: [ClarityColors.primary, ClarityColors.warning, ClarityColors.primary],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: ClaritySpacing.xs) {
                Text("\(Int(score))")
                    .font(ClarityFonts.serif(size: 56))
                    .foregroundStyle(ClarityColors.textPrimary)
                    // Use a fixed-width frame so the number doesn't shift layout
                    .monospacedDigit()

                Text("CLARITY SCORE")
                    .font(ClarityFonts.mono(size: 9))
                    .tracking(3)
                    .foregroundStyle(ClarityColors.textMuted)

                // Delta indicator
                deltaLabel
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                animatedTrim = CGFloat(min(score, 100)) / 100.0
            }
        }
    }

    // MARK: - Delta Label

    @ViewBuilder
    private var deltaLabel: some View {
        if delta != 0 {
            let isPositive = delta > 0
            let arrow = isPositive ? "↑" : "↓"
            let color = isPositive ? ClarityColors.success : ClarityColors.danger

            Text("\(arrow) \(Int(abs(delta))) from last week")
                .font(ClarityFonts.sans(size: 12))
                .foregroundStyle(color)
        }
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        ClarityScoreRing(score: 73, delta: 8)
    }
}
