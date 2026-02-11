import SwiftUI
import SwiftData

/// Configurable friction thresholds: escalating challenges at different screen time levels.
struct FrictionConfigView: View {
    var profile: UserProfile?

    @State private var thresholds: [Int] = [5, 15, 30, 45, 60]
    @State private var nightModeEnabled = false
    @State private var nightStart: Int = 22
    @State private var nightEnd: Int = 6

    private let levels: [(name: String, icon: String, description: String)] = [
        ("Awareness",            "eye",                         "A gentle reminder that you've been scrolling"),
        ("Breathing",            "wind",                        "Guided breathing exercise before continuing"),
        ("Intention Check",      "questionmark.circle",         "State why you need this app right now"),
        ("Reflection",           "heart",                       "Rate how you feel and journal a sentence"),
        ("Strong Encouragement", "exclamationmark.triangle",    "Multi-step challenge to prove you really need it"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.md) {

            // MARK: - Thresholds Header
            Text("FRICTION THRESHOLDS")
                .font(ClarityFonts.mono(size: 11))
                .tracking(3)
                .foregroundStyle(ClarityColors.textMuted)

            // MARK: - Level Rows
            ForEach(0..<5, id: \.self) { index in
                FrictionLevelRow(
                    name: levels[index].name,
                    icon: levels[index].icon,
                    description: levels[index].description,
                    minutes: $thresholds[index]
                )
            }

            // Reset defaults
            ClarityButton("Reset to Defaults", variant: .ghost, size: .sm) {
                HapticManager.light()
                thresholds = [5, 15, 30, 45, 60]
                syncToProfile()
            }

            // MARK: - Night Mode
            Divider()
                .background(ClarityColors.borderSubtle)

            Text("NIGHT MODE")
                .font(ClarityFonts.mono(size: 11))
                .tracking(3)
                .foregroundStyle(ClarityColors.textMuted)

            ToggleRow(
                title: "Night Mode",
                description: "Harder friction between \(formatHour(nightStart)) and \(formatHour(nightEnd))",
                isOn: $nightModeEnabled
            )

            if nightModeEnabled {
                HStack(spacing: ClaritySpacing.md) {
                    TimePickerRow(label: "Start", hour: $nightStart)
                    TimePickerRow(label: "End", hour: $nightEnd)
                }
            }
        }
        .onAppear {
            if let profile {
                thresholds = profile.frictionThresholds.count == 5
                    ? profile.frictionThresholds
                    : [5, 15, 30, 45, 60]
                nightStart = profile.nightModeStart
                nightEnd = profile.nightModeEnd
            }
        }
        .onChange(of: thresholds) { _, _ in syncToProfile() }
        .onChange(of: nightStart) { _, _ in syncToProfile() }
        .onChange(of: nightEnd) { _, _ in syncToProfile() }
    }

    private func syncToProfile() {
        profile?.frictionThresholds = thresholds
        profile?.nightModeStart = nightStart
        profile?.nightModeEnd = nightEnd
    }

    private func formatHour(_ hour: Int) -> String {
        let h = hour % 24
        if h == 0 { return "12 AM" }
        if h < 12 { return "\(h) AM" }
        if h == 12 { return "12 PM" }
        return "\(h - 12) PM"
    }
}

// MARK: - Friction Level Row

private struct FrictionLevelRow: View {
    let name: String
    let icon: String
    let description: String
    @Binding var minutes: Int

    var body: some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(ClarityColors.primary)
                    .frame(width: 24)

                Text(name)
                    .font(ClarityFonts.sansSemiBold(size: 15))
                    .foregroundStyle(ClarityColors.textPrimary)

                Spacer()

                Text("after \(minutes) min")
                    .font(ClarityFonts.mono(size: 12))
                    .foregroundStyle(ClarityColors.primary)
            }

            Text(description)
                .font(ClarityFonts.sans(size: 12))
                .foregroundStyle(ClarityColors.textMuted)

            // Slider: 5-120 in steps of 5
            Slider(
                value: Binding(
                    get: { Double(minutes) },
                    set: { newVal in
                        HapticManager.light()
                        minutes = Int(newVal / 5) * 5 // snap to 5
                    }
                ),
                in: 5...120,
                step: 5
            )
            .tint(ClarityColors.primary)
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

// MARK: - Time Picker Row

private struct TimePickerRow: View {
    let label: String
    @Binding var hour: Int

    var body: some View {
        VStack(spacing: ClaritySpacing.xs) {
            Text(label)
                .font(ClarityFonts.mono(size: 10))
                .foregroundStyle(ClarityColors.textMuted)

            HStack(spacing: ClaritySpacing.sm) {
                Button {
                    HapticManager.light()
                    hour = (hour - 1 + 24) % 24
                } label: {
                    Image(systemName: "minus.circle")
                        .foregroundStyle(ClarityColors.textSecondary)
                }

                Text(formatHour(hour))
                    .font(ClarityFonts.sansSemiBold(size: 14))
                    .foregroundStyle(ClarityColors.textPrimary)
                    .frame(width: 60)

                Button {
                    HapticManager.light()
                    hour = (hour + 1) % 24
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(ClarityColors.textSecondary)
                }
            }
            .padding(.vertical, ClaritySpacing.sm)
            .padding(.horizontal, ClaritySpacing.md)
            .background(ClarityColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
        }
        .frame(maxWidth: .infinity)
    }

    private func formatHour(_ h: Int) -> String {
        let hour = h % 24
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }
}

#Preview {
    ScrollView {
        FrictionConfigView(profile: nil)
            .padding()
    }
    .background(ClarityColors.background)
}
