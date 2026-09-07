import Foundation
import SwiftData

/// Not in PRODUCT_SPEC.md — added on request. Schedule/Todo categories
/// (`.event`) and Memo categories (`.memo`) are separate pools; a category
/// created from one context never shows up when picking a category in the
/// other.
enum CategoryKind: String, Codable {
    case event
    case memo
}

/// Shared by Schedule and Todo (PRODUCT_SPEC.md §16). Color is independent
/// of the pastel-blue completion scale in PlantingColor.
@Model
final class Category: Identifiable {
    var id: UUID
    var name: String
    var colorHex: String
    var order: Int
    /// Firebase Auth uid of the owning account (added on request, for
    /// multi-user sync). Empty string until scoped by a repository write.
    var ownerID: String = ""
    /// Added alongside `ownerID` — needed for last-write-wins conflict
    /// resolution once categories sync across devices.
    var updatedAt: Date = Date.now
    /// Stored as a raw String (rather than `CategoryKind` directly) so
    /// `#Predicate` filtering on it is a plain string comparison, not
    /// dependent on SwiftData's own enum-predicate support.
    var kindRawValue: String = CategoryKind.event.rawValue

    var kind: CategoryKind {
        get { CategoryKind(rawValue: kindRawValue) ?? .event }
        set { kindRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        order: Int,
        kind: CategoryKind = .event,
        ownerID: String = "",
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.order = order
        self.kindRawValue = kind.rawValue
        self.ownerID = ownerID
        self.updatedAt = updatedAt
    }
}
