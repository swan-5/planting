import SwiftUI

/// Pretendard is the default product font (PRODUCT_SPEC.md §20.2, non-negotiable #11).
/// Only weights 400/500/600 are used — avoid 700+ bold per spec.
///
/// Font files are not bundled yet: add Pretendard-Regular.otf, Pretendard-Medium.otf,
/// and Pretendard-SemiBold.otf to Planting/Resources/Fonts and register them via
/// UIAppFonts in project.yml (already declared) before this resolves to the real
/// typeface. Until then SwiftUI silently falls back to the system font.
enum PlantingFont {
    private enum Name {
        static let regular = "Pretendard-Regular"
        static let medium = "Pretendard-Medium"
        static let semiBold = "Pretendard-SemiBold"
    }

    static func body(_ size: CGFloat = 15) -> Font {
        .custom(Name.regular, size: size)
    }

    static func emphasis(_ size: CGFloat = 15) -> Font {
        .custom(Name.medium, size: size)
    }

    static func sectionHeading(_ size: CGFloat = 17) -> Font {
        .custom(Name.semiBold, size: size)
    }

    /// Calendar month header (PRODUCT_SPEC.md §6.2 — avoid oversized headings).
    static let monthTitle = sectionHeading(20)
    static let dateNumber = emphasis(13)
    static let itemLabel = body(12)
    static let caption = body(11)
}
