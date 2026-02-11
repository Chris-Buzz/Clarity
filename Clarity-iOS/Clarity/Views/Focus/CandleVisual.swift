import SwiftUI

/// Melting candle that shrinks as the session progresses.
/// `progress` goes from 1.0 (full) to 0.0 (done).
struct CandleVisual: View {

    let progress: Double
    let isPaused: Bool

    @State private var flameRotation: Double = -5
    @State private var glowScale: CGFloat = 1.0

    private let candleWidth: CGFloat = 44
    private let maxCandleHeight: CGFloat = 160
    private let wickHeight: CGFloat = 12

    private var candleHeight: CGFloat {
        max(maxCandleHeight * CGFloat(progress), 12)
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Flame + Glow

            ZStack {
                // Glow behind flame
                Circle()
                    .fill(ClarityColors.primary.opacity(isPaused ? 0.05 : 0.2))
                    .frame(width: 60, height: 60)
                    .blur(radius: 20)
                    .scaleEffect(glowScale)

                // Flame icon
                Image(systemName: "flame.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ClarityColors.warning, ClarityColors.primary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(isPaused ? 0.3 : 1.0)
                    .rotationEffect(.degrees(flameRotation))
            }
            .offset(y: 8) // Overlap the wick slightly

            // MARK: - Wick

            Rectangle()
                .fill(Color(hex: "#333333"))
                .frame(width: 2, height: wickHeight)

            // MARK: - Candle Body

            RoundedRectangle(cornerRadius: ClarityRadius.sm)
                .fill(
                    LinearGradient(
                        colors: [ClarityColors.primary, ClarityColors.warning],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: candleWidth, height: candleHeight)
                .animation(.easeInOut(duration: 1.0), value: candleHeight)
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: isPaused) { _, paused in
            if paused {
                // Reset to neutral when paused
                withAnimation(.easeOut(duration: 0.5)) {
                    flameRotation = 0
                    glowScale = 0.8
                }
            } else {
                startAnimations()
            }
        }
    }

    private func startAnimations() {
        // Flame sway
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            flameRotation = 5
        }

        // Glow pulse
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            glowScale = 1.15
        }
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        VStack(spacing: 40) {
            CandleVisual(progress: 0.8, isPaused: false)
            CandleVisual(progress: 0.3, isPaused: true)
        }
    }
}
