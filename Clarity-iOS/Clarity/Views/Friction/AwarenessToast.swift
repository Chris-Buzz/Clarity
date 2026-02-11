import SwiftUI

/// Layer 1 friction (5 min threshold). A non-blocking toast banner that slides
/// in from the top and auto-dismisses after 5 seconds.
struct AwarenessToast: View {

    var onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        VStack {
            if isVisible {
                toastCard
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.horizontal, ClaritySpacing.md)
                    .padding(.top, ClaritySpacing.xxl)
            }

            Spacer()
        }
        .onAppear {
            HapticManager.light()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isVisible = true
            }
            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                dismiss()
            }
        }
    }

    // MARK: - Toast Card

    private var toastCard: some View {
        VStack(spacing: ClaritySpacing.sm) {
            HStack(spacing: ClaritySpacing.sm) {
                Image(systemName: "eye")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(ClarityColors.primary)

                Text("You've been scrolling for 5 minutes")
                    .font(ClarityFonts.sans(size: 15))
                    .foregroundStyle(ClarityColors.textPrimary)
                    .lineLimit(2)
            }

            Text("Is this intentional?")
                .font(ClarityFonts.sans(size: 13))
                .foregroundStyle(ClarityColors.textTertiary)

            Button {
                dismiss()
            } label: {
                Text("Got it")
                    .font(ClarityFonts.sansMedium(size: 13))
                    .foregroundStyle(ClarityColors.primary)
                    .padding(.vertical, ClaritySpacing.xs)
                    .padding(.horizontal, ClaritySpacing.md)
            }
        }
        .padding(ClaritySpacing.md)
        .background(ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: ClarityRadius.xl)
                .stroke(ClarityColors.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
    }

    // MARK: - Helpers

    private func dismiss() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            isVisible = false
        }
        // Give the animation time to finish before calling back
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onDismiss()
        }
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        AwarenessToast(onDismiss: {})
    }
}
