import Foundation
import SwiftData

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

    init(id: UUID = UUID(), name: String, colorHex: String, order: Int, ownerID: String = "", updatedAt: Date = .now) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.order = order
        self.ownerID = ownerID
        self.updatedAt = updatedAt
    }
}
