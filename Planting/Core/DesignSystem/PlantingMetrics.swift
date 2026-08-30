import CoreGraphics

/// Spacing and radius constants (PRODUCT_SPEC.md §20.4 — restraint over decoration).
enum PlantingSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

enum PlantingRadius {
    static let button: CGFloat = 9
    static let textField: CGFloat = 8
    static let sheet: CGFloat = 18
    /// Calendar date cells are not rounded cards by default (spec §20.4).
    static let dateCell: CGFloat = 0
}
