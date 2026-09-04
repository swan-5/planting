import Foundation
import SwiftData

protocol MemoRepository {
    func fetchAll() throws -> [Memo]
    func memos(on date: Date) throws -> [Memo]
    func create(_ memo: Memo) throws
    func update(_ memo: Memo) throws
    func delete(_ memo: Memo) throws
}

final class SwiftDataMemoRepository: MemoRepository {
    private let context: ModelContext
    private let calendar: Calendar

    init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    func fetchAll() throws -> [Memo] {
        let uid = PersistenceController.currentUserID
        return try context.fetch(FetchDescriptor<Memo>(
            predicate: #Predicate { $0.ownerID == uid },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        ))
    }

    func memos(on date: Date) throws -> [Memo] {
        let day = calendar.startOfDay(for: date)
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { return [] }
        let uid = PersistenceController.currentUserID
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate { $0.date >= day && $0.date < nextDay && $0.ownerID == uid },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor)
    }

    func create(_ memo: Memo) throws {
        memo.ownerID = PersistenceController.currentUserID
        context.insert(memo)
        try context.save()
    }

    func update(_ memo: Memo) throws {
        memo.updatedAt = .now
        try context.save()
    }

    func delete(_ memo: Memo) throws {
        context.delete(memo)
        try context.save()
    }
}
