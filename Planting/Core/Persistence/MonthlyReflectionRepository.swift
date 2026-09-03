import Foundation
import SwiftData

protocol MonthlyReflectionRepository {
    func fetch(year: Int, month: Int) throws -> MonthlyReflection?
    func save(year: Int, month: Int, wentWell: String, couldImprove: String, nextMonthFocus: String) throws
}

final class SwiftDataMonthlyReflectionRepository: MonthlyReflectionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetch(year: Int, month: Int) throws -> MonthlyReflection? {
        let descriptor = FetchDescriptor<MonthlyReflection>(
            predicate: #Predicate { $0.year == year && $0.month == month }
        )
        return try context.fetch(descriptor).first
    }

    func save(year: Int, month: Int, wentWell: String, couldImprove: String, nextMonthFocus: String) throws {
        if let existing = try fetch(year: year, month: month) {
            existing.wentWell = wentWell
            existing.couldImprove = couldImprove
            existing.nextMonthFocus = nextMonthFocus
            existing.updatedAt = .now
        } else {
            let reflection = MonthlyReflection(
                year: year,
                month: month,
                wentWell: wentWell,
                couldImprove: couldImprove,
                nextMonthFocus: nextMonthFocus
            )
            context.insert(reflection)
        }
        try context.save()
    }
}
