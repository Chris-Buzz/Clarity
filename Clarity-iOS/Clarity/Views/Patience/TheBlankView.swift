import SwiftUI

/// The most minimal, intentional view in the app.
/// Permission to exist without input. Just a timer and silence.
struct TheBlankView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer?
    @State private var gradientShift: Bool = false

    var body: some View {
        ZStack {
            // Slowly shifting patience gradient
            LinearGradient(
                colors: gradientShift
                    ? [Color(red: 0.03, green: 0.1, blue: 0.12), Color(red: 0.05, green: 0.05, blue: 0.15)]
                    : [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.03, green: 0.1, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                Spacer()

                // Elapsed time
                Text(formattedTime)
                    .font(ClarityFonts.serif(size: 48))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                Text("Permission to exist without input")
                    .font(ClarityFonts.sans(size: 15))
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.top, ClaritySpacing.md)

                Spacer()

                // Subtle done button
                Button {
                    HapticManager.light()
                    dismiss()
                } label: {
                    Text("Done")
                        .font(ClarityFonts.sans(size: 15))
                        .foregroundStyle(.white.opacity(0.35))
                        .padding(.bottom, ClaritySpacing.xxl)
                }
            }
        }
        .onAppear {
            HapticManager.light()

            // Start elapsed timer
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                Task { @MainActor in
                    elapsed += 1
                }
            }

            // Slow gradient animation
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                gradientShift = true
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var formattedTime: String {
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    TheBlankView()
}
