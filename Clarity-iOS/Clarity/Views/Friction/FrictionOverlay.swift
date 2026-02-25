import SwiftUI

/// Full-screen overlay container that presents the appropriate friction intervention
/// based on the current patience escalation level (1-5).
struct FrictionOverlay: View {

    let frictionLevel: Int
    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            // Heavy overlay backdrop
            ClarityColors.overlayHeavy
                .ignoresSafeArea()
                .onTapGesture { /* block pass-through taps */ }

            // Card container (levels 1-3 use card layout, 4-5 are full-screen)
            if frictionLevel <= 3 {
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
            } else {
                frictionContent
            }
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
            AwarenessToast(onDismiss: onComplete)
        case 2:
            BreathingShield(onComplete: onComplete, onCancel: onCancel)
        case 3:
            IntentionCheck(onComplete: onComplete, onCancel: onCancel)
        case 4:
            CountdownUnlockView(
                delay: CountdownManager.shared.currentDelay,
                openNumber: CountdownManager.shared.opensToday + 1,
                onComplete: {
                    CountdownManager.shared.recordOpen()
                    onComplete()
                }
            )
        case 5:
            ScrollFrictionShield(onComplete: onComplete)
        default:
            EmptyView()
        }
    }
}

#Preview {
    FrictionOverlay(frictionLevel: 2, onComplete: {}, onCancel: {})
        .environment(AppState())
}
