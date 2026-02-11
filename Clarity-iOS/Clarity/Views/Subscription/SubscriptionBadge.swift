import SwiftUI

/// Small pill badge for Settings showing current subscription status.
struct SubscriptionBadge: View {
    @State private var service = SubscriptionService.shared
    @State private var showPaywall = false

    var body: some View {
        Button {
            HapticManager.light()
            showPaywall = true
        } label: {
            HStack(spacing: ClaritySpacing.xs) {
                if service.isSubscribed {
                    Circle()
                        .fill(ClarityColors.success)
                        .frame(width: 8, height: 8)

                    Text("Pro — \(service.subscriptionStatus.capitalized)")
                        .font(ClarityFonts.sansMedium(size: 14))
                        .foregroundStyle(ClarityColors.success)
                } else {
                    Circle()
                        .fill(ClarityColors.textMuted)
                        .frame(width: 8, height: 8)

                    Text("Free")
                        .font(ClarityFonts.sansMedium(size: 14))
                        .foregroundStyle(ClarityColors.textMuted)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(ClarityColors.textMuted)
            }
            .padding(.horizontal, ClaritySpacing.md)
            .padding(.vertical, ClaritySpacing.sm)
            .background(ClarityColors.surface)
            .clipShape(Capsule())
        }
        .sheet(isPresented: $showPaywall) {
            SubscriptionView()
        }
    }
}
