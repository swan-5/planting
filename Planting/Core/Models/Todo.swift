import Foundation
import SwiftData

/// PRODUCT_SPEC.md §9, §11, §23. `dueDate` is required by the MVP create/edit
/// form (§11) but kept optional at the model level, matching the spec's note
/// that open-ended todos may be supported later without a schema change.
@Model
final class Todo: Identifiable {
    var id: UUID
    var title: String
    var startDate: Date
    var dueDate: Date?
    var memo: String?
    var recurrenceRule: RecurrenceRule
    /// Firebase Auth uid of the owning account (added on request, for
    /// multi-user sync). Empty string until scoped by a repository write.
    var ownerID: String = ""
    var createdAt: Date
    var updatedAt: Date

    var category: Category?

    @Relationship(deleteRule: .cascade, inverse: \TodoOccurrence.todo)
    var occurrences: [TodoOccurrence] = []

    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        dueDate: Date? = nil,
        category: Category? = nil,
        memo: String? = nil,
        recurrenceRule: RecurrenceRule = .none,
        ownerID: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.dueDate = dueDate
        self.category = category
        self.memo = memo
        self.recurrenceRule = recurrenceRule
        self.ownerID = ownerID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
