import Foundation
import SwiftData

/// One dated instance of a Todo, with its own completion state
/// (PRODUCT_SPEC.md §9.1, §12, §23). A non-repeating todo still gets exactly
/// one occurrence, so completion is always evaluated at this level, never on
/// Todo directly. See TodoRepository for lazy materialization.
@Model
final class TodoOccurrence: Identifiable {
    var id: UUID
    var occurrenceDate: Date
    var completed: Bool
    var completedAt: Date?
    /// Manual display order among todos on the same calendar date (not in
    /// the spec — added on request for a "move to top" action). Lower
    /// sorts first; ties break by the parent Todo's createdAt, so untouched
    /// items keep their original creation order.
    var order: Int = 0

    var todo: Todo?

    init(
        id: UUID = UUID(),
        todo: Todo? = nil,
        occurrenceDate: Date,
        completed: Bool = false,
        completedAt: Date? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.todo = todo
        self.occurrenceDate = occurrenceDate
        self.completed = completed
        self.completedAt = completedAt
        self.order = order
    }
}
