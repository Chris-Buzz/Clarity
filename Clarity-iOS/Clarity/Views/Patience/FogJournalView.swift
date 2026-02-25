import SwiftUI
import SwiftData

/// Fog journal for tracking mental clarity throughout the day.
/// Quick check-in with 1-5 clarity scale, trigger selection, and optional notes.
struct FogJournalView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FogEntry.timestamp, order: .reverse) private var entries: [FogEntry]

    @State private var selectedLevel: Int = 3
    @State private var selectedTrigger: String = ""
    @State private var notes: String = ""
    @State private var showSaved = false

    /// When true, shows compact mode for embedding in the Patience tab
    var compact: Bool = false

    private let triggers = ["Scrolling", "Work Stress", "Poor Sleep", "Overstimulation"]

    private let levelLabels = ["Heavy fog", "Foggy", "Neutral", "Fairly clear", "Crystal clear"]
    private let levelColors: [Color] = [
        .red.opacity(0.7),
        .orange.opacity(0.7),
        .yellow.opacity(0.6),
        ClarityColors.teal.opacity(0.7),
        ClarityColors.teal
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.lg) {
            // Header
            Text("FOG JOURNAL")
                .font(ClarityFonts.mono(size: 9))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.6))

            // Quick check-in card
            VStack(alignment: .leading, spacing: ClaritySpacing.md) {
                Text("How clear is your mind?")
                    .font(ClarityFonts.serif(size: 22))
                    .foregroundStyle(.white)

                // 5 clarity circles
                HStack(spacing: ClaritySpacing.md) {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            HapticManager.light()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedLevel = level
                            }
                        } label: {
                            Circle()
                                .fill(selectedLevel == level ? levelColors[level - 1] : ClarityColors.surface)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selectedLevel == level ? levelColors[level - 1] : ClarityColors.borderSubtle,
                                            lineWidth: selectedLevel == level ? 2 : 1
                                        )
                                )
                                .overlay(
                                    Text("\(level)")
                                        .font(ClarityFonts.sansSemiBold(size: 16))
                                        .foregroundStyle(selectedLevel == level ? .white : .white.opacity(0.4))
                                )
                                .scaleEffect(selectedLevel == level ? 1.1 : 1.0)
                        }
                    }
                }

                Text(levelLabels[max(0, min(4, selectedLevel - 1))])
                    .font(ClarityFonts.sans(size: 14))
                    .foregroundStyle(levelColors[max(0, min(4, selectedLevel - 1))])
            }
            .padding(ClaritySpacing.lg)
            .background(ClarityColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))

            // Trigger chips
            VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
                Text("What triggered it?")
                    .font(ClarityFonts.sans(size: 14))
                    .foregroundStyle(.white.opacity(0.6))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ClaritySpacing.sm) {
                        ForEach(triggers, id: \.self) { trigger in
                            Button {
                                HapticManager.light()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    selectedTrigger = selectedTrigger == trigger ? "" : trigger
                                }
                            } label: {
                                Text(trigger)
                                    .font(ClarityFonts.sans(size: 13))
                                    .foregroundStyle(selectedTrigger == trigger ? .white : .white.opacity(0.6))
                                    .padding(.horizontal, ClaritySpacing.md)
                                    .padding(.vertical, ClaritySpacing.sm)
                                    .background(selectedTrigger == trigger ? ClarityColors.tealMuted : ClarityColors.surface)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                selectedTrigger == trigger ? ClarityColors.teal : ClarityColors.borderSubtle,
                                                lineWidth: 1
                                            )
                                    )
                            }
                        }
                    }
                }
            }

            if !compact {
                // Optional notes
                TextField("Any notes? (optional)", text: $notes)
                    .font(ClarityFonts.sans(size: 15))
                    .foregroundStyle(.white)
                    .padding(ClaritySpacing.md)
                    .background(ClarityColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: ClarityRadius.md)
                            .stroke(ClarityColors.borderSubtle, lineWidth: 1)
                    )
            }

            // Save button
            ClarityButton(showSaved ? "Logged" : "Log Entry", variant: .primary, fullWidth: true) {
                saveEntry()
            }
            .disabled(showSaved)

            // History (only in full mode)
            if !compact && !entries.isEmpty {
                VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
                    Text("RECENT ENTRIES")
                        .font(ClarityFonts.mono(size: 9))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.6))

                    ForEach(entries.prefix(5)) { entry in
                        historyRow(entry)
                    }
                }
            }
        }
    }

    // MARK: - History Row

    private func historyRow(_ entry: FogEntry) -> some View {
        HStack(spacing: ClaritySpacing.md) {
            Circle()
                .fill(levelColors[max(0, min(4, entry.clarityLevel - 1))])
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.timestamp, style: .relative)
                    .font(ClarityFonts.sans(size: 13))
                    .foregroundStyle(.white.opacity(0.6))

                if entry.trigger != "unknown" {
                    Text(entry.trigger)
                        .font(ClarityFonts.mono(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            Spacer()

            Text(levelLabels[max(0, min(4, entry.clarityLevel - 1))])
                .font(ClarityFonts.sans(size: 12))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(ClaritySpacing.sm)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
    }

    // MARK: - Save

    private func saveEntry() {
        HapticManager.success()
        let entry = FogEntry(
            clarityLevel: selectedLevel,
            trigger: selectedTrigger.isEmpty ? "unknown" : selectedTrigger,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(entry)

        // Update PatienceManager fog level
        PatienceManager.shared.currentFogLevel = selectedLevel

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showSaved = true
        }

        // Reset after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSaved = false
                selectedLevel = 3
                selectedTrigger = ""
                notes = ""
            }
        }
    }
}

#Preview {
    ScrollView {
        FogJournalView()
            .padding()
    }
    .background(ClarityColors.background)
    .modelContainer(for: [FogEntry.self], inMemory: true)
}
