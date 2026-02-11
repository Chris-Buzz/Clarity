import SwiftUI

/// Typography helpers wrapping the app's custom font families.
/// Fonts must be included in the bundle and registered in Info.plist.
enum ClarityFonts {

    // MARK: - Serif (Playfair Display)

    static func serif(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold, .heavy, .black:
            name = "PlayfairDisplay-Bold"
        default:
            name = "PlayfairDisplay-Regular"
        }
        return .custom(name, size: size)
    }

    static func serifItalic(size: CGFloat) -> Font {
        .custom("PlayfairDisplay-Italic", size: size)
    }

    // MARK: - Sans (Outfit)

    static func sans(size: CGFloat) -> Font {
        .custom("Outfit-Regular", size: size)
    }

    static func sansMedium(size: CGFloat) -> Font {
        .custom("Outfit-Medium", size: size)
    }

    static func sansSemiBold(size: CGFloat) -> Font {
        .custom("Outfit-SemiBold", size: size)
    }

    static func sansLight(size: CGFloat) -> Font {
        .custom("Outfit-Light", size: size)
    }

    // MARK: - Mono (Space Mono)

    static func mono(size: CGFloat) -> Font {
        .custom("SpaceMono-Regular", size: size)
    }
}
