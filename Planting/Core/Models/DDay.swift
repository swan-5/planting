import Foundation
import SwiftData

/// Not in PRODUCT_SPEC.md — added on request. A standalone date counter
/// shown next to the clover on the Calendar tab; `targetDate` may be in the
/// future ("D-n") or the past ("D+n").
@Model
final class DDay: Identifiable {
    var id: UUID
    var title: String
    var targetDate: Date
    /// Firebase Auth uid of the owning account (added on request, for
    /// multi-user sync). Empty string until scoped by a repository write.
    var ownerID: String = ""
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        targetDate: Date,
        ownerID: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.targetDate = targetDate
        self.ownerID = ownerID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension DDay {
    func daysFromToday(calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: .now)
        let target = calendar.startOfDay(for: targetDate)
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
    }

    func label(calendar: Calendar = .current) -> String {
        let days = daysFromToday(calendar: calendar)
        if days == 0 { return "D-DAY" }
        return days > 0 ? "D-\(days)" : "D+\(-days)"
    }
}
