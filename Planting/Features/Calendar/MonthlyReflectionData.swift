import Foundation

/// Auto-aggregated stats for one month, computed fresh each time rather
/// than stored — so re-opening a past month's Reflection always reflects
/// the data as it stands today, while the hand-written reflection text
/// (see MonthlyReflection) is the only part that's actually persisted.
struct MonthlyReflectionData {
    struct WeekSummary {
        let startDate: Date
        let endDate: Date
        let completed: Int
        let total: Int
    }

    struct CategorySummary: Identifiable {
        let category: Category?
        let count: Int
        var id: String { category?.id.uuidString ?? "uncategorized" }
        var name: String { category?.name ?? "Uncategorized" }
    }

    struct DaySummary {
        let date: Date
        let completed: Int
        let total: Int
    }

    let monthDate: Date
    let totalTodos: Int
    let completedTodos: Int
    let scheduleCount: Int
    let memoCount: Int
    let fullyCompletedWeeks: Int
    let totalWeeksInMonth: Int
    let bestWeek: WeekSummary?
    let categoryBreakdown: [CategorySummary]
    let bestDay: DaySummary?
    let incompleteTodos: [TodoItem]

    var completionRate: Double {
        totalTodos == 0 ? 0 : Double(completedTodos) / Double(totalTodos)
    }
}

enum MonthlyReflectionCalculator {
    /// The fully-completed-week rule here intentionally mirrors
    /// CalendarHomeViewModel.fullyCompletedWeeksThisMonth (a week with
    /// ≥1 todo across its 7 days, all of them done) — duplicated rather
    /// than shared, so the live calendar's own calculation is never at
    /// risk of changing as a side effect of this feature.
    static func compute(
        for monthDate: Date,
        scheduleRepository: ScheduleRepository,
        todoRepository: TodoRepository,
        memoRepository: MemoRepository,
        calendar: Calendar = MonthGridBuilder.calendar
    ) -> MonthlyReflectionData {
        let gridDays = MonthGridBuilder.days(for: monthDate, calendar: calendar)
        let monthDaysOnly = gridDays.filter(\.isInCurrentMonth)

        guard let monthStart = monthDaysOnly.first?.date, let monthEnd = monthDaysOnly.last?.date else {
            return MonthlyReflectionData(
                monthDate: monthDate, totalTodos: 0, completedTodos: 0, scheduleCount: 0,
                memoCount: 0, fullyCompletedWeeks: 0, totalWeeksInMonth: 0, bestWeek: nil,
                categoryBreakdown: [], bestDay: nil, incompleteTodos: []
            )
        }
        let monthRange = calendar.startOfDay(for: monthStart)...calendar.startOfDay(for: monthEnd)

        let scheduleOccurrences = (try? scheduleRepository.occurrences(in: monthRange)) ?? []

        let candidateTodoItems = (try? todoRepository.items(in: monthRange)) ?? []
        let monthTodoItems = candidateTodoItems.filter {
            TodoVisibility.window(for: $0.todo, occurrence: $0.occurrence, calendar: calendar).overlaps(monthRange)
        }
        let completedCount = monthTodoItems.filter(\.occurrence.completed).count

        let memoCount = ((try? memoRepository.fetchAll()) ?? []).filter { memo in
            let day = calendar.startOfDay(for: memo.date)
            return day >= monthRange.lowerBound && day <= monthRange.upperBound
        }.count

        func todosVisible(on date: Date) -> [TodoItem] {
            let day = calendar.startOfDay(for: date)
            return monthTodoItems.filter { TodoVisibility.isVisible(todo: $0.todo, occurrence: $0.occurrence, on: day, calendar: calendar) }
        }

        let weeks = stride(from: 0, to: gridDays.count, by: 7)
            .map { Array(gridDays[$0..<min($0 + 7, gridDays.count)]) }
            .filter { week in week.contains(where: \.isInCurrentMonth) }

        var fullyCompletedWeeksCount = 0
        var weekStats: [(range: ClosedRange<Date>, completed: Int, total: Int)] = []
        for week in weeks {
            guard let first = week.first?.date, let last = week.last?.date else { continue }
            let weekTodos = week.flatMap { todosVisible(on: $0.date) }
            let completed = weekTodos.filter(\.occurrence.completed).count
            let total = weekTodos.count
            if total > 0 && completed == total {
                fullyCompletedWeeksCount += 1
            }
            weekStats.append((
                range: calendar.startOfDay(for: first)...calendar.startOfDay(for: last),
                completed: completed,
                total: total
            ))
        }

        let bestWeekStat = weekStats
            .filter { $0.total > 0 }
            .max { lhs, rhs in
                let lhsRate = Double(lhs.completed) / Double(lhs.total)
                let rhsRate = Double(rhs.completed) / Double(rhs.total)
                return lhsRate != rhsRate ? lhsRate < rhsRate : lhs.total < rhs.total
            }
        let bestWeek = bestWeekStat.map {
            MonthlyReflectionData.WeekSummary(
                startDate: $0.range.lowerBound, endDate: $0.range.upperBound,
                completed: $0.completed, total: $0.total
            )
        }

        var categoryGroups: [String: (category: Category?, count: Int)] = [:]
        for item in monthTodoItems {
            let key = item.todo.category?.id.uuidString ?? "uncategorized"
            let current = categoryGroups[key] ?? (item.todo.category, 0)
            categoryGroups[key] = (current.category, current.count + 1)
        }
        let categoryBreakdown = categoryGroups.values
            .map { MonthlyReflectionData.CategorySummary(category: $0.category, count: $0.count) }
            .sorted { $0.count > $1.count }

        var bestDay: MonthlyReflectionData.DaySummary?
        for day in monthDaysOnly {
            let items = todosVisible(on: day.date)
            guard !items.isEmpty else { continue }
            let completed = items.filter(\.occurrence.completed).count
            let total = items.count
            let candidateRate = Double(completed) / Double(total)
            if let current = bestDay {
                let currentRate = Double(current.completed) / Double(current.total)
                if candidateRate > currentRate || (candidateRate == currentRate && total > current.total) {
                    bestDay = MonthlyReflectionData.DaySummary(date: day.date, completed: completed, total: total)
                }
            } else {
                bestDay = MonthlyReflectionData.DaySummary(date: day.date, completed: completed, total: total)
            }
        }

        let incompleteTodos = monthTodoItems.filter { item in
            guard !item.occurrence.completed else { return false }
            let dueDate = item.todo.dueDate ?? item.occurrence.occurrenceDate
            let day = calendar.startOfDay(for: dueDate)
            return day >= monthRange.lowerBound && day <= monthRange.upperBound
        }

        return MonthlyReflectionData(
            monthDate: monthDate,
            totalTodos: monthTodoItems.count,
            completedTodos: completedCount,
            scheduleCount: scheduleOccurrences.count,
            memoCount: memoCount,
            fullyCompletedWeeks: fullyCompletedWeeksCount,
            totalWeeksInMonth: weeks.count,
            bestWeek: bestWeek,
            categoryBreakdown: categoryBreakdown,
            bestDay: bestDay,
            incompleteTodos: incompleteTodos
        )
    }
}
