import Foundation
import Observation

@Observable
final class CalendarHomeViewModel {
    struct CellContent {
        var todos: [TodoItem] = []
    }

    /// One schedule's bar segment within a single week (grid row) — every
    /// schedule renders as a category-colored background bar now (not just
    /// multi-day ones, on request), so a single-day schedule is just a bar
    /// with columnSpan 1. A schedule spanning more than one week gets one
    /// bar per week row it crosses, each clamped to that week's 7 columns.
    struct ScheduleBar: Identifiable {
        let occurrence: ScheduleOccurrence
        let weekStart: Date
        let startColumn: Int
        let columnSpan: Int
        /// Vertical stacking slot when multiple multi-day bars overlap the
        /// same week (greedy interval packing, same idea as Apple/Google
        /// Calendar's month view).
        let lane: Int
        var id: String { "\(occurrence.id)-\(weekStart.timeIntervalSince1970)" }
    }

    private let calendar: Calendar
    private let scheduleRepository: ScheduleRepository
    private let todoRepository: TodoRepository

    private(set) var visibleMonth: Date
    private(set) var cellContents: [Date: CellContent] = [:]
    private(set) var scheduleBars: [ScheduleBar] = []
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

    func scheduleBars(forWeekStarting date: Date) -> [ScheduleBar] {
        let weekStart = calendar.startOfDay(for: date)
        return scheduleBars.filter { calendar.isDate($0.weekStart, inSameDayAs: weekStart) }
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
                let dayTodos = todoItems
                    .filter { TodoVisibility.isVisible(todo: $0.todo, occurrence: $0.occurrence, on: dayStart, calendar: calendar) }
                    .sorted {
                        $0.occurrence.order != $1.occurrence.order
                            ? $0.occurrence.order < $1.occurrence.order
                            : $0.todo.createdAt < $1.todo.createdAt
                    }
                contents[dayStart] = CellContent(todos: dayTodos)
            }
            cellContents = contents

            let weeks = stride(from: 0, to: gridDays.count, by: 7)
                .map { Array(gridDays[$0..<min($0 + 7, gridDays.count)]) }
            scheduleBars = Self.packScheduleBars(
                occurrences: scheduleOccurrences,
                weeks: weeks,
                calendar: calendar
            )
        } catch {
            print("Failed to load calendar data: \(error)")
        }
    }

    /// Greedy interval-lane packing, one pass per week: every schedule
    /// occurrence (single-day included) is clamped to that week's 7
    /// columns and assigned the lowest lane whose last-used column doesn't
    /// overlap it.
    private static func packScheduleBars(
        occurrences: [ScheduleOccurrence],
        weeks: [[MonthGridDay]],
        calendar: Calendar
    ) -> [ScheduleBar] {
        var bars: [ScheduleBar] = []

        for week in weeks {
            let weekDays = week.map { calendar.startOfDay(for: $0.date) }
            guard let weekFirst = weekDays.first, let weekLast = weekDays.last else { continue }

            let relevant = occurrences
                .filter { calendar.startOfDay(for: $0.endDate) >= weekFirst && calendar.startOfDay(for: $0.date) <= weekLast }
                .sorted { $0.date < $1.date }

            var laneEndColumn: [Int] = []
            for occurrence in relevant {
                let occStart = calendar.startOfDay(for: occurrence.date)
                let occEnd = calendar.startOfDay(for: occurrence.endDate)
                let startColumn = weekDays.firstIndex(where: { $0 >= occStart }) ?? 0
                let endColumn = weekDays.lastIndex(where: { $0 <= occEnd }) ?? weekDays.count - 1
                guard endColumn >= startColumn else { continue }

                var lane = 0
                while lane < laneEndColumn.count && laneEndColumn[lane] >= startColumn {
                    lane += 1
                }
                if lane == laneEndColumn.count {
                    laneEndColumn.append(endColumn)
                } else {
                    laneEndColumn[lane] = endColumn
                }

                bars.append(ScheduleBar(
                    occurrence: occurrence,
                    weekStart: weekFirst,
                    startColumn: startColumn,
                    columnSpan: endColumn - startColumn + 1,
                    lane: lane
                ))
            }
        }
        return bars
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
