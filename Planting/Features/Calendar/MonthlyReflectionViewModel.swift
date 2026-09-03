import Foundation
import Observation

@Observable
final class MonthlyReflectionViewModel {
    let monthDate: Date
    private(set) var data: MonthlyReflectionData?

    var wentWell: String = ""
    var couldImprove: String = ""
    var nextMonthFocus: String = ""

    private let scheduleRepository: ScheduleRepository
    private let todoRepository: TodoRepository
    private let memoRepository: MemoRepository
    private let reflectionRepository: MonthlyReflectionRepository
    private let calendar: Calendar

    init(
        monthDate: Date,
        scheduleRepository: ScheduleRepository,
        todoRepository: TodoRepository,
        memoRepository: MemoRepository,
        reflectionRepository: MonthlyReflectionRepository,
        calendar: Calendar = MonthGridBuilder.calendar
    ) {
        self.monthDate = monthDate
        self.scheduleRepository = scheduleRepository
        self.todoRepository = todoRepository
        self.memoRepository = memoRepository
        self.reflectionRepository = reflectionRepository
        self.calendar = calendar
    }

    func load() {
        data = MonthlyReflectionCalculator.compute(
            for: monthDate,
            scheduleRepository: scheduleRepository,
            todoRepository: todoRepository,
            memoRepository: memoRepository,
            calendar: calendar
        )

        let comps = calendar.dateComponents([.year, .month], from: monthDate)
        guard let year = comps.year, let month = comps.month else { return }
        if let existing = try? reflectionRepository.fetch(year: year, month: month) {
            wentWell = existing.wentWell
            couldImprove = existing.couldImprove
            nextMonthFocus = existing.nextMonthFocus
        }
    }

    func saveReflection() {
        let comps = calendar.dateComponents([.year, .month], from: monthDate)
        guard let year = comps.year, let month = comps.month else { return }
        do {
            try reflectionRepository.save(
                year: year,
                month: month,
                wentWell: wentWell,
                couldImprove: couldImprove,
                nextMonthFocus: nextMonthFocus
            )
        } catch {
            print("Failed to save monthly reflection: \(error)")
        }
    }
}
