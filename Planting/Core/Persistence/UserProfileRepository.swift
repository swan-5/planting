import Foundation
import SwiftData

protocol UserProfileRepository {
    func fetch() throws -> UserProfile?
    func save(birthday: Date?) throws
}

final class SwiftDataUserProfileRepository: UserProfileRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetch() throws -> UserProfile? {
        let uid = PersistenceController.currentUserID
        let descriptor = FetchDescriptor<UserProfile>(predicate: #Predicate { $0.ownerID == uid })
        return try context.fetch(descriptor).first
    }

    func save(birthday: Date?) throws {
        if let existing = try fetch() {
            existing.birthday = birthday
        } else {
            context.insert(UserProfile(ownerID: PersistenceController.currentUserID, birthday: birthday))
        }
        try context.save()
    }
}
