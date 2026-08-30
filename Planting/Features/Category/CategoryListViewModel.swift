import Foundation
import Observation
import SwiftUI

@Observable
final class CategoryListViewModel {
    private(set) var categories: [Category] = []
    private let repository: CategoryRepository

    init(repository: CategoryRepository) {
        self.repository = repository
    }

    func load() {
        do {
            categories = try repository.fetchAll()
        } catch {
            print("Failed to load categories: \(error)")
        }
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        var reordered = categories
        reordered.move(fromOffsets: source, toOffset: destination)
        do {
            try repository.reorder(reordered)
            categories = reordered
        } catch {
            print("Failed to reorder categories: \(error)")
        }
    }

    func delete(_ category: Category) {
        do {
            try repository.delete(category)
            load()
        } catch {
            print("Failed to delete category: \(error)")
        }
    }

    func save(editingID: UUID?, name: String, colorHex: String) {
        do {
            if let editingID, let existing = categories.first(where: { $0.id == editingID }) {
                try repository.rename(existing, to: name)
                try repository.updateColor(existing, colorHex: colorHex)
            } else {
                try repository.create(name: name, colorHex: colorHex)
            }
            load()
        } catch {
            print("Failed to save category: \(error)")
        }
    }
}
