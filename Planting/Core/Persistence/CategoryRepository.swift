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
        try context.fetch(FetchDescriptor<Category>(sortBy: [SortDescriptor(\.order)]))
    }

    @discardableResult
    func create(name: String, colorHex: String) throws -> Category {
        let nextOrder = (try fetchAll().map(\.order).max() ?? -1) + 1
        let category = Category(name: name, colorHex: colorHex, order: nextOrder)
        context.insert(category)
        try context.save()
        return category
    }

    func rename(_ category: Category, to name: String) throws {
        category.name = name
        try context.save()
    }

    func updateColor(_ category: Category, colorHex: String) throws {
        category.colorHex = colorHex
        try context.save()
    }

    func reorder(_ categories: [Category]) throws {
        for (index, category) in categories.enumerated() {
            category.order = index
        }
        try context.save()
    }

    func delete(_ category: Category) throws {
        context.delete(category)
        try context.save()
    }
}
