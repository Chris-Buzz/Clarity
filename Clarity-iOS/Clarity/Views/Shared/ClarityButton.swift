import SwiftUI

/// Reusable button with variant styling, size presets, and haptic feedback.
struct ClarityButton: View {

    enum Variant {
        case primary    // Filled orange background, white text
        case secondary  // Surface background with border
        case ghost      // Transparent background
    }

    enum Size {
        case sm, md, lg

        var verticalPadding: CGFloat {
            switch self {
            case .sm: return ClaritySpacing.sm
            case .md: return ClaritySpacing.sm + 4
            case .lg: return ClaritySpacing.md
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .sm: return ClaritySpacing.md
            case .md: return ClaritySpacing.lg
            case .lg: return ClaritySpacing.xl
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .sm: return 14
            case .md: return 16
            case .lg: return 18
            }
        }
    }

    let title: String
    let variant: Variant
    let size: Size
    let fullWidth: Bool
    let action: () -> Void

    init(
        _ title: String,
        variant: Variant = .primary,
        size: Size = .md,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.size = size
        self.fullWidth = fullWidth
        self.action = action
    }

    @State private var isPressed = false

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Text(title)
                .font(ClarityFonts.sansSemiBold(size: size.fontSize))
                .foregroundStyle(textColor)
                .padding(.vertical, size.verticalPadding)
                .padding(.horizontal, size.horizontalPadding)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: ClarityRadius.md)
                        .stroke(borderColor, lineWidth: variant == .secondary ? 1 : 0)
                )
        }
        .buttonStyle(ScalePressStyle())
    }

    // MARK: - Computed Colors

    private var textColor: Color {
        switch variant {
        case .primary:   return .white
        case .secondary: return ClarityColors.textPrimary
        case .ghost:     return ClarityColors.textSecondary
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:   return ClarityColors.primary
        case .secondary: return ClarityColors.surface
        case .ghost:     return .clear
        }
    }

    private var borderColor: Color {
        switch variant {
        case .secondary: return ClarityColors.border
        default:         return .clear
        }
    }
}

/// Press animation: scales to 0.96 with a spring curve.
private struct ScalePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        ClarityButton("Start Session", variant: .primary, fullWidth: true) {}
        ClarityButton("Settings", variant: .secondary) {}
        ClarityButton("Skip", variant: .ghost, size: .sm) {}
    }
    .padding()
    .background(ClarityColors.background)
}
