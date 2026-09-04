import Foundation
import SwiftData

protocol CategoryRepository {
    func fetchAll() throws -> [Category]
    @discardableResult
    func create(name: String, colorHex: String) throws -> Category
    func rename(_ category: Category, to name: String) throws
    func updateColor(_ category: Category, colorHex: String) throws
    func reorder(_ categories: [Category]) throws
    func delete(_ category: Category) throws
}

final class SwiftDataCategoryRepository: CategoryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Category] {
        let uid = PersistenceController.currentUserID
        return try context.fetch(FetchDescriptor<Category>(
            predicate: #Predicate { $0.ownerID == uid },
            sortBy: [SortDescriptor(\.order)]
        ))
    }

    @discardableResult
    func create(name: String, colorHex: String) throws -> Category {
        let nextOrder = (try fetchAll().map(\.order).max() ?? -1) + 1
        let category = Category(name: name, colorHex: colorHex, order: nextOrder, ownerID: PersistenceController.currentUserID)
        context.insert(category)
        try context.save()
        return category
    }

    func rename(_ category: Category, to name: String) throws {
        category.name = name
        category.updatedAt = .now
        try context.save()
    }

    func updateColor(_ category: Category, colorHex: String) throws {
        category.colorHex = colorHex
        category.updatedAt = .now
        try context.save()
    }

    func reorder(_ categories: [Category]) throws {
        for (index, category) in categories.enumerated() {
            category.order = index
            category.updatedAt = .now
        }
        try context.save()
    }

    func delete(_ category: Category) throws {
        context.delete(category)
        try context.save()
    }
}
