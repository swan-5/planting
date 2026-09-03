import Foundation
import Observation

@Observable
final class MonthlyReflectionViewModel {
    /// The three reflection prompts are editable (on request) but shared
    /// across every month rather than stored per-month, since they read as
    /// "how I want to reflect each month" rather than month-specific data.
    enum QuestionDefaults {
        static let wentWell = "What went well this month?"
        static let couldImprove = "What could have been better?"
        static let nextMonthFocus = "What do I want to focus on next month?"
    }

    private enum QuestionKey {
        static let wentWell = "reflectionQuestion.wentWell"
        static let couldImprove = "reflectionQuestion.couldImprove"
        static let nextMonthFocus = "reflectionQuestion.nextMonthFocus"
    }

    let monthDate: Date
    private(set) var data: MonthlyReflectionData?

    var wentWell: String = ""
    var couldImprove: String = ""
    var nextMonthFocus: String = ""

    var wentWellQuestion: String = QuestionDefaults.wentWell
    var couldImproveQuestion: String = QuestionDefaults.couldImprove
    var nextMonthFocusQuestion: String = QuestionDefaults.nextMonthFocus

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

        let defaults = UserDefaults.standard
        wentWellQuestion = defaults.string(forKey: QuestionKey.wentWell) ?? QuestionDefaults.wentWell
        couldImproveQuestion = defaults.string(forKey: QuestionKey.couldImprove) ?? QuestionDefaults.couldImprove
        nextMonthFocusQuestion = defaults.string(forKey: QuestionKey.nextMonthFocus) ?? QuestionDefaults.nextMonthFocus

        let comps = calendar.dateComponents([.year, .month], from: monthDate)
        guard let year = comps.year, let month = comps.month else { return }
        if let existing = try? reflectionRepository.fetch(year: year, month: month) {
            wentWell = existing.wentWell
            couldImprove = existing.couldImprove
            nextMonthFocus = existing.nextMonthFocus
        }
    }

    func saveQuestions() {
        let defaults = UserDefaults.standard
        defaults.set(wentWellQuestion, forKey: QuestionKey.wentWell)
        defaults.set(couldImproveQuestion, forKey: QuestionKey.couldImprove)
        defaults.set(nextMonthFocusQuestion, forKey: QuestionKey.nextMonthFocus)
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
