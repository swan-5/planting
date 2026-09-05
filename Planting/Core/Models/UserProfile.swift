import Foundation
import SwiftData

/// Not in PRODUCT_SPEC.md — added on request. One row per account, created
/// the first time someone finishes (or skips) the post-signup birthday
/// prompt; its mere existence is what marks that prompt as already shown,
/// regardless of whether a birthday was actually entered.
@Model
final class UserProfile: Identifiable {
    var id: UUID
    var ownerID: String
    var birthday: Date?
    var createdAt: Date

    init(id: UUID = UUID(), ownerID: String, birthday: Date? = nil, createdAt: Date = .now) {
        self.id = id
        self.ownerID = ownerID
        self.birthday = birthday
        self.createdAt = createdAt
    }
}
