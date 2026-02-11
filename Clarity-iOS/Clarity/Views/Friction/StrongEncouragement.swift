import SwiftUI

/// Layer 5 friction (60 min). Maximum friction: requires the user to type an
/// exact confirmation phrase before they can proceed. Designed to make
/// the conscious choice unmistakable.
struct StrongEncouragement: View {

    let onComplete: () -> Void
    let onCancel: () -> Void

    /// Today's usage in minutes for this app (injected from parent).
    var todayMinutes: Int = 62
    /// Weekly average in minutes.
    var weeklyAverage: Int = 45

    private let requiredPhrase = "I choose to continue"

    @State private var typedText: String = ""
    @FocusState private var isFocused: Bool

    private var phraseMatches: Bool {
        typedText.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() == requiredPhrase.lowercased()
    }

    var body: some View {
        VStack(spacing: ClaritySpacing.lg) {
            // Header
            Text("ARE YOU SURE?")
                .font(ClarityFonts.mono(size: 10))
                .tracking(3)
                .foregroundStyle(ClarityColors.danger)

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(ClarityColors.danger)

            Text("You've spent over an hour here today")
                .font(ClarityFonts.serif(size: 24, weight: .bold))
                .foregroundStyle(ClarityColors.textPrimary)
                .multilineTextAlignment(.center)

            // Stats card
            statsCard

            // Typed confirmation
            VStack(spacing: ClaritySpacing.sm) {
                Text("Type '\(requiredPhrase)' to proceed")
                    .font(ClarityFonts.sans(size: 14))
                    .foregroundStyle(ClarityColors.textSecondary)

                // Character-by-character colored text display
                characterMatchView
                    .padding(.bottom, ClaritySpacing.xs)

                TextField("", text: $typedText)
                    .font(ClarityFonts.mono(size: 16))
                    .foregroundStyle(ClarityColors.textPrimary)
                    .padding(ClaritySpacing.sm)
                    .background(ClarityColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: ClarityRadius.md)
                            .stroke(ClarityColors.primary, lineWidth: 1)
                    )
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            // Continue (disabled until phrase matches)
            ClarityButton("Continue", variant: .primary, fullWidth: true) {
                onComplete()
            }
            .opacity(phraseMatches ? 1.0 : 0.5)
            .disabled(!phraseMatches)

            // Encouraged cancel option
            Button {
                HapticManager.light()
                onCancel()
            } label: {
                Text("I'll do something else")
                    .font(ClarityFonts.sansMedium(size: 15))
                    .foregroundStyle(ClarityColors.success)
            }
        }
        .onAppear {
            HapticManager.warning()
        }
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(spacing: ClaritySpacing.sm) {
            HStack {
                Text("Today")
                    .font(ClarityFonts.sans(size: 14))
                    .foregroundStyle(ClarityColors.textSecondary)
                Spacer()
                Text("\(todayMinutes) minutes")
                    .font(ClarityFonts.sansSemiBold(size: 14))
                    .foregroundStyle(ClarityColors.danger)
            }

            // Simple bar visualization
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ClarityColors.dangerMuted)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(ClarityColors.danger)
                        .frame(width: min(geo.size.width, geo.size.width * CGFloat(todayMinutes) / 120.0), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("Weekly average")
                    .font(ClarityFonts.sans(size: 13))
                    .foregroundStyle(ClarityColors.textTertiary)
                Spacer()
                Text("\(weeklyAverage) minutes")
                    .font(ClarityFonts.sans(size: 13))
                    .foregroundStyle(ClarityColors.textTertiary)
            }
        }
        .padding(ClaritySpacing.md)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: ClarityRadius.lg)
                .stroke(ClarityColors.border, lineWidth: 1)
        )
    }

    // MARK: - Character Match View

    /// Shows each typed character colored green (correct) or red (wrong)
    /// relative to the required phrase.
    private var characterMatchView: some View {
        let target = Array(requiredPhrase.lowercased())
        let typed = Array(typedText.lowercased())

        return HStack(spacing: 0) {
            ForEach(0..<typed.count, id: \.self) { i in
                let char = String(typedText[typedText.index(typedText.startIndex, offsetBy: i)])
                let isCorrect = i < target.count && typed[i] == target[i]

                Text(char)
                    .font(ClarityFonts.mono(size: 16))
                    .foregroundStyle(isCorrect ? ClarityColors.success : ClarityColors.danger)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 20)
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        StrongEncouragement(onComplete: {}, onCancel: {})
            .padding()
    }
}
