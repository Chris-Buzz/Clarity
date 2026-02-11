import SwiftUI
import SwiftData

/// Step 2: Five slider questions to assess phone dependency level (score 5-25).
struct AssessmentStep: View {

    let onContinue: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var answers: [Double] = [3, 3, 3, 3, 3]

    private let questions = [
        "How often do you check your phone without a clear purpose?",
        "Do you feel anxious when you can't access your phone?",
        "How often do you lose track of time while scrolling?",
        "Do you use your phone to avoid uncomfortable feelings?",
        "How difficult is it to put your phone down once you start?"
    ]

    var totalScore: Int {
        answers.reduce(0) { $0 + Int($1) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ClaritySpacing.lg) {
                // Header
                VStack(spacing: ClaritySpacing.sm) {
                    Text("Quick Check-in")
                        .font(ClarityFonts.serif(size: 28, weight: .bold))
                        .foregroundStyle(ClarityColors.textPrimary)

                    Text("5 quick questions to calibrate your experience")
                        .font(ClarityFonts.sans(size: 15))
                        .foregroundStyle(ClarityColors.textTertiary)
                }
                .padding(.top, ClaritySpacing.lg)

                // Question cards
                ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                    questionCard(index: index, question: question)
                }
                .padding(.horizontal, ClaritySpacing.lg)

                // Continue
                ClarityButton(
                    "Continue",
                    variant: .primary,
                    size: .lg,
                    fullWidth: true
                ) {
                    saveAndContinue()
                }
                .padding(.horizontal, ClaritySpacing.lg)
                .padding(.bottom, ClaritySpacing.xl)
            }
        }
    }

    // MARK: - Question Card

    private func questionCard(index: Int, question: String) -> some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.md) {
            Text(question)
                .font(ClarityFonts.sans(size: 14))
                .foregroundStyle(ClarityColors.textSecondary)
                .lineSpacing(3)

            // Custom slider
            VStack(spacing: ClaritySpacing.sm) {
                GeometryReader { geo in
                    let trackWidth = geo.size.width
                    let thumbOffset = (answers[index] - 1) / 4 * trackWidth

                    ZStack(alignment: .leading) {
                        // Track background
                        Capsule()
                            .fill(ClarityColors.surface)
                            .frame(height: 6)

                        // Orange fill
                        Capsule()
                            .fill(ClarityColors.primary)
                            .frame(width: max(0, thumbOffset + 12), height: 6)

                        // Thumb
                        Circle()
                            .fill(ClarityColors.primary)
                            .frame(width: 24, height: 24)
                            .shadow(color: ClarityColors.primaryGlow, radius: 8)
                            .offset(x: thumbOffset - 12)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let ratio = min(max(value.location.x / trackWidth, 0), 1)
                                        let snapped = round(ratio * 4) + 1
                                        answers[index] = snapped
                                    }
                            )
                    }
                }
                .frame(height: 24)

                // Labels
                HStack {
                    Text("Rarely")
                        .font(ClarityFonts.mono(size: 10))
                        .foregroundStyle(ClarityColors.textMuted)
                    Spacer()
                    Text("Always")
                        .font(ClarityFonts.mono(size: 10))
                        .foregroundStyle(ClarityColors.textMuted)
                }
            }
        }
        .padding(ClaritySpacing.md)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.lg))
    }

    // MARK: - Actions

    private func saveAndContinue() {
        if let profile = profiles.first {
            profile.assessmentScore = totalScore
        }
        HapticManager.light()
        onContinue()
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        AssessmentStep {}
    }
    .modelContainer(for: UserProfile.self, inMemory: true)
}
