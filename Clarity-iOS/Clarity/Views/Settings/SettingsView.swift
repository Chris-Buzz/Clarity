import SwiftUI
import SwiftData
import FamilyControls

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var programs: [DopamineProgram]

    @State private var progressiveFrictionEnabled = false
    @State private var dailyBudgetEnabled = false
    @State private var focusSessionBlockingEnabled = false
    @State private var focusRemindersEnabled = true
    @State private var dailyChallengesEnabled = true
    @State private var fogReminderEnabled = false
    @State private var fogReminderTime = Date()
    @State private var nightModeEnabled = false
    @State private var selectedTheme: String = "vibrant"
    @State private var resetConfirming = false
    @State private var showPaywall = false
    @State private var countdownBaseDelay: Int = 5

    // HealthKit placeholder
    @State private var healthAuthorized = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: ClaritySpacing.lg) {

                // MARK: - Title
                Text("Settings")
                    .font(ClarityFonts.serif(size: 36))
                    .foregroundStyle(ClarityColors.textPrimary)

                // MARK: - The Cure
                settingsSection("THE CURE", color: ClarityColors.danger) {
                    ToggleRow(
                        title: "Progressive Friction",
                        description: "Escalating patience challenges as screen time increases",
                        isOn: $progressiveFrictionEnabled
                    )

                    if progressiveFrictionEnabled {
                        FrictionConfigView(profile: profile)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                // MARK: - Patience Training
                settingsSection("PATIENCE TRAINING") {
                    // Countdown base delay
                    VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
                        HStack {
                            Text("Countdown Base Delay")
                                .font(ClarityFonts.sansSemiBold(size: 15))
                                .foregroundStyle(ClarityColors.textPrimary)
                            Spacer()
                            Text("\(countdownBaseDelay)s")
                                .font(ClarityFonts.mono(size: 14))
                                .foregroundStyle(ClarityColors.primary)
                        }

                        Stepper("", value: $countdownBaseDelay, in: 5...20, step: 5)
                            .labelsHidden()
                            .onChange(of: countdownBaseDelay) { _, newValue in
                                HapticManager.light()
                                profile?.countdownEscalationBase = newValue
                            }

                        // Escalation preview
                        Text("Escalation: \(countdownBaseDelay)s \u{2192} \(countdownBaseDelay * 2)s \u{2192} \(countdownBaseDelay * 4)s \u{2192} ...")
                            .font(ClarityFonts.mono(size: 11))
                            .foregroundStyle(.white.opacity(0.4))

                        Text("Breathing gate: 6 seconds (2-2-2 cycle)")
                            .font(ClarityFonts.sans(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(ClaritySpacing.md)
                    .background(ClarityColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: ClarityRadius.md)
                            .stroke(ClarityColors.borderSubtle, lineWidth: 1)
                    )
                }

                // MARK: - Daily Budget
                settingsSection("DAILY BUDGET") {
                    ToggleRow(
                        title: "Daily Budget",
                        description: "Hard lock after reaching your daily screen time limit",
                        isOn: $dailyBudgetEnabled
                    )

                    if dailyBudgetEnabled {
                        BudgetConfigView(profile: profile)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                // MARK: - Focus Blocking
                settingsSection("FOCUS BLOCKING") {
                    ToggleRow(
                        title: "Block Apps During Focus",
                        description: "Shielded apps are hard-blocked during focus sessions",
                        isOn: $focusSessionBlockingEnabled
                    )

                    if focusSessionBlockingEnabled {
                        Text("When you start a focus session, your shielded apps will be blocked until the session ends. No bypass button.")
                            .font(ClarityFonts.sans(size: 13))
                            .foregroundStyle(ClarityColors.textMuted)
                    }
                }

                // MARK: - Daily Challenges
                settingsSection("DAILY CHALLENGES") {
                    ToggleRow(
                        title: "Patience Challenges",
                        description: "Receive a daily patience challenge to complete",
                        isOn: $dailyChallengesEnabled
                    )
                }

                // MARK: - Fog Journal
                settingsSection("FOG JOURNAL") {
                    ToggleRow(
                        title: "Clarity Reminders",
                        description: "Get reminded to log your mental clarity",
                        isOn: $fogReminderEnabled
                    )

                    if fogReminderEnabled {
                        DatePicker("Reminder Time", selection: $fogReminderTime, displayedComponents: .hourAndMinute)
                            .font(ClarityFonts.sans(size: 15))
                            .foregroundStyle(ClarityColors.textPrimary)
                            .tint(ClarityColors.primary)
                            .padding(ClaritySpacing.md)
                            .background(ClarityColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                    }
                }

                // MARK: - Dopamine Program
                settingsSection("DOPAMINE PROGRAM") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("30-Day Rewiring")
                                .font(ClarityFonts.sansMedium(size: 15))
                                .foregroundStyle(ClarityColors.textPrimary)
                            if let program = programs.first {
                                Text("Day \(program.currentDay)/30 - \(program.currentPhase.capitalized)")
                                    .font(ClarityFonts.sans(size: 12))
                                    .foregroundStyle(ClarityColors.primary)
                            } else {
                                Text("Not started")
                                    .font(ClarityFonts.sans(size: 12))
                                    .foregroundStyle(ClarityColors.textMuted)
                            }
                        }

                        Spacer()

                        ClarityButton(programs.first != nil ? "Restart" : "Start", variant: .ghost, size: .sm) {
                            HapticManager.medium()
                            // Delete existing and create new
                            for p in programs { modelContext.delete(p) }
                            modelContext.insert(DopamineProgram())
                        }
                    }
                    .padding(ClaritySpacing.md)
                    .background(ClarityColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: ClarityRadius.md)
                            .stroke(ClarityColors.borderSubtle, lineWidth: 1)
                    )
                }

                // MARK: - Your Shields
                settingsSection("YOUR SHIELDS") {
                    ShieldedAppsList(profile: profile)
                }

                // MARK: - Subscription
                settingsSection("SUBSCRIPTION") {
                    SubscriptionBadge()
                }

                // MARK: - Health
                settingsSection("HEALTH") {
                    Button {
                        HapticManager.light()
                        healthAuthorized = true
                    } label: {
                        HStack {
                            Text("HealthKit Connection")
                                .font(ClarityFonts.sans(size: 15))
                                .foregroundStyle(ClarityColors.textPrimary)

                            Spacer()

                            if healthAuthorized {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(ClarityColors.success)
                            } else {
                                Image(systemName: "arrow.right.circle")
                                    .foregroundStyle(ClarityColors.primary)
                            }
                        }
                        .padding(ClaritySpacing.md)
                        .background(ClarityColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: ClarityRadius.md)
                                .stroke(ClarityColors.borderSubtle, lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScalePress())
                }

                // MARK: - Notifications
                settingsSection("NOTIFICATIONS") {
                    ToggleRow(
                        title: "Focus Reminders",
                        description: "Get gentle reminders to start focus sessions",
                        isOn: $focusRemindersEnabled
                    )
                }

                // MARK: - Appearance
                settingsSection("APPEARANCE") {
                    HStack(spacing: ClaritySpacing.sm) {
                        ThemeButton(label: "Vibrant", isActive: selectedTheme == "vibrant") {
                            HapticManager.light()
                            selectedTheme = "vibrant"
                            profile?.theme = "vibrant"
                        }
                        ThemeButton(label: "Eerie", isActive: selectedTheme == "eerie") {
                            HapticManager.light()
                            selectedTheme = "eerie"
                            profile?.theme = "eerie"
                        }
                    }
                }

                // MARK: - Data
                settingsSection("DATA") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Cleanup")
                                .font(ClarityFonts.sansMedium(size: 15))
                                .foregroundStyle(ClarityColors.textPrimary)
                            Text("Sessions older than 30 days are automatically cleaned up. Snapshots kept for 90 days.")
                                .font(ClarityFonts.sans(size: 12))
                                .foregroundStyle(ClarityColors.textMuted)
                        }
                        Spacer()
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(ClarityColors.textMuted)
                    }
                    .padding(ClaritySpacing.md)
                    .background(ClarityColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                }

                // MARK: - Reset
                VStack(spacing: ClaritySpacing.sm) {
                    Button {
                        HapticManager.warning()
                        if resetConfirming {
                            performReset()
                        } else {
                            resetConfirming = true
                        }
                    } label: {
                        Text(resetConfirming ? "Tap again to confirm" : "Reset All Data")
                            .font(ClarityFonts.sans(size: 15))
                            .foregroundStyle(resetConfirming ? ClarityColors.danger : ClarityColors.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ClaritySpacing.md)
                            .background(Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: ClarityRadius.md)
                                    .stroke(
                                        resetConfirming ? ClarityColors.danger : ClarityColors.border,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(ScalePress())

                    if resetConfirming {
                        Button {
                            HapticManager.light()
                            resetConfirming = false
                        } label: {
                            Text("Cancel")
                                .font(ClarityFonts.sans(size: 14))
                                .foregroundStyle(ClarityColors.textMuted)
                        }
                    }
                }
                .padding(.top, ClaritySpacing.md)
            }
            .padding(.horizontal, ClaritySpacing.md)
            .padding(.top, ClaritySpacing.lg)
            .padding(.bottom, ClaritySpacing.xxxl)
        }
        .background(ClarityColors.background)
        .onAppear {
            if let profile {
                selectedTheme = profile.theme
                focusRemindersEnabled = profile.nudgesEnabled
                progressiveFrictionEnabled = profile.frictionThresholds != [5, 15, 30, 45, 60]
                countdownBaseDelay = profile.countdownEscalationBase
            }
            dailyBudgetEnabled = profile?.dailyBudgetEnabled ?? false
            focusSessionBlockingEnabled = profile?.focusSessionBlockingEnabled ?? false
        }
        .onChange(of: dailyBudgetEnabled) { _, newValue in
            profile?.dailyBudgetEnabled = newValue
            if newValue {
                if let profile,
                   let data = profile.budgetAppsData,
                   let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                    DailyBudgetService.shared.startBudgetMonitoring(
                        budgetMinutes: profile.dailyBudgetMinutes,
                        apps: selection
                    )
                }
            } else {
                DailyBudgetService.shared.stopBudgetMonitoring()
            }
        }
        .onChange(of: focusSessionBlockingEnabled) { _, newValue in
            profile?.focusSessionBlockingEnabled = newValue
        }
        .animation(.easeInOut(duration: 0.25), value: progressiveFrictionEnabled)
        .animation(.easeInOut(duration: 0.25), value: dailyBudgetEnabled)
        .animation(.easeInOut(duration: 0.25), value: focusSessionBlockingEnabled)
        .animation(.easeInOut(duration: 0.25), value: fogReminderEnabled)
        .animation(.easeInOut(duration: 0.2), value: resetConfirming)
    }

    // MARK: - Section Builder

    @ViewBuilder
    private func settingsSection(
        _ title: String,
        color: Color = ClarityColors.textMuted,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.md) {
            SectionHeader(title: title, color: color)
            content()
        }
    }

    // MARK: - Actions

    private func performReset() {
        HapticManager.error()
        try? modelContext.delete(model: FocusSession.self)
        try? modelContext.delete(model: MoodEntry.self)
        try? modelContext.delete(model: UserProfile.self)
        try? modelContext.delete(model: FogEntry.self)
        try? modelContext.delete(model: PatienceChallenge.self)
        try? modelContext.delete(model: DopamineProgram.self)
        resetConfirming = false
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var color: Color = ClarityColors.textMuted

    var body: some View {
        Text(title)
            .font(ClarityFonts.mono(size: 11))
            .tracking(3)
            .foregroundStyle(color)
            .textCase(.uppercase)
            .padding(.bottom, ClaritySpacing.xs)
    }
}

// MARK: - Toggle Row

struct ToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            HapticManager.light()
            isOn.toggle()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ClarityFonts.sansSemiBold(size: 15))
                        .foregroundStyle(ClarityColors.textPrimary)
                    Text(description)
                        .font(ClarityFonts.sans(size: 12))
                        .foregroundStyle(ClarityColors.textMuted)
                }

                Spacer()

                // Custom toggle
                ClarityToggle(isOn: isOn)
            }
            .padding(ClaritySpacing.md)
            .background(isOn ? ClarityColors.primaryMuted : ClarityColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: ClarityRadius.md)
                    .stroke(isOn ? ClarityColors.primary.opacity(0.3) : ClarityColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(ScalePress())
    }
}

// MARK: - Custom Toggle

struct ClarityToggle: View {
    let isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: 15)
                .fill(isOn ? ClarityColors.primary : ClarityColors.borderAccent)
                .frame(width: 52, height: 30)

            Circle()
                .fill(Color.white)
                .frame(width: 24, height: 24)
                .padding(3)
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isOn)
    }
}

// MARK: - Theme Button

private struct ThemeButton: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(ClarityFonts.sansSemiBold(size: 14))
                .foregroundStyle(isActive ? ClarityColors.textPrimary : ClarityColors.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ClaritySpacing.sm + 4)
                .background(isActive ? ClarityColors.primaryMuted : ClarityColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: ClarityRadius.md)
                        .stroke(isActive ? ClarityColors.primary : ClarityColors.borderSubtle, lineWidth: 1)
                )
        }
        .buttonStyle(ScalePress())
    }
}

// MARK: - Shielded Apps List (Placeholder)

private struct ShieldedAppsList: View {
    let profile: UserProfile?

    private let apps = [
        "Instagram", "TikTok", "Twitter / X", "YouTube",
        "Snapchat", "Reddit", "Facebook",
    ]

    @State private var selected: Set<String> = ["Instagram", "TikTok", "Twitter / X"]

    var body: some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
            ForEach(apps, id: \.self) { app in
                Button {
                    HapticManager.light()
                    if selected.contains(app) {
                        selected.remove(app)
                    } else {
                        selected.insert(app)
                    }
                } label: {
                    HStack {
                        Text(app)
                            .font(ClarityFonts.sans(size: 15))
                            .foregroundStyle(ClarityColors.textPrimary)

                        Spacer()

                        ZStack {
                            Circle()
                                .fill(selected.contains(app) ? ClarityColors.primary : Color.clear)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selected.contains(app) ? ClarityColors.primary : ClarityColors.border,
                                            lineWidth: 2
                                        )
                                )

                            if selected.contains(app) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(.horizontal, ClaritySpacing.md)
                    .padding(.vertical, ClaritySpacing.sm)
                }
                .buttonStyle(ScalePress())
            }

            Text("Selected apps will have patience friction applied")
                .font(ClarityFonts.sans(size: 12))
                .foregroundStyle(ClarityColors.textMuted)
                .padding(.top, ClaritySpacing.xs)
        }
    }
}

// MARK: - Scale Press Style

private struct ScalePress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [
            UserProfile.self,
            FocusSession.self,
            MoodEntry.self,
            DopamineProgram.self,
            FogEntry.self,
            PatienceChallenge.self,
        ], inMemory: true)
}
