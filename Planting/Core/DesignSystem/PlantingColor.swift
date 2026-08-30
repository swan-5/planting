import SwiftUI

/// Design tokens from PRODUCT_SPEC.md §20.3.
/// Category colors are user-defined and independent of this palette.
///
/// The §8.2 pastel-blue completion-intensity background was removed on
/// request — date cells now stay flat white regardless of completion rate.
enum PlantingColor {
    static let primaryBlue = Color(hex: 0x6F9ED8)
    static let primaryText = Color(hex: 0x202124)
    static let secondaryText = Color(hex: 0x8A8D91)
    static let divider = Color(hex: 0xECEDEF)
    static let background = Color.white
}
