import SwiftUI
import SwiftData

/// 30-day dopamine rewiring program view.
/// Four phases: Awareness (1-7) -> Delay (8-14) -> Substitute (15-21) -> Integrate (22-30).
struct DopamineProgramView: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var programs: [DopamineProgram]

    @State private var impulsesCaught: Int = 0
    @State private var delaysPracticed: Int = 0
    @State private var dailyNotes: String = ""
    @State private var showLogSaved = false

    private var program: DopamineProgram? { programs.first }

    private let phases: [(name: String, range: ClosedRange<Int>, description: String)] = [
        ("Awareness", 1...7, "Notice your impulses. Do not fight them yet."),
        ("Delay", 8...14, "Start inserting pauses. 10 seconds, then 30, then 60."),
        ("Substitute", 15...21, "Replace the impulse with something analog."),
        ("Integrate", 22...30, "Your new patterns become automatic."),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: ClaritySpacing.lg) {
                // Header
                Text("30-DAY REWIRING")
                    .font(ClarityFonts.mono(size: 9))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.6))

                if let program {
                    programContent(program)
                } else {
                    startCard
                }
            }
            .padding(.horizontal, ClaritySpacing.lg)
            .padding(.top, ClaritySpacing.md)
            .padding(.bottom, ClaritySpacing.xxxl)
        }
        .background(ClarityColors.background)
    }

    // MARK: - Start Card

    private var startCard: some View {
        VStack(spacing: ClaritySpacing.lg) {
            Text("Rewire Your Dopamine System")
                .font(ClarityFonts.serif(size: 26))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("A 30-day structured program to rebuild your brain's relationship with instant gratification.")
                .font(ClarityFonts.sans(size: 15))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            ForEach(phases, id: \.name) { phase in
                HStack(spacing: ClaritySpacing.md) {
                    Circle()
                        .fill(ClarityColors.primary.opacity(0.3))
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(phase.name)
                            .font(ClarityFonts.sansSemiBold(size: 14))
                            .foregroundStyle(.white.opacity(0.8))
                        Text(phase.description)
                            .font(ClarityFonts.sans(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }

            ClarityButton("Start Program", variant: .primary, size: .lg, fullWidth: true) {
                startProgram()
            }
        }
        .padding(ClaritySpacing.xl)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xxl))
    }

    // MARK: - Program Content

    @ViewBuilder
    private func programContent(_ program: DopamineProgram) -> some View {
        // Phase indicator
        phaseIndicator(program)

        // Current phase description
        if let currentPhaseInfo = phases.first(where: { $0.range.contains(program.currentDay) }) {
            VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
                Text("Week \(phaseWeek(program.currentDay)): \(currentPhaseInfo.name)")
                    .font(ClarityFonts.serif(size: 22))
                    .foregroundStyle(.white)

                Text(currentPhaseInfo.description)
                    .font(ClarityFonts.sans(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineSpacing(4)
            }
        }

        // Progress grid
        progressGrid(program)

        // Daily log form
        dailyLogForm(program)
    }

    // MARK: - Phase Indicator

    private func phaseIndicator(_ program: DopamineProgram) -> some View {
        HStack(spacing: ClaritySpacing.xs) {
            ForEach(phases, id: \.name) { phase in
                let isCurrent = phase.range.contains(program.currentDay)
                let isPast = program.currentDay > phase.range.upperBound

                VStack(spacing: ClaritySpacing.xs) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isPast ? ClarityColors.teal : (isCurrent ? ClarityColors.primary : ClarityColors.borderSubtle))
                        .frame(height: 3)

                    Text(phase.name)
                        .font(ClarityFonts.mono(size: 8))
                        .tracking(1)
                        .foregroundStyle(isCurrent ? ClarityColors.primary : .white.opacity(isPast ? 0.5 : 0.25))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Progress Grid (6 x 5 = 30 days)

    private func progressGrid(_ program: DopamineProgram) -> some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
            Text("PROGRESS")
                .font(ClarityFonts.mono(size: 9))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.6))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: ClaritySpacing.sm), count: 6), spacing: ClaritySpacing.sm) {
                ForEach(1...30, id: \.self) { day in
                    let isCompleted = day < program.currentDay
                    let isCurrent = day == program.currentDay

                    Circle()
                        .fill(isCompleted ? ClarityColors.primary : (isCurrent ? ClarityColors.primary.opacity(0.5) : ClarityColors.surface))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(
                                    isCurrent ? ClarityColors.primary : ClarityColors.borderSubtle,
                                    lineWidth: isCurrent ? 2 : 1
                                )
                        )
                        .overlay(
                            Text("\(day)")
                                .font(ClarityFonts.mono(size: 11))
                                .foregroundStyle(isCompleted || isCurrent ? .white : .white.opacity(0.25))
                        )
                        .scaleEffect(isCurrent ? 1.1 : 1.0)
                        .animation(
                            isCurrent ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true) : .default,
                            value: isCurrent
                        )
                }
            }
        }
        .padding(ClaritySpacing.md)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
    }

    // MARK: - Daily Log Form

    private func dailyLogForm(_ program: DopamineProgram) -> some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.md) {
            Text("DAY \(program.currentDay) LOG")
                .font(ClarityFonts.mono(size: 9))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.6))

            // Impulses caught
            HStack {
                Text("Impulses caught")
                    .font(ClarityFonts.sans(size: 15))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Stepper("\(impulsesCaught)", value: $impulsesCaught, in: 0...99)
                    .labelsHidden()
                    .onChange(of: impulsesCaught) { _, _ in HapticManager.light() }
                Text("\(impulsesCaught)")
                    .font(ClarityFonts.sansSemiBold(size: 16))
                    .foregroundStyle(ClarityColors.primary)
                    .frame(width: 30)
            }

            // Delays practiced
            HStack {
                Text("Delays practiced")
                    .font(ClarityFonts.sans(size: 15))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Stepper("\(delaysPracticed)", value: $delaysPracticed, in: 0...99)
                    .labelsHidden()
                    .onChange(of: delaysPracticed) { _, _ in HapticManager.light() }
                Text("\(delaysPracticed)")
                    .font(ClarityFonts.sansSemiBold(size: 16))
                    .foregroundStyle(ClarityColors.teal)
                    .frame(width: 30)
            }

            // Notes
            TextField("Notes (optional)", text: $dailyNotes)
                .font(ClarityFonts.sans(size: 15))
                .foregroundStyle(.white)
                .padding(ClaritySpacing.md)
                .background(ClarityColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: ClarityRadius.md)
                        .stroke(ClarityColors.borderSubtle, lineWidth: 1)
                )

            ClarityButton(showLogSaved ? "Logged" : "Log Today", variant: .primary, fullWidth: true) {
                logToday(program)
            }
            .disabled(showLogSaved)
        }
        .padding(ClaritySpacing.lg)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
    }

    // MARK: - Actions

    private func startProgram() {
        HapticManager.success()
        let newProgram = DopamineProgram()
        modelContext.insert(newProgram)
    }

    private func logToday(_ program: DopamineProgram) {
        HapticManager.success()
        let log = DayLog(
            date: Date(),
            impulsesCaught: impulsesCaught,
            delaysPracticed: delaysPracticed,
            notes: dailyNotes.isEmpty ? nil : dailyNotes
        )
        var logs = program.dailyLogs
        logs.append(log)
        program.dailyLogs = logs

        // Advance day
        if program.currentDay < 30 {
            program.currentDay += 1
            program.phase = program.currentPhase
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showLogSaved = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showLogSaved = false
                impulsesCaught = 0
                delaysPracticed = 0
                dailyNotes = ""
            }
        }
    }

    private func phaseWeek(_ day: Int) -> Int {
        switch day {
        case 1...7: return 1
        case 8...14: return 2
        case 15...21: return 3
        case 22...30: return 4
        default: return 4
        }
    }
}

#Preview {
    DopamineProgramView()
        .modelContainer(for: [DopamineProgram.self], inMemory: true)
}
