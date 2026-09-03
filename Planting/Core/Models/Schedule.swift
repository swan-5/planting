import Foundation
import SwiftData

/// PRODUCT_SPEC.md §13–§15. Recurring schedules are not materialized into
/// per-occurrence rows — they have no completion state, so RecurrenceEngine
/// expands `recurrenceRule` on demand for whatever date range is on screen.
@Model
final class Schedule: Identifiable {
    var id: UUID
    var title: String
    var startDate: Date
    var endDate: Date?
    var startTime: Date?
    var endTime: Date?
    var allDay: Bool
    var location: String?
    var memo: String?
    var recurrenceRule: RecurrenceRule
    var createdAt: Date
    var updatedAt: Date

    var category: Category?

    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        endDate: Date? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        allDay: Bool = false,
        category: Category? = nil,
        location: String? = nil,
        memo: String? = nil,
        recurrenceRule: RecurrenceRule = .none,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.startTime = startTime
        self.endTime = endTime
        self.allDay = allDay
        self.category = category
        self.location = location
        self.memo = memo
        self.recurrenceRule = recurrenceRule
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
