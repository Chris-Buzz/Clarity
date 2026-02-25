import SwiftUI
import SwiftData

/// Daily patience challenge card. Shows one challenge per day from a curated bank.
/// User can accept, complete, or skip challenges to build their patience score.
struct DailyPatienceChallenge: View {

    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<PatienceChallenge> { !$0.wasCompleted },
        sort: \PatienceChallenge.date,
        order: .reverse
    )
    private var activeChallenges: [PatienceChallenge]

    @State private var isAccepted = false
    @State private var showCompleted = false

    // Challenge bank
    private static let challengeBank: [(text: String, type: String, minutes: Int)] = [
        // Wait
        ("Wait 5 minutes before responding to that notification", "wait", 5),
        ("Do not check your phone for the next 30 minutes", "wait", 30),
        ("Wait until tomorrow to make that purchase", "wait", 1440),
        ("Let a text sit for 10 minutes before replying", "wait", 10),
        ("Wait for the next song to finish before skipping", "wait", 4),
        // Analog
        ("Navigate somewhere without GPS", "analog", 15),
        ("Write a note by hand instead of typing", "analog", 5),
        ("Read a physical page for 10 minutes", "analog", 10),
        ("Draw something, anything, for 5 minutes", "analog", 5),
        ("Make a cup of tea without looking at a screen", "analog", 10),
        // Decision
        ("Sit with a decision for 2 hours before acting", "decision", 120),
        ("Sleep on that reply before sending it", "decision", 480),
        ("Before adding to cart, close the app and wait an hour", "decision", 60),
        ("Choose your next meal without looking at reviews", "decision", 5),
        // Attention
        ("Listen to a full song without doing anything else", "attention", 4),
        ("Watch the sky for 3 minutes", "attention", 3),
        ("Eat a meal without your phone", "attention", 20),
        ("Have a conversation without checking your phone once", "attention", 15),
        ("Sit in silence for 5 minutes", "attention", 5),
        ("Walk for 10 minutes without headphones", "attention", 10),
    ]

    private var todaysChallenge: PatienceChallenge? {
        activeChallenges.first { Calendar.current.isDateInToday($0.date) }
    }

    private let typeColors: [String: Color] = [
        "wait": ClarityColors.primary,
        "analog": ClarityColors.teal,
        "decision": Color.purple,
        "attention": Color.blue,
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.md) {
            Text("TODAY'S CHALLENGE")
                .font(ClarityFonts.mono(size: 9))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.6))

            if showCompleted {
                completedCard
            } else if let challenge = todaysChallenge {
                challengeCard(challenge)
            } else {
                generateCard
            }
        }
    }

    // MARK: - Challenge Card

    private func challengeCard(_ challenge: PatienceChallenge) -> some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.md) {
            // Type badge
            Text(challenge.challengeType.uppercased())
                .font(ClarityFonts.mono(size: 9))
                .tracking(2)
                .foregroundStyle(.white)
                .padding(.horizontal, ClaritySpacing.sm)
                .padding(.vertical, ClaritySpacing.xs)
                .background(typeColors[challenge.challengeType, default: ClarityColors.primary].opacity(0.3))
                .clipShape(Capsule())

            // Challenge text
            Text(challenge.challengeText)
                .font(ClarityFonts.sans(size: 16))
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(4)

            // Duration
            Text("~\(challenge.durationMinutes) minutes")
                .font(ClarityFonts.mono(size: 11))
                .foregroundStyle(.white.opacity(0.4))

            // Actions
            HStack(spacing: ClaritySpacing.sm) {
                if isAccepted {
                    ClarityButton("Complete", variant: .secondary, size: .md, fullWidth: true) {
                        completeChallenge(challenge)
                    }
                } else {
                    ClarityButton("Accept", variant: .primary, size: .md, fullWidth: true) {
                        HapticManager.medium()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isAccepted = true
                        }
                    }
                }

                Button {
                    HapticManager.light()
                    skipChallenge(challenge)
                } label: {
                    Text("Skip")
                        .font(ClarityFonts.sans(size: 14))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ClaritySpacing.sm + 2)
                }
            }
        }
        .padding(ClaritySpacing.lg)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: ClarityRadius.xl)
                .stroke(ClarityColors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Generate Card

    private var generateCard: some View {
        VStack(spacing: ClaritySpacing.md) {
            Text("No active challenge")
                .font(ClarityFonts.sans(size: 15))
                .foregroundStyle(.white.opacity(0.5))

            ClarityButton("Generate One", variant: .primary, size: .md, fullWidth: true) {
                generateChallenge()
            }
        }
        .padding(ClaritySpacing.lg)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: ClarityRadius.xl)
                .stroke(ClarityColors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Completed Card

    private var completedCard: some View {
        VStack(spacing: ClaritySpacing.md) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(ClarityColors.teal)

            Text("Challenge completed")
                .font(ClarityFonts.sansMedium(size: 16))
                .foregroundStyle(.white)

            Text("Your patience grew today")
                .font(ClarityFonts.sans(size: 14))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(ClaritySpacing.lg)
        .background(ClarityColors.tealMuted)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
    }

    // MARK: - Actions

    private func generateChallenge() {
        HapticManager.medium()
        guard let selected = Self.challengeBank.randomElement() else { return }
        let challenge = PatienceChallenge(
            challengeText: selected.text,
            challengeType: selected.type,
            durationMinutes: selected.minutes
        )
        modelContext.insert(challenge)
    }

    private func completeChallenge(_ challenge: PatienceChallenge) {
        HapticManager.success()
        challenge.wasCompleted = true
        challenge.completedAt = Date()
        PatienceManager.shared.todaysChallengeCompleted = true
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showCompleted = true
        }
    }

    private func skipChallenge(_ challenge: PatienceChallenge) {
        modelContext.delete(challenge)
        isAccepted = false
    }
}

#Preview {
    VStack {
        DailyPatienceChallenge()
    }
    .padding()
    .background(ClarityColors.background)
    .modelContainer(for: [PatienceChallenge.self], inMemory: true)
}
