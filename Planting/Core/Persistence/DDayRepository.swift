import Foundation
import SwiftData

protocol DDayRepository {
    func fetchAll() throws -> [DDay]
    func create(_ dDay: DDay) throws
    func update(_ dDay: DDay) throws
    func delete(_ dDay: DDay) throws
}

final class SwiftDataDDayRepository: DDayRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [DDay] {
        let uid = PersistenceController.currentUserID
        return try context.fetch(FetchDescriptor<DDay>(
            predicate: #Predicate { $0.ownerID == uid }
        ))
    }

    func create(_ dDay: DDay) throws {
        dDay.ownerID = PersistenceController.currentUserID
        context.insert(dDay)
        try context.save()
    }

    func update(_ dDay: DDay) throws {
        dDay.updatedAt = .now
        try context.save()
    }

    func delete(_ dDay: DDay) throws {
        context.delete(dDay)
        try context.save()
    }
}
