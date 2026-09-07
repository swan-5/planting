import Foundation
import SwiftData

protocol MonthlyReflectionRepository {
    func fetch(year: Int, month: Int) throws -> MonthlyReflection?
    func save(year: Int, month: Int, goal: String, wentWell: String, couldImprove: String, nextMonthFocus: String) throws
}

final class SwiftDataMonthlyReflectionRepository: MonthlyReflectionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetch(year: Int, month: Int) throws -> MonthlyReflection? {
        let uid = PersistenceController.currentUserID
        let descriptor = FetchDescriptor<MonthlyReflection>(
            predicate: #Predicate { $0.year == year && $0.month == month && $0.ownerID == uid }
        )
        return try context.fetch(descriptor).first
    }

    func save(year: Int, month: Int, goal: String, wentWell: String, couldImprove: String, nextMonthFocus: String) throws {
        if let existing = try fetch(year: year, month: month) {
            existing.goal = goal
            existing.wentWell = wentWell
            existing.couldImprove = couldImprove
            existing.nextMonthFocus = nextMonthFocus
            existing.updatedAt = .now
        } else {
            let reflection = MonthlyReflection(
                year: year,
                month: month,
                goal: goal,
                wentWell: wentWell,
                couldImprove: couldImprove,
                nextMonthFocus: nextMonthFocus,
                ownerID: PersistenceController.currentUserID
            )
            context.insert(reflection)
        }
        try context.save()
    }
}
