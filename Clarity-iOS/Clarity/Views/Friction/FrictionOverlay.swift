import SwiftUI
import SwiftData

/// Full-screen overlay container that presents the appropriate friction intervention
/// based on the current escalation level (1-5).
/// Levels 2 and 4 show prosocial challenges when prosocial mode is enabled
/// and the user has important contacts configured.
struct FrictionOverlay: View {

    let frictionLevel: Int
    let onComplete: () -> Void
    let onCancel: () -> Void

    @Environment(AppState.self) private var appState
    @Query(sort: \ImportantContact.contactName) private var contacts: [ImportantContact]

    @State private var appeared = false

    /// Whether this level should use prosocial challenges instead of classic friction
    private var useProsocial: Bool {
        let engine = appState.prosocialEngine
        let isProsocialLevel = (frictionLevel == 2 || frictionLevel == 4)
        return isProsocialLevel && engine.prosocialEnabled && !contacts.isEmpty
    }

    var body: some View {
        ZStack {
            // Heavy overlay backdrop
            ClarityColors.overlayHeavy
                .ignoresSafeArea()
                .onTapGesture { /* block pass-through taps */ }

            // Card container
            VStack(spacing: ClaritySpacing.lg) {
                frictionContent
            }
            .padding(ClaritySpacing.xl)
            .frame(maxWidth: 360)
            .background(ClarityColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xxl))
            .overlay(
                RoundedRectangle(cornerRadius: ClarityRadius.xxl)
                    .stroke(ClarityColors.border, lineWidth: 1)
            )
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }

    // MARK: - Level Switch

    @ViewBuilder
    private var frictionContent: some View {
        switch frictionLevel {
        case 1:
            // Layer 1 is handled separately as AwarenessToast (not full-screen)
            EmptyView()
        case 2:
            if useProsocial {
                ProsocialChallengeView(
                    challengeType: .text,
                    onComplete: onComplete,
                    onCancel: onCancel
                )
            } else {
                BreathingShield(onComplete: onComplete, onCancel: onCancel)
            }
        case 3:
            IntentionCheck(onComplete: onComplete, onCancel: onCancel)
        case 4:
            if useProsocial {
                ProsocialChallengeView(
                    challengeType: .call,
                    onComplete: onComplete,
                    onCancel: onCancel
                )
            } else {
                ReflectionShield(onComplete: onComplete, onCancel: onCancel)
            }
        case 5:
            StrongEncouragement(onComplete: onComplete, onCancel: onCancel)
        default:
            EmptyView()
        }
    }
}

#Preview {
    FrictionOverlay(frictionLevel: 2, onComplete: {}, onCancel: {})
        .environment(AppState())
        .modelContainer(for: [ImportantContact.self], inMemory: true)
}
