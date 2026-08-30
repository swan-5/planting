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

    init(id: UUID = UUID(), name: String, colorHex: String, order: Int) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.order = order
    }
}
