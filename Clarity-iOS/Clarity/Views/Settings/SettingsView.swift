import SwiftUI
import SwiftData
import FamilyControls

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(filter: #Predicate<ImplementationIntention> { $0.isActive })
    private var intentions: [ImplementationIntention]
    @Query(sort: \ImportantContact.contactName) private var importantContacts: [ImportantContact]
    @Query private var wifiConfigs: [WiFiGateConfig]

    @State private var progressiveFrictionEnabled = false
    @State private var dailyBudgetEnabled = false
    @State private var focusSessionBlockingEnabled = false
    @State private var focusRemindersEnabled = true
    @State private var nightModeEnabled = false
    @State private var wifiGateEnabled = false
    @State private var selectedTheme: String = "vibrant"
    @State private var resetConfirming = false
    @State private var showPaywall = false

    // HealthKit placeholder
    @State private var healthAuthorized = false

    private var profile: UserProfile? { profiles.first }
    private var wifiConfig: WiFiGateConfig? { wifiConfigs.first }

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
                        description: "Escalating challenges as screen time increases",
                        isOn: $progressiveFrictionEnabled
                    )

                    if progressiveFrictionEnabled {
                        FrictionConfigView(profile: profile)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                // MARK: - Daily Budget
                settingsSection("DAILY BUDGET", color: ClarityColors.danger) {
                    ToggleRow(
                        title: "Daily Screen Time Budget",
                        description: "Hard-block apps after your daily limit is reached",
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

                // MARK: - Your Shields
                settingsSection("YOUR SHIELDS") {
                    ShieldedAppsList(profile: profile)
                }

                // MARK: - Your People
                settingsSection("YOUR PEOPLE") {
                    if importantContacts.isEmpty {
                        Text("No important contacts set. Add people you'd rather connect with instead of scrolling.")
                            .font(ClarityFonts.sans(size: 14))
                            .foregroundStyle(ClarityColors.textMuted)
                    } else {
                        ForEach(importantContacts, id: \.id) { contact in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.contactName)
                                        .font(ClarityFonts.sansMedium(size: 15))
                                        .foregroundStyle(ClarityColors.textPrimary)
                                    if let phone = contact.contactPhone {
                                        Text(phone)
                                            .font(ClarityFonts.sans(size: 13))
                                            .foregroundStyle(ClarityColors.textMuted)
                                    }
                                }

                                Spacer()

                                Button {
                                    HapticManager.warning()
                                    modelContext.delete(contact)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(ClarityColors.textMuted)
                                }
                            }
                            .padding(ClaritySpacing.md)
                            .background(ClarityColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                        }
                    }

                    Text("\(importantContacts.count)/\(ProsocialLimits.maxImportantContacts) contacts")
                        .font(ClarityFonts.mono(size: 12))
                        .foregroundStyle(ClarityColors.textMuted)
                }

                // MARK: - WiFi Gate
                settingsSection("WIFI GATE") {
                    ToggleRow(
                        title: "WiFi-Gated Unlocking",
                        description: "Only unlock shielded apps on your home WiFi",
                        isOn: $wifiGateEnabled
                    )

                    if wifiGateEnabled {
                        VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
                            let networks = WiFiGateService.shared.homeNetworks
                            if networks.isEmpty {
                                Text("No home networks set. Go to WiFi settings to add one.")
                                    .font(ClarityFonts.sans(size: 13))
                                    .foregroundStyle(ClarityColors.textMuted)
                            } else {
                                ForEach(networks, id: \.self) { ssid in
                                    HStack {
                                        Image(systemName: "wifi")
                                            .foregroundStyle(ClarityColors.primary)
                                        Text(ssid)
                                            .font(ClarityFonts.sansMedium(size: 14))
                                            .foregroundStyle(ClarityColors.textPrimary)
                                        Spacer()
                                        Button {
                                            HapticManager.light()
                                            WiFiGateService.shared.removeHomeNetwork(ssid)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(ClarityColors.danger)
                                        }
                                    }
                                    .padding(ClaritySpacing.sm)
                                    .background(ClarityColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.sm))
                                }
                            }

                            Text("Up to \(ProsocialLimits.maxHomeNetworks) trusted networks")
                                .font(ClarityFonts.sans(size: 12))
                                .foregroundStyle(ClarityColors.textMuted)
                        }
                    }
                }

                // MARK: - Subscription
                settingsSection("SUBSCRIPTION") {
                    SubscriptionBadge()
                }

                // MARK: - Health
                settingsSection("HEALTH") {
                    Button {
                        HapticManager.light()
                        healthAuthorized = true // Placeholder: real impl would call HKHealthStore
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

                // MARK: - Intentions
                settingsSection("INTENTIONS") {
                    if intentions.isEmpty {
                        Text("No intentions set yet")
                            .font(ClarityFonts.sans(size: 14))
                            .foregroundStyle(ClarityColors.textMuted)
                    } else {
                        ForEach(intentions, id: \.id) { intention in
                            IntentionCard(intention: intention)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        HapticManager.warning()
                                        modelContext.delete(intention)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }

                    ClarityButton("Add Intention", variant: .ghost, size: .sm) {
                        // TODO: present intention creation sheet
                    }
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
            }
            wifiGateEnabled = WiFiGateService.shared.isEnabled
            dailyBudgetEnabled = profile?.dailyBudgetEnabled ?? false
            focusSessionBlockingEnabled = profile?.focusSessionBlockingEnabled ?? false
        }
        .onChange(of: wifiGateEnabled) { _, newValue in
            WiFiGateService.shared.isEnabled = newValue
        }
        .onChange(of: dailyBudgetEnabled) { _, newValue in
            profile?.dailyBudgetEnabled = newValue
            if newValue {
                // Start monitoring with saved budget config
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
        .animation(.easeInOut(duration: 0.25), value: wifiGateEnabled)
        .animation(.easeInOut(duration: 0.25), value: dailyBudgetEnabled)
        .animation(.easeInOut(duration: 0.25), value: focusSessionBlockingEnabled)
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
        // Delete all data
        try? modelContext.delete(model: FocusSession.self)
        try? modelContext.delete(model: MoodEntry.self)
        try? modelContext.delete(model: ImplementationIntention.self)
        try? modelContext.delete(model: ProsocialChallenge.self)
        try? modelContext.delete(model: ConnectionLog.self)
        try? modelContext.delete(model: ImportantContact.self)
        try? modelContext.delete(model: WiFiGateConfig.self)
        try? modelContext.delete(model: UserProfile.self)
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

// MARK: - Intention Card

private struct IntentionCard: View {
    let intention: ImplementationIntention

    var body: some View {
        HStack {
            Text("If ")
                .font(ClarityFonts.sans(size: 14))
                .foregroundStyle(ClarityColors.textMuted)
            + Text(intention.triggerCondition)
                .font(ClarityFonts.sansSemiBold(size: 14))
                .foregroundStyle(ClarityColors.textPrimary)
            + Text(" \u{2192} ")
                .font(ClarityFonts.sans(size: 14))
                .foregroundStyle(ClarityColors.textMuted)
            + Text(intention.intendedAction)
                .font(ClarityFonts.sansSemiBold(size: 14))
                .foregroundStyle(ClarityColors.primary)

            Spacer()
        }
        .padding(ClaritySpacing.md)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: ClarityRadius.md)
                .stroke(ClarityColors.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Shielded Apps List (Placeholder)

private struct ShieldedAppsList: View {
    let profile: UserProfile?

    // Placeholder app list for UI demonstration
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

                        // Custom circular checkbox
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

            Text("Selected apps will be blocked during focus sessions")
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
        .modelContainer(for: [UserProfile.self, ImplementationIntention.self, FocusSession.self, MoodEntry.self, ImportantContact.self, WiFiGateConfig.self, ProsocialChallenge.self, ConnectionLog.self], inMemory: true)
}
