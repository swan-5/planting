import Foundation
import SwiftData

/// PRODUCT_SPEC.md §17. Memos relate to a date, not to a Schedule or Todo.
@Model
final class Memo: Identifiable {
    var id: UUID
    var title: String?
    var content: String
    var date: Date
    var locked: Bool
    /// Firebase Auth uid of the owning account (added on request, for
    /// multi-user sync). Empty string until scoped by a repository write.
    var ownerID: String = ""
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String? = nil,
        content: String,
        date: Date,
        locked: Bool = false,
        ownerID: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.date = date
        self.locked = locked
        self.ownerID = ownerID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
