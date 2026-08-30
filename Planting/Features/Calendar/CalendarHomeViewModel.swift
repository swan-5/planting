import Foundation
import Observation

@Observable
final class CalendarHomeViewModel {
    struct CellContent {
        var schedules: [ScheduleOccurrence] = []
        var todos: [TodoItem] = []
    }

    private let calendar: Calendar
    private let scheduleRepository: ScheduleRepository
    private let todoRepository: TodoRepository

    private(set) var visibleMonth: Date
    private(set) var cellContents: [Date: CellContent] = [:]
    /// In-memory only (not persisted) — resets on relaunch, which is fine
    /// for a short-lived copy/paste clipboard.
    private(set) var copiedPayload: CalendarDragPayload?

    init(
        scheduleRepository: ScheduleRepository,
        todoRepository: TodoRepository,
        referenceDate: Date = .now,
        calendar: Calendar = MonthGridBuilder.calendar
    ) {
        self.scheduleRepository = scheduleRepository
        self.todoRepository = todoRepository
        self.calendar = calendar
        self.visibleMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate))
            ?? referenceDate
    }

    var days: [MonthGridDay] {
        MonthGridBuilder.days(for: visibleMonth, calendar: calendar)
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale.autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: visibleMonth)
    }

    var weekdaySymbols: [String] {
        calendar.shortWeekdaySymbols.map { $0.uppercased() }
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    func content(for date: Date) -> CellContent {
        cellContents[calendar.startOfDay(for: date)] ?? CellContent()
    }

    /// Calendar weeks (grid rows) overlapping the visible month that have
    /// at least one todo across their 7 days, all of them done. Not
    /// persisted — recomputed from the visible month's own data, so it
    /// "resets" automatically whenever the user moves to a different month.
    var fullyCompletedWeeksThisMonth: Int {
        stride(from: 0, to: days.count, by: 7)
            .map { Array(days[$0..<min($0 + 7, days.count)]) }
            .filter { week in week.contains(where: \.isInCurrentMonth) }
            .filter { week in
                let todos = week.flatMap { content(for: $0.date).todos }
                return !todos.isEmpty && todos.allSatisfy(\.occurrence.completed)
            }
            .count
    }

    func goToPreviousMonth() {
        guard let date = calendar.date(byAdding: .month, value: -1, to: visibleMonth) else { return }
        visibleMonth = date
        loadMonthData()
    }

    func goToNextMonth() {
        guard let date = calendar.date(byAdding: .month, value: 1, to: visibleMonth) else { return }
        visibleMonth = date
        loadMonthData()
    }

    func goToToday() {
        visibleMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: .now)) ?? .now
        loadMonthData()
    }

    func loadMonthData() {
        let gridDays = days
        guard let first = gridDays.first?.date, let last = gridDays.last?.date else { return }
        let range = first...last

        do {
            let scheduleOccurrences = try scheduleRepository.occurrences(in: range)
            let todoItems = try todoRepository.items(in: range)

            var contents: [Date: CellContent] = [:]
            for day in gridDays {
                let dayStart = calendar.startOfDay(for: day.date)
                let daySchedules = scheduleOccurrences.filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
                let dayTodos = todoItems
                    .filter { TodoVisibility.isVisible(todo: $0.todo, occurrence: $0.occurrence, on: dayStart, calendar: calendar) }
                    .sorted {
                        $0.occurrence.order != $1.occurrence.order
                            ? $0.occurrence.order < $1.occurrence.order
                            : $0.todo.createdAt < $1.todo.createdAt
                    }
                contents[dayStart] = CellContent(schedules: daySchedules, todos: dayTodos)
            }
            cellContents = contents
        } catch {
            print("Failed to load calendar data: \(error)")
        }
    }

    func moveItem(_ payload: CalendarDragPayload, to destinationDate: Date) {
        guard !calendar.isDate(payload.sourceDate, inSameDayAs: destinationDate) else { return }
        do {
            switch payload.kind {
            case .todoOccurrence:
                try todoRepository.moveOccurrence(id: payload.id, sourceDate: payload.sourceDate, to: destinationDate)
            case .schedule:
                try scheduleRepository.moveSchedule(id: payload.id, sourceDate: payload.sourceDate, to: destinationDate)
            }
            loadMonthData()
        } catch {
            print("Failed to move item: \(error)")
        }
    }

    func toggleTodoCompletion(_ item: TodoItem) {
        do {
            try todoRepository.setCompleted(item.occurrence, completed: !item.occurrence.completed, at: .now)
            loadMonthData()
        } catch {
            print("Failed to toggle todo: \(error)")
        }
    }

    /// Moves `item` above every other todo currently showing on `date`.
    func moveTodoToTop(_ item: TodoItem, on date: Date) {
        let dayTodos = content(for: date).todos
        let minOrder = dayTodos.map(\.occurrence.order).min() ?? 0
        guard item.occurrence.order > minOrder || dayTodos.first?.id != item.id else { return }
        do {
            try todoRepository.setOrder(occurrenceID: item.occurrence.id, order: minOrder - 1)
            loadMonthData()
        } catch {
            print("Failed to reorder todo: \(error)")
        }
    }

    func copyItem(_ payload: CalendarDragPayload) {
        copiedPayload = payload
    }

    func pasteItem(to date: Date) {
        guard let copiedPayload else { return }
        do {
            switch copiedPayload.kind {
            case .todoOccurrence:
                try todoRepository.duplicateOccurrence(id: copiedPayload.id, to: date)
            case .schedule:
                try scheduleRepository.duplicateSchedule(id: copiedPayload.id, to: date)
            }
            loadMonthData()
        } catch {
            print("Failed to paste item: \(error)")
        }
    }
}
