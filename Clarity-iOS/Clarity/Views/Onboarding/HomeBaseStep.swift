import SwiftUI
import SwiftData

/// Onboarding step for setting up WiFi-gated unlocking.
struct HomeBaseStep: View {
    let onContinue: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var wifiEnabled = true
    @State private var currentSSID: String?
    @State private var manualSSID = ""
    @State private var homeNetworkSet = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: ClaritySpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
                        Text("HOME BASE")
                            .font(ClarityFonts.mono(size: 11))
                            .tracking(3)
                            .foregroundStyle(ClarityColors.textMuted)

                        Text("Where's home?")
                            .font(ClarityFonts.serif(size: 28))
                            .foregroundStyle(ClarityColors.textPrimary)

                        Text("Doomscroll apps will only unlock when you're on your home WiFi. Everywhere else, Clarity keeps you present.")
                            .font(ClarityFonts.sans(size: 15))
                            .foregroundStyle(ClarityColors.textTertiary)
                            .lineSpacing(4)
                    }

                    // WiFi detection
                    VStack(alignment: .leading, spacing: ClaritySpacing.md) {
                        if let ssid = currentSSID {
                            HStack(spacing: ClaritySpacing.sm) {
                                Image(systemName: "wifi")
                                    .foregroundStyle(ClarityColors.primary)

                                Text("Connected to: \(ssid)")
                                    .font(ClarityFonts.sansMedium(size: 15))
                                    .foregroundStyle(ClarityColors.textPrimary)
                            }
                            .padding(ClaritySpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ClarityColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))

                            if !homeNetworkSet {
                                ClarityButton("Set as Home Base", variant: .primary, size: .md, fullWidth: true) {
                                    HapticManager.success()
                                    _ = WiFiGateService.shared.addHomeNetwork(ssid)
                                    homeNetworkSet = true
                                }
                            } else {
                                HStack(spacing: ClaritySpacing.sm) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(ClarityColors.success)
                                    Text("Home base set")
                                        .font(ClarityFonts.sansMedium(size: 15))
                                        .foregroundStyle(ClarityColors.success)
                                }
                            }
                        } else {
                            Text("No WiFi detected. Enter your home network name:")
                                .font(ClarityFonts.sans(size: 14))
                                .foregroundStyle(ClarityColors.textTertiary)

                            HStack(spacing: ClaritySpacing.sm) {
                                TextField("Network name (SSID)", text: $manualSSID)
                                    .font(.custom("Outfit-Regular", size: 15))
                                    .foregroundStyle(ClarityColors.textPrimary)
                                    .padding(ClaritySpacing.sm)
                                    .background(ClarityColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.sm))

                                ClarityButton("Set", variant: .primary, size: .sm) {
                                    guard !manualSSID.isEmpty else { return }
                                    HapticManager.success()
                                    _ = WiFiGateService.shared.addHomeNetwork(manualSSID)
                                    homeNetworkSet = true
                                }
                            }
                        }
                    }

                    // WiFi Gate toggle
                    ToggleRow(
                        title: "Enable WiFi Gate",
                        description: "Shield apps when you're away from home WiFi",
                        isOn: $wifiEnabled
                    )

                    Text("You can add up to 3 trusted networks in Settings")
                        .font(ClarityFonts.sans(size: 13))
                        .foregroundStyle(ClarityColors.textMuted)
                }
                .padding(.horizontal, ClaritySpacing.lg)
                .padding(.top, ClaritySpacing.lg)
                .padding(.bottom, ClaritySpacing.xxxl)
            }

            // Bottom CTA
            VStack(spacing: ClaritySpacing.sm) {
                ClarityButton("Continue", variant: .primary, size: .lg, fullWidth: true) {
                    saveConfig()
                    onContinue()
                }

                ClarityButton("Skip for now", variant: .ghost, size: .sm) {
                    onContinue()
                }
            }
            .padding(.horizontal, ClaritySpacing.lg)
            .padding(.bottom, ClaritySpacing.lg)
        }
        .background(ClarityColors.background)
        .onAppear {
            WiFiGateService.shared.fetchCurrentSSID()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                currentSSID = WiFiGateService.shared.currentSSID
            }
        }
    }

    private func saveConfig() {
        WiFiGateService.shared.isEnabled = wifiEnabled
        let config = WiFiGateConfig()
        config.isEnabled = wifiEnabled
        config.homeNetworks = WiFiGateService.shared.homeNetworks
        modelContext.insert(config)
    }
}
