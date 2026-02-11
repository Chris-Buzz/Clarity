import SwiftUI

/// Challenge: List 3 things you are grateful for.
struct GratitudeChallenge: View {

    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var items: [String] = ["", "", ""]

    private var filledCount: Int {
        items.filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 }.count
    }

    var body: some View {
        ChallengeTemplate(
            icon: "heart.fill",
            iconColor: .pink,
            category: "Gratitude",
            title: "3 things you're grateful for",
            onCancel: onCancel
        ) {
            VStack(spacing: ClaritySpacing.sm) {
                ForEach(0..<3, id: \.self) { index in
                    HStack(spacing: ClaritySpacing.sm) {
                        Text("\(index + 1).")
                            .font(ClarityFonts.mono(size: 14))
                            .foregroundStyle(ClarityColors.textMuted)
                            .frame(width: 24)

                        TextField("I'm grateful for...", text: $items[index])
                            .font(ClarityFonts.sans(size: 16))
                            .foregroundStyle(ClarityColors.textPrimary)
                            .padding(ClaritySpacing.sm)
                            .background(ClarityColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: ClarityRadius.md)
                                    .stroke(ClarityColors.border, lineWidth: 1)
                            )
                    }
                }
            }

            Text("\(filledCount)/3 completed")
                .font(ClarityFonts.sans(size: 13))
                .foregroundStyle(ClarityColors.textTertiary)

            ClarityButton("Done", variant: .primary, fullWidth: true) {
                onComplete()
            }
            .opacity(filledCount >= 3 ? 1.0 : 0.5)
            .disabled(filledCount < 3)
        }
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        GratitudeChallenge(onComplete: {}, onCancel: {})
    }
}
