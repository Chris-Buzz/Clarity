import SwiftUI
import SwiftData

/// Full-screen active focus session with candle visual, timer, and urge resistance.
struct FocusTimerView: View {

    @Environment(AppState.self) private var appState
    @Environment(SessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showBreathing = false
    @State private var urgeFlash = false

    var body: some View {
        ZStack {
            // Background
            ClarityColors.background.ignoresSafeArea()
            AnimatedBackground()

            // Urge resist green flash
            if urgeFlash {
                ClarityColors.success.opacity(0.15)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            VStack(spacing: ClaritySpacing.lg) {
                // MARK: - Top Bar

                HStack {
                    // Back / exit button — triggers friction
                    Button {
                        HapticManager.warning()
                        showBreathing = true
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(ClarityColors.textSecondary)
                            .frame(width: 40, height: 40)
                            .background(ClarityColors.surface)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(ClarityColors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, ClaritySpacing.lg)
                .padding(.top, ClaritySpacing.sm)

                // MARK: - Task Label

                if let task = sessionManager.currentSession?.task {
                    Text(task.uppercased())
                        .font(ClarityFonts.mono(size: 10))
                        .tracking(4)
                        .foregroundStyle(ClarityColors.textMuted)
                }

                Spacer()

                // MARK: - Candle Visual

                CandleVisual(
                    progress: candleProgress,
                    isPaused: sessionManager.isPaused
                )
                .frame(height: 220)

                // MARK: - Timer

                Text(formattedTime)
                    .font(ClarityFonts.serif(size: 64))
                    .foregroundStyle(ClarityColors.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Spacer()

                // MARK: - Controls

                VStack(spacing: ClaritySpacing.md) {
                    // Pause / Resume
                    Button {
                        HapticManager.medium()
                        if sessionManager.isPaused {
                            sessionManager.resumeSession()
                        } else {
                            sessionManager.pauseSession()
                        }
                    } label: {
                        Image(systemName: sessionManager.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(ClarityColors.textPrimary)
                            .frame(width: 56, height: 56)
                            .background(ClarityColors.surface)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(ClarityColors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(ScalePress())

                    // Resist Urge
                    ClarityButton("Resist Urge", variant: .ghost, size: .sm) {
                        resistUrge()
                    }
                }
                .padding(.bottom, ClaritySpacing.xxl)
            }
        }
        .overlay {
            if showBreathing {
                BreathingOverlay {
                    // After breathing, actually end the session
                    showBreathing = false
                    endSession(completed: false)
                }
            }
        }
        // Auto-complete when timer hits zero
        .onChange(of: sessionManager.status) { _, newStatus in
            if newStatus == .completed {
                endSession(completed: true)
            }
        }
    }

    // MARK: - Helpers

    private var formattedTime: String {
        let total = Int(sessionManager.timeRemaining)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var candleProgress: Double {
        guard let session = sessionManager.currentSession else { return 1.0 }
        let total = Double(session.plannedDuration * 60)
        guard total > 0 else { return 1.0 }
        return sessionManager.timeRemaining / total
    }

    private func resistUrge() {
        sessionManager.currentSession?.urgesResisted += 1
        HapticManager.success()

        // Brief green flash
        withAnimation(.easeOut(duration: 0.15)) {
            urgeFlash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                urgeFlash = false
            }
        }
    }

    private func endSession(completed: Bool) {
        sessionManager.endSession(completed: completed, context: modelContext)
        dismiss()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.isShowingFocusTimer = false
            appState.isShowingReflection = true
        }
    }
}

/// Minimal press-scale style for icon buttons.
private struct ScalePress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    FocusTimerView()
        .environment(AppState())
        .environment(SessionManager())
        .modelContainer(for: FocusSession.self, inMemory: true)
}
