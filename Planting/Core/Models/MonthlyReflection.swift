import Foundation
import SwiftData

/// Not in PRODUCT_SPEC.md — added on request. One row per (year, month);
/// uniqueness is enforced by MonthlyReflectionRepository (fetch, then
/// update-or-insert), since SwiftData's `@Attribute(.unique)` only covers
/// a single property, not a composite key.
@Model
final class MonthlyReflection: Identifiable {
    var id: UUID
    var year: Int
    var month: Int
    var wentWell: String
    var couldImprove: String
    var nextMonthFocus: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        year: Int,
        month: Int,
        wentWell: String = "",
        couldImprove: String = "",
        nextMonthFocus: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.year = year
        self.month = month
        self.wentWell = wentWell
        self.couldImprove = couldImprove
        self.nextMonthFocus = nextMonthFocus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
