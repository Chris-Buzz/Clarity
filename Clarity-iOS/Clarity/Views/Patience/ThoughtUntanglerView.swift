import SwiftUI

/// Premium thought externalization tool.
/// Lets users dump their thoughts and optionally send to Claude for structured reflection.
struct ThoughtUntanglerView: View {

    @State private var thoughtText: String = ""
    @State private var response: String = ""
    @State private var showPaywall = false
    @State private var errorMessage: String?

    private var claudeService = ClaudeAPIService.shared
    private var isSubscribed: Bool { SubscriptionService.shared.isSubscribed }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: ClaritySpacing.lg) {
                // Header
                Text("THOUGHT UNTANGLER")
                    .font(ClarityFonts.mono(size: 9))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.6))

                Text("Get it out of your head")
                    .font(ClarityFonts.serif(size: 26))
                    .foregroundStyle(.white)

                // Input area
                TextEditor(text: $thoughtText)
                    .font(ClarityFonts.sans(size: 16))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .padding(ClaritySpacing.md)
                    .frame(minHeight: 200)
                    .background(ClarityColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
                    .overlay(
                        RoundedRectangle(cornerRadius: ClarityRadius.xl)
                            .stroke(ClarityColors.borderSubtle, lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if thoughtText.isEmpty {
                            Text("Just start typing...")
                                .font(ClarityFonts.sans(size: 16))
                                .foregroundStyle(.white.opacity(0.25))
                                .padding(ClaritySpacing.md)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }

                // Action buttons
                HStack(spacing: ClaritySpacing.md) {
                    ClarityButton("Just Dump", variant: .secondary, size: .md, fullWidth: true) {
                        HapticManager.success()
                        // Save locally — just clear the text to acknowledge
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            response = "Dumped. Your thoughts are acknowledged."
                        }
                    }
                    .disabled(thoughtText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    ClarityButton("Untangle", variant: .primary, size: .md, fullWidth: true) {
                        if isSubscribed {
                            Task { await untangle() }
                        } else {
                            HapticManager.light()
                            showPaywall = true
                        }
                    }
                    .disabled(thoughtText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(ClarityFonts.sans(size: 14))
                        .foregroundStyle(ClarityColors.danger)
                }

                // Loading indicator
                if claudeService.isLoading {
                    HStack(spacing: ClaritySpacing.sm) {
                        ProgressView()
                            .tint(ClarityColors.primary)
                        Text("Thinking...")
                            .font(ClarityFonts.sans(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                // Response card
                if !response.isEmpty {
                    VStack(alignment: .leading, spacing: ClaritySpacing.md) {
                        Text("REFLECTION")
                            .font(ClarityFonts.mono(size: 9))
                            .tracking(3)
                            .foregroundStyle(.white.opacity(0.6))

                        Text(response)
                            .font(ClarityFonts.sans(size: 15))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineSpacing(6)
                    }
                    .padding(ClaritySpacing.lg)
                    .background(ClarityColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Usage indicator
                if isSubscribed && claudeService.hasAPIKey {
                    Text("\(claudeService.remainingCalls) untangles remaining today")
                        .font(ClarityFonts.mono(size: 10))
                        .foregroundStyle(.white.opacity(0.3))
                }

                // API key setup (only for subscribers without key)
                if isSubscribed && !claudeService.hasAPIKey {
                    apiKeySetup
                }
            }
            .padding(.horizontal, ClaritySpacing.lg)
            .padding(.top, ClaritySpacing.md)
            .padding(.bottom, ClaritySpacing.xxxl)
        }
        .background(ClarityColors.background)
        .sheet(isPresented: $showPaywall) {
            SubscriptionView()
        }
    }

    // MARK: - API Key Setup

    @State private var apiKeyInput: String = ""

    private var apiKeySetup: some View {
        VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
            Text("API KEY REQUIRED")
                .font(ClarityFonts.mono(size: 9))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.6))

            Text("Enter your Anthropic API key to enable AI untangling.")
                .font(ClarityFonts.sans(size: 13))
                .foregroundStyle(.white.opacity(0.5))

            TextField("sk-ant-...", text: $apiKeyInput)
                .font(ClarityFonts.mono(size: 14))
                .foregroundStyle(.white)
                .padding(ClaritySpacing.md)
                .background(ClarityColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: ClarityRadius.md)
                        .stroke(ClarityColors.borderSubtle, lineWidth: 1)
                )

            ClarityButton("Save Key", variant: .secondary, size: .sm) {
                HapticManager.success()
                claudeService.apiKey = apiKeyInput
            }
            .disabled(apiKeyInput.isEmpty)
        }
        .padding(ClaritySpacing.md)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
    }

    // MARK: - Untangle Action

    private func untangle() async {
        errorMessage = nil
        HapticManager.medium()

        do {
            let result = try await claudeService.untangleThought(thoughtText)
            HapticManager.success()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                response = result
            }
        } catch {
            HapticManager.error()
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ThoughtUntanglerView()
}
