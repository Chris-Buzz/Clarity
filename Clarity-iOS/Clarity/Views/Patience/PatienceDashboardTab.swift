import SwiftUI
import SwiftData

/// The Patience tab — assembles fog journal, challenges, dopamine program, and The Blank.
struct PatienceDashboardTab: View {

    @Query private var programs: [DopamineProgram]
    @Query(sort: \FocusSession.startTime, order: .reverse) private var sessions: [FocusSession]

    @State private var showTheBlank = false
    @State private var showDopamineProgram = false

    private var program: DopamineProgram? { programs.first }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: ClaritySpacing.lg) {

                // Custom header
                Text("PATIENCE")
                    .font(ClarityFonts.mono(size: 9))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.6))

                // Dopamine program summary card
                programSummaryCard

                // Daily challenge
                DailyPatienceChallenge()

                // Fog journal (compact mode)
                FogJournalView(compact: true)

                // The Blank button
                theBlankCard

                // Weekly trend sparkline
                WeeklyTrendSparkline(sessions: recentSessions)
            }
            .padding(.horizontal, ClaritySpacing.lg)
            .padding(.top, ClaritySpacing.md)
            .padding(.bottom, ClaritySpacing.xxxl)
        }
        .background(ClarityColors.background)
        .fullScreenCover(isPresented: $showTheBlank) {
            TheBlankView()
        }
        .sheet(isPresented: $showDopamineProgram) {
            DopamineProgramView()
        }
    }

    // MARK: - Program Summary Card

    private var programSummaryCard: some View {
        Button {
            HapticManager.light()
            showDopamineProgram = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: ClaritySpacing.xs) {
                    Text("30-DAY REWIRING")
                        .font(ClarityFonts.mono(size: 9))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.6))

                    if let program {
                        Text("Day \(program.currentDay) of 30")
                            .font(ClarityFonts.serif(size: 22))
                            .foregroundStyle(.white)

                        Text(program.currentPhase.capitalized)
                            .font(ClarityFonts.sans(size: 13))
                            .foregroundStyle(ClarityColors.primary)
                    } else {
                        Text("Not started")
                            .font(ClarityFonts.serif(size: 22))
                            .foregroundStyle(.white)

                        Text("Tap to begin your rewiring journey")
                            .font(ClarityFonts.sans(size: 13))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()

                // Mini progress ring
                if let program {
                    ZStack {
                        Circle()
                            .stroke(ClarityColors.borderSubtle, lineWidth: 3)
                            .frame(width: 44, height: 44)

                        Circle()
                            .trim(from: 0, to: CGFloat(program.currentDay) / 30.0)
                            .stroke(ClarityColors.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))

                        Text("\(program.currentDay)")
                            .font(ClarityFonts.mono(size: 12))
                            .foregroundStyle(.white)
                    }
                } else {
                    Image(systemName: "arrow.right.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(ClarityColors.primary)
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
        .buttonStyle(.plain)
    }

    // MARK: - The Blank Card

    private var theBlankCard: some View {
        Button {
            HapticManager.light()
            showTheBlank = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: ClaritySpacing.xs) {
                    Text("Sit with nothing")
                        .font(ClarityFonts.sansMedium(size: 16))
                        .foregroundStyle(.white)

                    Text("The most intentional thing you can do")
                        .font(ClarityFonts.sans(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Circle()
                    .fill(ClarityColors.teal.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(ClarityColors.teal, lineWidth: 1.5)
                    )
            }
            .padding(ClaritySpacing.lg)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: ClarityRadius.xl)
                    .stroke(ClarityColors.teal.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data

    private var recentSessions: [FocusSession] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { $0.startTime >= weekAgo }
    }
}

#Preview {
    PatienceDashboardTab()
        .modelContainer(for: [
            DopamineProgram.self,
            PatienceChallenge.self,
            FogEntry.self,
            FocusSession.self,
        ], inMemory: true)
}
