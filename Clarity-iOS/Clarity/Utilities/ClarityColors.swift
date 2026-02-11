import SwiftUI

/// Centralized color palette for the Clarity app (dark-only UI).
enum ClarityColors {
    // MARK: - Backgrounds
    static let background       = Color(hex: "#030303")
    static let surface          = Color(hex: "#141414")
    static let surfaceElevated  = Color(hex: "#1a1a1a")

    // MARK: - Text
    static let textPrimary      = Color.white
    static let textSecondary    = Color.white.opacity(0.7)
    static let textTertiary     = Color.white.opacity(0.6)
    static let textMuted        = Color.white.opacity(0.35)

    // MARK: - Borders
    static let border           = Color.white.opacity(0.15)
    static let borderSubtle     = Color.white.opacity(0.08)
    static let borderAccent     = Color.white.opacity(0.25)

    // MARK: - Primary (Orange)
    static let primary          = Color(hex: "#f97316")
    static let primaryMuted     = Color(hex: "#f97316").opacity(0.15)
    static let primaryGlow      = Color(hex: "#f97316").opacity(0.3)

    // MARK: - Semantic
    static let success          = Color(hex: "#22c55e")
    static let successMuted     = Color(hex: "#22c55e").opacity(0.15)
    static let danger           = Color(hex: "#ef4444")
    static let dangerMuted      = Color(hex: "#ef4444").opacity(0.15)
    static let warning          = Color(hex: "#eab308")
    static let warningMuted     = Color(hex: "#eab308").opacity(0.15)

    // MARK: - Overlays
    static let overlay          = Color.black.opacity(0.8)
    static let overlayHeavy     = Color.black.opacity(0.95)
}
