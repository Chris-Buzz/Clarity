import SwiftUI

/// A breathing orange glow that sits behind content.
/// The circle scales between 1.0 and 1.15 over 4 seconds with heavy blur.
struct AnimatedBackground: View {

    @State private var isExpanded = false

    var body: some View {
        GeometryReader { geo in
            Circle()
                .fill(ClarityColors.primary.opacity(0.1))
                .frame(width: geo.size.width * 0.8, height: geo.size.width * 0.8)
                .blur(radius: 80)
                .scaleEffect(isExpanded ? 1.15 : 1.0)
                .position(x: geo.size.width / 2, y: geo.size.height * 0.35)
                .animation(
                    .easeInOut(duration: 4).repeatForever(autoreverses: true),
                    value: isExpanded
                )
                .onAppear { isExpanded = true }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        AnimatedBackground()
        Text("Content")
            .foregroundStyle(.white)
    }
}
