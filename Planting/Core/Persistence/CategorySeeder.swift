import Foundation

/// PRODUCT_SPEC.md §16: these are examples, not requirements — users can
/// rename, recolor, reorder, or delete every one of them. Colors are muted
/// to match §20.1 (calm, restrained) and are independent of the pastel-blue
/// completion scale (PlantingColor.completionScale).
enum CategorySeeder {
    static let defaults: [(name: String, colorHex: String)] = [
        ("School", "8FAF9F"),
        ("Personal", "D4A373"),
        ("Work", "7C89B8"),
        ("Appointment", "D08C99"),
    ]

    static func seedIfNeeded(repository: CategoryRepository) throws {
        guard try repository.fetchAll().isEmpty else { return }
        for entry in defaults {
            try repository.create(name: entry.name, colorHex: entry.colorHex)
        }
    }
}
