import SwiftUI
import SwiftData

/// Sheet for configuring and starting a focus session.
/// Captures task description and duration, then kicks off the timer.
struct QuickStartButton: View {

    @Environment(AppState.self) private var appState
    @Environment(SessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var task: String = ""
    @State private var selectedDuration: Int = 25

    private let durations = [10, 25, 45, 60, 90]

    var body: some View {
        VStack(spacing: ClaritySpacing.lg) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2)
                .fill(ClarityColors.borderSubtle)
                .frame(width: 36, height: 4)
                .padding(.top, ClaritySpacing.md)

            // MARK: - Task Input

            VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
                Text("What will you focus on?")
                    .font(ClarityFonts.sansMedium(size: 18))
                    .foregroundStyle(ClarityColors.textPrimary)

                TextField("", text: $task, prompt: Text("e.g. Deep work, reading, journaling")
                    .foregroundStyle(ClarityColors.textMuted))
                    .font(ClarityFonts.sans(size: 16))
                    .foregroundStyle(ClarityColors.textPrimary)
                    .padding(ClaritySpacing.md)
                    .background(ClarityColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: ClarityRadius.lg)
                            .stroke(ClarityColors.border, lineWidth: 1)
                    )
                    .autocorrectionDisabled()
            }

            // MARK: - Duration Pills

            VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
                Text("DURATION")
                    .font(ClarityFonts.mono(size: 10))
                    .tracking(3)
                    .foregroundStyle(ClarityColors.textMuted)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ClaritySpacing.sm) {
                        ForEach(durations, id: \.self) { minutes in
                            durationPill(minutes)
                        }
                    }
                }
            }

            Spacer()

            // MARK: - Begin Button

            ClarityButton("Begin Session", variant: .primary, size: .lg, fullWidth: true) {
                beginSession()
            }
            .opacity(task.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1.0)
            .disabled(task.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.bottom, ClaritySpacing.lg)
        }
        .padding(.horizontal, ClaritySpacing.lg)
        .background(ClarityColors.background)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(ClarityColors.background)
    }

    // MARK: - Duration Pill

    private func durationPill(_ minutes: Int) -> some View {
        let isSelected = selectedDuration == minutes

        return Button {
            HapticManager.light()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                selectedDuration = minutes
            }
        } label: {
            Text("\(minutes)m")
                .font(ClarityFonts.sansSemiBold(size: 14))
                .foregroundStyle(isSelected ? .white : ClarityColors.textSecondary)
                .padding(.horizontal, ClaritySpacing.md)
                .padding(.vertical, ClaritySpacing.sm)
                .background(isSelected ? ClarityColors.primary : ClarityColors.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : ClarityColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func beginSession() {
        let trimmed = task.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        HapticManager.medium()
        sessionManager.startSession(task: trimmed, duration: selectedDuration, context: modelContext)
        dismiss()

        // Small delay so the sheet dismisses before the full-screen cover appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.isShowingFocusTimer = true
        }
    }
}

#Preview {
    QuickStartButton()
        .environment(AppState())
        .environment(SessionManager())
        .modelContainer(for: FocusSession.self, inMemory: true)
}
